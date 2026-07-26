import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wardrobe_slot.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  late Isar isar;
  final supabase = Supabase.instance.client;
  
  // Manual notifier for Web support
  final ValueNotifier<List<WardrobeSlot>> slotsNotifier = ValueNotifier<List<WardrobeSlot>>([]);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);

  Future<void> init() async {
    print('Sync: Initializing Service...');
    
    try {
      // 1. Manually initialize Isar for the Web
      if (kIsWeb) {
        print('Sync: Initializing Isar Core for Web...');
        await Isar.initialize();
      }

      // 2. Initialize Isar Instance
      print('Sync: Opening Isar Database...');
      isar = Isar.open(
        schemas: [WardrobeSlotSchema],
        directory: kIsWeb ? Isar.sqliteInMemory : '', 
        engine: kIsWeb ? IsarEngine.sqlite : IsarEngine.isar,
      );
      print('Sync: Isar Database opened successfully');

      // 3. Initial Pull
      await pullFromSupabase();

      // 4. Realtime Listeners
      _setupRealtime();
      
    } catch (e, stack) {
      print('Sync CRITICAL ERROR during init: $e');
      print(stack);
      errorNotifier.value = 'Fehler beim Starten der Datenbank: $e';
    }
  }

  Future<void> pullFromSupabase() async {
    print('Sync: Fetching data from Supabase...');
    try {
      final data = await supabase
          .from('checket_garderobe')
          .select()
          .order('id', ascending: true);

      final slots = (data as List)
          .map((json) => WardrobeSlot.fromSupabase(json))
          .toList();

      print('Sync: Received ${slots.length} slots from Supabase');

      // Update Isar
      await isar.writeAsync((isar) {
        isar.wardrobeSlots.clear();
        isar.wardrobeSlots.putAll(slots);
      });
      
      // Update Notifier
      slotsNotifier.value = slots;
      print('Sync: Local cache updated');
      
    } catch (e) {
      print('Sync Error (Pull): $e');
      errorNotifier.value = 'Daten konnten nicht geladen werden: $e';
    }
  }

  void _setupRealtime() {
    print('Sync: Setting up Realtime listeners...');
    try {
      supabase
          .channel('public:checket_garderobe')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'checket_garderobe',
            callback: (payload) async {
              print('Sync: Realtime change detected');
              await pullFromSupabase();
            },
          )
          .subscribe((status, [error]) {
            print('Sync: Realtime Status changed to: $status');
            if (error != null) print('Sync Realtime Error: $error');
          });
    } catch (e) {
      print('Sync Error (Realtime Setup): $e');
    }
  }

  Future<void> updateSlot(WardrobeSlot slot) async {
    print('Sync: Updating Slot ${slot.id}...');
    
    // UI-Update vorab für Schnelligkeit
    final currentSlots = List<WardrobeSlot>.from(slotsNotifier.value);
    final index = currentSlots.indexWhere((s) => s.id == slot.id);
    if (index != -1) {
      currentSlots[index] = slot;
      slotsNotifier.value = currentSlots;
    }

    try {
      // Isar Update
      await isar.writeAsync((isar) {
        isar.wardrobeSlots.put(slot);
      });

      // Supabase Update
      await supabase
          .from('checket_garderobe')
          .update(slot.toSupabase())
          .eq('id', slot.id);
          
      print('Sync: Slot ${slot.id} updated successfully in Cloud');
    } catch (e) {
      print('Sync Error (Push): $e');
      // Im Fehlerfall Liste neu laden, um konsistent zu bleiben
      await pullFromSupabase();
    }
  }
}
