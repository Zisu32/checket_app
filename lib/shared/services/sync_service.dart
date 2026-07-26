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
  
  final ValueNotifier<List<WardrobeSlot>> slotsNotifier = ValueNotifier<List<WardrobeSlot>>([]);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<bool> isInitialized = ValueNotifier<bool>(false);

  Future<void> init({String dbName = 'checket_db'}) async {
    print('Sync: Initializing Database ($dbName)...');
    try {
      db = AppDatabase(name: dbName);
      
      // Perform initial pull in background
      pullFromSupabase().then((_) {
        print('Sync: Initial background pull completed');
        isInitialized.value = true;
      }).catchError((e) {
        print('Sync: Background pull failed: $e');
        errorNotifier.value = 'Datenabgleich fehlgeschlagen. Bitte Seite neu laden.';
      });

      _setupRealtime();
      
    } catch (e) {
      print('Sync CRITICAL ERROR during init: $e');
      errorNotifier.value = 'Datenbank konnte nicht gestartet werden: $e';
    }
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

      await db.batch((batch) {
        batch.insertAll(
          db.wardrobeSlots, 
          entries, 
          mode: InsertMode.insertOrReplace
        );
      });
      
      final slots = await db.select(db.wardrobeSlots).get();
      slotsNotifier.value = slots;
      
      print('Sync: Local cache updated');
    } catch (e) {
      print('Sync Error (Pull): $e');
      if (e.toString().contains('NoModificationAllowedError')) {
        errorNotifier.value = 'Datenbank-Sperre erkannt. Bitte alle anderen Tabs dieser App schließen.';
      } else {
        errorNotifier.value = 'Fehler beim Laden: $e';
      }
      rethrow;
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
                
                final slots = await db.select(db.wardrobeSlots).get();
                slotsNotifier.value = slots;
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
    
    await db.into(db.wardrobeSlots).insertOnConflictUpdate(slot);
    
    final slots = await db.select(db.wardrobeSlots).get();
    slotsNotifier.value = slots;

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
