import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  late AppDatabase db;
  final supabase = Supabase.instance.client;
  
  // Manual notifier for Web support
  final ValueNotifier<List<WardrobeSlot>> slotsNotifier = ValueNotifier<List<WardrobeSlot>>([]);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<bool> isInitialized = ValueNotifier<bool>(false);

  Future<void> init() async {
    print('Sync: Initializing Drift Database...');
    db = AppDatabase();
    
    // Perform initial pull in background, don't await it to avoid blocking UI
    pullFromSupabase().then((_) {
      print('Sync: Initial background pull completed');
      isInitialized.value = true;
    });

    // Setup Realtime listener
    _setupRealtime();
  }

  Future<void> pullFromSupabase() async {
    print('Sync: Fetching data from Supabase...');
    try {
      final data = await supabase
          .from('checket_garderobe')
          .select()
          .order('id', ascending: true);

      final entries = (data as List).map((json) => db.companionFromJson(json)).toList();

      print('Sync: Received ${entries.length} slots from Supabase');

      // Update local Drift DB (Insert or Replace)
      await db.batch((batch) {
        batch.insertAll(
          db.wardrobeSlots, 
          entries, 
          mode: InsertMode.insertOrReplace
        );
      });
      
      // Update Notifier
      final slots = await db.select(db.wardrobeSlots).get();
      slotsNotifier.value = slots;
      
      print('Sync: Local Drift cache updated with ${slots.length} slots');
    } catch (e) {
      print('Sync Error (Pull): $e');
      errorNotifier.value = 'Fehler beim Laden: $e';
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
              if (payload.newRecord.isNotEmpty) {
                final entry = db.companionFromJson(payload.newRecord);
                await db.into(db.wardrobeSlots).insertOnConflictUpdate(entry);
                
                // Refresh full list for notifier
                final slots = await db.select(db.wardrobeSlots).get();
                slotsNotifier.value = slots;
                print('Sync: Realtime update applied and UI notified');
              }
            },
          )
          .subscribe((status, [error]) {
            print('Sync: Realtime Status changed to: $status');
            if (error != null) print('Sync Realtime Error Detail: $error');
          });
    } catch (e) {
      print('Sync Error (Realtime Setup): $e');
    }
  }

  Future<void> updateSlot(WardrobeSlot slot) async {
    print('Sync: Updating Slot ${slot.id}...');
    
    // 1. Update locally in Drift
    await db.into(db.wardrobeSlots).insertOnConflictUpdate(slot);
    
    // Update notifier value to trigger UI
    final slots = await db.select(db.wardrobeSlots).get();
    slotsNotifier.value = slots;

    // 2. Update Supabase
    try {
      await supabase
          .from('checket_garderobe')
          .update(db.toJson(slot))
          .eq('id', slot.id);
          
      print('Sync: Slot ${slot.id} updated successfully in Cloud');
    } catch (e) {
      print('Sync Error (Push): $e');
      await pullFromSupabase();
    }
  }

  Stream<List<WardrobeSlot>> watchSlots() {
    return (db.select(db.wardrobeSlots)..orderBy([(t) => OrderingTerm(expression: t.id)])).watch();
  }
}
