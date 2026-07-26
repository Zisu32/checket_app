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

  Future<void> init() async {
    // 1. Manually initialize Isar for the Web (Required for dev.14)
    if (kIsWeb) {
      await Isar.initialize();
    }

    // 2. Initialize Isar Instance
    // In Isar 4.0.0-dev.14, Isar.open is synchronous!
    isar = Isar.open(
      schemas: [WardrobeSlotSchema],
      directory: kIsWeb ? Isar.sqliteInMemory : '', 
      engine: kIsWeb ? IsarEngine.sqlite : IsarEngine.isar,
    );

    // Initial Pull
    await pullFromSupabase();

    // Realtime Listeners
    _setupRealtime();
  }

  Future<void> pullFromSupabase() async {
    try {
      final data = await supabase
          .from('checket_garderobe')
          .select()
          .order('id', ascending: true);

      final slots = (data as List)
          .map((json) => WardrobeSlot.fromSupabase(json))
          .toList();

      // Clear local Isar and save new data
      // Use writeAsync for Isar 4. Callback takes 'isar' instance.
      await isar.writeAsync((isar) {
        isar.wardrobeSlots.clear();
        isar.wardrobeSlots.putAll(slots);
      });
      
      if (kDebugMode) print('Sync: Pulled ${slots.length} slots from Supabase');
    } catch (e) {
      if (kDebugMode) print('Sync Error (Pull): $e');
    }
  }

  void _setupRealtime() {
    supabase
        .channel('public:checket_garderobe')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'checket_garderobe',
          callback: (payload) async {
            final json = payload.newRecord;
            if (json.isNotEmpty) {
              final slot = WardrobeSlot.fromSupabase(json);
              await isar.writeAsync((isar) {
                isar.wardrobeSlots.put(slot);
              });
              if (kDebugMode) print('Sync: Received Realtime Update for Slot ${slot.id}');
            }
          },
        )
        .subscribe();
  }

  Future<void> updateSlot(WardrobeSlot slot) async {
    // Update locally for instant UI feedback
    await isar.writeAsync((isar) {
      isar.wardrobeSlots.put(slot);
    });

    // Update Supabase
    try {
      await supabase
          .from('checket_garderobe')
          .update(slot.toSupabase())
          .eq('id', slot.id);
    } catch (e) {
      if (kDebugMode) print('Sync Error (Push): $e');
    }
  }

  Stream<List<WardrobeSlot>> watchSlots() {
    return isar.wardrobeSlots.where().sortById().watch(fireImmediately: true);
  }
}
