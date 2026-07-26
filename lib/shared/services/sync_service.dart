import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database.dart';
import 'package:drift/drift.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  late AppDatabase db;
  final supabase = Supabase.instance.client;

  Future<void> init() async {
    print('Sync: Initializing Drift Database...');
    db = AppDatabase();
    
    // Initial Pull from Supabase to fill local DB
    await pullFromSupabase();

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
      
      print('Sync: Local Drift cache updated');
    } catch (e) {
      print('Sync Error (Pull): $e');
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
                print('Sync: Realtime update applied to local DB');
              }
            },
          )
          .subscribe((status, [error]) {
            print('Sync: Realtime Status changed to: $status');
          });
    } catch (e) {
      print('Sync Error (Realtime Setup): $e');
    }
  }

  Future<void> updateSlot(WardrobeSlot slot) async {
    print('Sync: Updating Slot ${slot.id}...');
    
    // 1. Update locally in Drift (UI will update automatically via Stream)
    await db.into(db.wardrobeSlots).insertOnConflictUpdate(slot);

    // 2. Update Supabase
    try {
      await supabase
          .from('checket_garderobe')
          .update(db.toJson(slot))
          .eq('id', slot.id);
          
      print('Sync: Slot ${slot.id} updated successfully in Cloud');
    } catch (e) {
      print('Sync Error (Push): $e');
      // If push fails, we might want to re-pull to ensure consistency
      await pullFromSupabase();
    }
  }

  Stream<List<WardrobeSlot>> watchSlots() {
    return (db.select(db.wardrobeSlots)..orderBy([(t) => OrderingTerm(expression: t.id)])).watch();
  }
}
