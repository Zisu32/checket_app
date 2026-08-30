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
  
  String _schemaName = 'public';
  String get schemaName => _schemaName;
  
  final ValueNotifier<List<WardrobeSlot>> slotsNotifier = ValueNotifier<List<WardrobeSlot>>([]);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<bool> isInitialized = ValueNotifier<bool>(false);
  final ValueNotifier<SyncStatus> statusNotifier = ValueNotifier<SyncStatus>(SyncStatus.syncing);

  Future<void> init({String dbName = 'checket_db', String? schema}) async {
    statusNotifier.value = SyncStatus.syncing;
    errorNotifier.value = null;
    
    try {
      db = AppDatabase(name: dbName);
      
      if (schema != null) {
        _schemaName = schema;
      } else {
        final user = supabase.auth.currentUser;
        _schemaName = user?.appMetadata['schema_name'] as String? ?? 'public';
      }

      // Only pull wardrobe data if we are in a tenant schema
      if (_schemaName != 'public') {
        await pullFromSupabase();
        await pullLostItemsFromSupabase();
        _setupRealtime();
        _setupLostFoundRealtime();
      } else {
        // Admin mode: Just report as online
        statusNotifier.value = SyncStatus.online;
      }
      
      isInitialized.value = true;
    } catch (e) {
      print('Sync Error during init: $e');
      final msg = e.toString().contains('403') 
        ? 'Zugriff verweigert (403). Bitte Admin-Rechte prüfen.' 
        : 'Initialisierung fehlgeschlagen: $e';
      errorNotifier.value = msg;
      statusNotifier.value = SyncStatus.offline;
      rethrow;
    }
  }

  SupabaseQueryBuilder _from(String table) => supabase.schema(_schemaName).from(table);

  Future<void> pullFromSupabase() async {
    if (_schemaName == 'public') return;
    statusNotifier.value = SyncStatus.syncing;
    try {
      final data = await _from('checket_garderobe').select().order('id', ascending: true);
      final entries = (data as List).map((json) => db.companionFromJson(json)).toList();

      await db.batch((batch) {
        batch.insertAll(db.wardrobeSlots, entries, mode: InsertMode.insertOrReplace);
      });
      
      final slots = await db.select(db.wardrobeSlots).get();
      slotsNotifier.value = slots;
      statusNotifier.value = SyncStatus.online;
    } catch (e) {
      statusNotifier.value = SyncStatus.offline;
      rethrow;
    }
  }

  Future<void> pullLostItemsFromSupabase() async {
    if (_schemaName == 'public') return;
    try {
      final data = await _from('checket_lost_found').select().eq('is_handed_over', false);
      final entries = (data as List).map((json) => db.lostItemCompanionFromJson(json)).toList();

      await db.batch((batch) {
        batch.deleteWhere(db.lostItems, (t) => const Constant(true));
        batch.insertAll(db.lostItems, entries, mode: InsertMode.insertOrReplace);
      });
    } catch (e) {
      print('Sync Error (Pull Lost): $e');
    }
  }

  void _setupRealtime() {
    supabase.channel('public:checket_garderobe').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: _schemaName,
      table: 'checket_garderobe',
      callback: (payload) async {
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
      schema: _schemaName,
      table: 'checket_lost_found',
      callback: (payload) async {
        await pullLostItemsFromSupabase();
      },
    ).subscribe();
  }

  Future<void> archiveAndResetShift() async {
    statusNotifier.value = SyncStatus.syncing;
    try {
      final archiveQuery = db.select(db.wardrobeSlots)
        ..where((t) => t.status.equals('active') | t.status.equals('unpaid'));
      final toArchive = await archiveQuery.get();
      
      if (toArchive.isNotEmpty) {
        final lostEntries = toArchive.map((s) => {
          'original_slot_id': s.id,
          'secret': s.secret,
          'is_paid': s.isPaid,
          'created_at': DateTime.now().toIso8601String(),
        }).toList();
        
        await _from('checket_lost_found').insert(lostEntries);
      }

      await _from('checket_garderobe').update({
        'status': 'free',
        'is_paid': false,
        'payment_method': 'none',
        'secret': '',
        'group_id': '',
        'updated_at': DateTime.now().toIso8601String()
      }).neq('status', 'free');

      await Future.wait([
        pullLostItemsFromSupabase(),
        pullFromSupabase(),
      ]);
      
      statusNotifier.value = SyncStatus.online;
    } catch (e) {
      statusNotifier.value = SyncStatus.offline;
      rethrow;
    }
  }

  Future<void> handOverLostItem(LostItem item) async {
    statusNotifier.value = SyncStatus.syncing;
    try {
      await (db.update(db.lostItems)..where((t) => t.id.equals(item.id)))
          .write(const LostItemsCompanion(isHandedOver: Value(true)));

      await _from('checket_lost_found').update({'is_handed_over': true}).eq('id', item.id);
      statusNotifier.value = SyncStatus.online;
    } catch (e) {
      statusNotifier.value = SyncStatus.offline;
      await pullLostItemsFromSupabase();
    }
  }

  Future<void> updateSlots(List<WardrobeSlot> slots) async {
    statusNotifier.value = SyncStatus.syncing;
    
    // 1. Update local DB
    await db.batch((batch) {
      batch.insertAll(db.wardrobeSlots, slots, mode: InsertMode.insertOrReplace);
    });
    await _notifySlots();

    try {
      // 2. Update Supabase
      await Future.wait(slots.map((slot) {
        final data = db.toJson(slot);
        data.remove('id');
        data.remove('updated_at');
        return _from('checket_garderobe').update(data).eq('id', slot.id);
      }));
      
      statusNotifier.value = SyncStatus.online;
    } catch (e) {
      statusNotifier.value = SyncStatus.offline;
      await pullFromSupabase();
      rethrow;
    }
  }

  Future<void> updateSlot(WardrobeSlot slot) async {
    await updateSlots([slot]);
  }

  Future<void> _notifySlots() async {
    final slots = await db.select(db.wardrobeSlots).get();
    slotsNotifier.value = slots;
  }

  Future<void> updateGlobalTicketPrice(double newPrice) async {
    try {
      await _from('checket_terminal_assignments')
          .update({'ticket_price': newPrice})
          .neq('reader_id', '');
    } catch (e) {
      rethrow;
    }
  }

  Future<double> getGlobalTicketPrice() async {
    try {
      final res = await _from('checket_terminal_assignments')
          .select('ticket_price')
          .limit(1)
          .maybeSingle();
      
      if (res == null) throw 'Kein globaler Ticket-Preis konfiguriert.';
      return (res['ticket_price'] as num).toDouble();
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> reauthenticate(String password) async {
    try {
      final email = supabase.auth.currentUser?.email;
      if (email == null) return false;
      await supabase.auth.signInWithPassword(email: email, password: password);
      return true;
    } catch (e) {
      return false;
    }
  }

  Stream<WardrobeSlot?> watchSingleSlot(int id) {
    return (db.select(db.wardrobeSlots)..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  Stream<List<WardrobeSlot>> watchSlots() {
    return (db.select(db.wardrobeSlots)..orderBy([(t) => OrderingTerm(expression: t.id)])).watch();
  }

  Stream<List<LostItem>> watchLostItems() {
    return (db.select(db.lostItems)
      ..where((t) => t.isHandedOver.equals(false))
      ..orderBy([(t) => OrderingTerm(expression: t.originalSlotId, mode: OrderingMode.asc)]))
      .watch();
  }

  Stream<List<WardrobeSlot>> watchGroup(String groupId, String secret) {
    final controller = StreamController<List<WardrobeSlot>>.broadcast();
    
    Future<void> update() async {
      if (controller.isClosed) return;
      
      // 1. Check local DB
      final local = await (db.select(db.wardrobeSlots)
            ..where((t) => t.groupId.equals(groupId) & t.secret.equals(secret))
            ..orderBy([(t) => OrderingTerm(expression: t.id)]))
          .get();
      
      if (local.isNotEmpty) {
        controller.add(local);
      } else {
        // 2. Fallback to Supabase (important for first guest load)
        try {
          final data = await _from('checket_garderobe')
              .select()
              .eq('group_id', groupId)
              .eq('secret', secret)
              .order('id', ascending: true);
          
          final slots = (data as List).map((json) => WardrobeSlot(
            id: json['id'] as int,
            status: json['status'] as String? ?? 'free',
            isPaid: json['is_paid'] as bool? ?? false,
            paymentMethod: json['payment_method'] as String? ?? 'none',
            secret: json['secret'] as String? ?? '',
            groupId: json['group_id'] as String? ?? '',
            updatedAt: DateTime.parse(json['updated_at'] as String),
          )).toList();
          
          if (slots.isNotEmpty) controller.add(slots);
        } catch (e) {
          // Silent fail or empty
        }
      }
    }

    final sub = db.wardrobeSlots.all().watch().listen((_) => update());
    update();
    
    controller.onCancel = () {
      sub.cancel();
      controller.close();
    };
    
    return controller.stream;
  }

  Stream<WardrobeSlot?> watchTicket(int id, String secret) {
    final controller = StreamController<WardrobeSlot?>();
    Future<void> update() async {
      if (controller.isClosed) return;
      final activeBySecret = await (db.select(db.wardrobeSlots)
            ..where((t) => t.id.equals(id) & t.secret.equals(secret)))
          .getSingleOrNull();
      if (activeBySecret != null && activeBySecret.status != 'free') {
        controller.add(activeBySecret);
        return;
      }
      final lostBySecret = await (db.select(db.lostItems)
            ..where((t) => t.originalSlotId.equals(id) & t.secret.equals(secret)))
          .getSingleOrNull();
      if (lostBySecret != null) {
        controller.add(WardrobeSlot(
          id: lostBySecret.originalSlotId,
          status: lostBySecret.isHandedOver ? 'picked_up' : 'forgotten',
          isPaid: lostBySecret.isPaid,
          paymentMethod: 'none',
          secret: lostBySecret.secret,
          groupId: '',
          updatedAt: lostBySecret.createdAt,
        ));
        return;
      }
      final hookInGrid = await (db.select(db.wardrobeSlots)..where((t) => t.id.equals(id))).getSingleOrNull();
      if (hookInGrid != null) {
        if (hookInGrid.status == 'free') {
          controller.add(hookInGrid);
        } else {
          controller.add(hookInGrid.copyWith(status: 'picked_up'));
        }
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
