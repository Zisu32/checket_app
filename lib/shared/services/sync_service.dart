import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

enum SyncStatus { online, syncing, offline }

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  late AppDatabase db;
  final supabase = Supabase.instance.client;
  
  final ValueNotifier<List<WardrobeSlot>> slotsNotifier = ValueNotifier<List<WardrobeSlot>>([]);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<bool> isInitialized = ValueNotifier<bool>(false);
  final ValueNotifier<SyncStatus> statusNotifier = ValueNotifier<SyncStatus>(SyncStatus.syncing);

  Future<void> init({String dbName = 'checket_db'}) async {
    print('Sync: Initializing Database ($dbName)...');
    statusNotifier.value = SyncStatus.syncing;
    
    try {
      db = AppDatabase(name: dbName);
      
      // Perform initial pulls in background
      Future.wait([
        pullFromSupabase(),
        pullLostItemsFromSupabase(),
      ]).then((_) {
        print('Sync: Initial background pulls completed');
        isInitialized.value = true;
        statusNotifier.value = SyncStatus.online;
      }).catchError((e) {
        print('Sync: Background pull failed: $e');
        errorNotifier.value = 'Datenabgleich fehlgeschlagen.';
        statusNotifier.value = SyncStatus.offline;
      });

      _setupRealtime();
      _setupLostFoundRealtime();
      
    } catch (e) {
      print('Sync CRITICAL ERROR during init: $e');
      errorNotifier.value = 'Datenbank-Fehler: $e';
      statusNotifier.value = SyncStatus.offline;
    }
  }

  Future<void> pullFromSupabase() async {
    print('Sync: Fetching Garderobe data...');
    statusNotifier.value = SyncStatus.syncing;
    
    try {
      final data = await supabase.from('checket_garderobe').select().order('id', ascending: true);
      final entries = (data as List).map((json) => db.companionFromJson(json)).toList();

      await db.batch((batch) {
        batch.insertAll(db.wardrobeSlots, entries, mode: InsertMode.insertOrReplace);
      });
      
      final slots = await db.select(db.wardrobeSlots).get();
      slotsNotifier.value = slots;
      print('Sync: Garderobe cache updated');
      statusNotifier.value = SyncStatus.online;
    } catch (e) {
      print('Sync Error (Pull Garderobe): $e');
      statusNotifier.value = SyncStatus.offline;
      if (e.toString().contains('NoModificationAllowedError')) {
        errorNotifier.value = 'Datenbank-Sperre erkannt. Bitte andere Tabs schließen.';
      }
      rethrow;
    }
  }

  Future<void> pullLostItemsFromSupabase() async {
    print('Sync: Fetching Lost & Found data...');
    try {
      final data = await supabase.from('checket_lost_found').select().eq('is_handed_over', false);
      final entries = (data as List).map((json) => db.lostItemCompanionFromJson(json)).toList();

      await db.batch((batch) {
        batch.deleteWhere(db.lostItems, (t) => const Constant(true));
        batch.insertAll(db.lostItems, entries, mode: InsertMode.insertOrReplace);
      });
      print('Sync: Lost & Found cache updated');
    } catch (e) {
      print('Sync Error (Pull Lost): $e');
    }
  }

  void _setupRealtime() {
    supabase.channel('public:checket_garderobe').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'checket_garderobe',
      callback: (payload) async {
        print('Sync: Realtime change in Garderobe');
        await pullFromSupabase();
      },
    ).subscribe((status, [error]) {
       if (status == RealtimeSubscribeStatus.channelError) {
         statusNotifier.value = SyncStatus.offline;
       }
    });
  }

  void _setupLostFoundRealtime() {
    supabase.channel('public:checket_lost_found').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'checket_lost_found',
      callback: (payload) async {
        print('Sync: Realtime change in Lost & Found');
        await pullLostItemsFromSupabase();
      },
    ).subscribe();
  }

  Future<void> archiveAndResetShift() async {
    print('Sync: Starting Shift Reset...');
    statusNotifier.value = SyncStatus.syncing;
    try {
      final occupied = await (db.select(db.wardrobeSlots)..where((t) => t.status.isNotValue('free'))).get();
      
      if (occupied.isNotEmpty) {
        final lostEntries = occupied.map((s) => {
          'original_slot_id': s.id,
          'secret': s.secret,
          'is_paid': s.isPaid,
          'created_at': DateTime.now().toIso8601String(),
        }).toList();
        
        await supabase.from('checket_lost_found').insert(lostEntries);
      }

      await supabase.from('checket_garderobe').update({
        'status': 'free',
        'is_paid': false,
        'payment_method': 'none',
        'secret': '',
        'updated_at': DateTime.now().toIso8601String()
      }).neq('status', 'free');

      await Future.wait([
        pullLostItemsFromSupabase(),
        pullFromSupabase(),
      ]);
      
      print('Sync: Shift reset complete');
      statusNotifier.value = SyncStatus.online;
    } catch (e) {
      print('Sync Error (Reset): $e');
      statusNotifier.value = SyncStatus.offline;
      rethrow;
    }
  }

  Future<void> handOverLostItem(LostItem item) async {
    statusNotifier.value = SyncStatus.syncing;
    try {
      await (db.update(db.lostItems)..where((t) => t.id.equals(item.id)))
          .write(const LostItemsCompanion(isHandedOver: Value(true)));

      await supabase.from('checket_lost_found').update({'is_handed_over': true}).eq('id', item.id);
          
      print('Sync: Lost item handed over');
      statusNotifier.value = SyncStatus.online;
    } catch (e) {
      print('Sync Error (Handover): $e');
      statusNotifier.value = SyncStatus.offline;
      await pullLostItemsFromSupabase();
    }
  }

  Future<void> updateSlot(WardrobeSlot slot) async {
    statusNotifier.value = SyncStatus.syncing;
    await db.into(db.wardrobeSlots).insertOnConflictUpdate(slot);
    final slots = await db.select(db.wardrobeSlots).get();
    slotsNotifier.value = slots;

    try {
      await supabase.from('checket_garderobe').update(db.toJson(slot)).eq('id', slot.id);
      statusNotifier.value = SyncStatus.online;
    } catch (e) {
      print('Sync Error (Push): $e');
      statusNotifier.value = SyncStatus.offline;
      await pullFromSupabase();
    }
  }

  Stream<List<WardrobeSlot>> watchSlots() {
    return (db.select(db.wardrobeSlots)..orderBy([(t) => OrderingTerm(expression: t.id)])).watch();
  }

  Stream<List<LostItem>> watchLostItems() {
    return (db.select(db.lostItems)
      ..where((t) => t.isHandedOver.equals(false))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
      .watch();
  }

  Stream<WardrobeSlot?> watchTicket(int id, String secret) {
    final controller = StreamController<WardrobeSlot?>();

    Future<void> update() async {
      if (controller.isClosed) return;

      final anyActiveSlot = await (db.select(db.wardrobeSlots)..where((t) => t.id.equals(id))).getSingleOrNull();
      
      if (anyActiveSlot != null && anyActiveSlot.status != 'free' && anyActiveSlot.secret != secret) {
         controller.add(anyActiveSlot.copyWith(status: 'wrong_secret'));
         return;
      }

      if (anyActiveSlot != null && anyActiveSlot.secret == secret) {
        controller.add(anyActiveSlot);
        return;
      }

      final lostItem = await (db.select(db.lostItems)
            ..where((t) => t.originalSlotId.equals(id) & t.secret.equals(secret) & t.isHandedOver.equals(false)))
          .getSingleOrNull();

      if (lostItem != null) {
        controller.add(WardrobeSlot(
          id: lostItem.originalSlotId,
          status: 'forgotten',
          isPaid: lostItem.isPaid,
          paymentMethod: 'none',
          secret: lostItem.secret,
          updatedAt: lostItem.createdAt,
        ));
        return;
      }
      
      final anyLostItem = await (db.select(db.lostItems)
            ..where((t) => t.originalSlotId.equals(id) & t.isHandedOver.equals(false)))
          .getSingleOrNull();
      if (anyLostItem != null && anyLostItem.secret != secret) {
         controller.add(WardrobeSlot(
          id: id,
          status: 'wrong_secret',
          isPaid: false,
          paymentMethod: 'none',
          secret: '',
          updatedAt: DateTime.now(),
        ));
        return;
      }

      if (anyActiveSlot != null && anyActiveSlot.status == 'free') {
        controller.add(anyActiveSlot);
      } else {
        controller.add(null);
      }
    }

    final sub1 = db.wardrobeSlots.all().watch().listen((_) => update());
    final sub2 = db.lostItems.all().watch().listen((_) => update());
    
    update();

    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
      controller.close();
    };

    return controller.stream;
  }
}
