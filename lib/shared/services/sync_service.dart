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

  Future<void> pullGroupFromSupabase(String groupId, String secret) async {
    if (_schemaName == 'public') return;
    try {
      // 1. Pull from Wardrobe
      final wardrobeData = await _from('checket_garderobe')
          .select()
          .eq('group_id', groupId)
          .eq('secret', secret);
      
      final wardrobeEntries = (wardrobeData as List).map((json) => db.companionFromJson(json)).toList();
      
      // 2. Pull from Lost Found
      final lostData = await _from('checket_lost_found')
          .select()
          .eq('group_id', groupId)
          .eq('secret', secret);
      
      final lostEntries = (lostData as List).map((json) => db.lostItemCompanionFromJson(json)).toList();

      await db.batch((batch) {
        // Update wardrobe slots
        batch.insertAll(db.wardrobeSlots, wardrobeEntries, mode: InsertMode.insertOrReplace);

        // Update lost items
        batch.insertAll(db.lostItems, lostEntries, mode: InsertMode.insertOrReplace);
      });
      await _notifySlots();
    } catch (e) {
      print('Guest Sync Error (Group): $e');
    }
  }

  Future<void> pullTicketFromSupabase(int id, String secret) async {
    if (_schemaName == 'public') return;
    try {
      // 1. Check Wardrobe
      final wardrobeData = await _from('checket_garderobe')
          .select()
          .eq('id', id)
          .eq('secret', secret)
          .maybeSingle();
      
      // 2. Check Lost Found
      final lostData = await _from('checket_lost_found')
          .select()
          .eq('original_slot_id', id)
          .eq('secret', secret)
          .maybeSingle();

      await db.batch((batch) {
        if (wardrobeData != null) {
          batch.insertAll(db.wardrobeSlots, [db.companionFromJson(wardrobeData)], mode: InsertMode.insertOrReplace);
        }
        if (lostData != null) {
          batch.insertAll(db.lostItems, [db.lostItemCompanionFromJson(lostData)], mode: InsertMode.insertOrReplace);
        }
      });
      await _notifySlots();
    } catch (e) {
      print('Guest Sync Error (Ticket): $e');
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
        // If we are a tenant/staff, we pull everything
        final user = supabase.auth.currentUser;
        if (user != null) {
          await pullFromSupabase();
        }
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
          'group_id': s.groupId,
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

      // Clear local wardrobe cache to avoid ghost items for staff
      await db.batch((batch) {
        batch.deleteWhere(db.wardrobeSlots, (t) => const Constant(true));
      });

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
      
      // 1. Check local DB (WardrobeSlots) - Only those that still match secret/group
      final localWardrobe = await (db.select(db.wardrobeSlots)
            ..where((t) => t.groupId.equals(groupId) & t.secret.equals(secret))
            ..orderBy([(t) => OrderingTerm(expression: t.id)]))
          .get();
      
      // 2. Check local DB (LostItems)
      final localLost = await (db.select(db.lostItems)
            ..where((t) => t.groupId.equals(groupId) & t.secret.equals(secret))
            ..orderBy([(t) => OrderingTerm(expression: t.originalSlotId)]))
          .get();

      final Map<int, WardrobeSlot> slotsMap = {};
      
      // Priority 1: Items in Fundbüro (Archived)
      for (final l in localLost) {
        slotsMap[l.originalSlotId] = WardrobeSlot(
          id: l.originalSlotId,
          status: l.isHandedOver ? 'picked_up' : 'forgotten',
          isPaid: l.isPaid,
          paymentMethod: 'none',
          secret: l.secret,
          groupId: l.groupId,
          updatedAt: l.createdAt,
        );
      }
      
      // Priority 2: Active items in wardrobe (Live)
      // If an item is in both, the 'active' one in wardrobe table is usually the most recent 
      // UNLESS it's status is 'free' (meaning it's been reset but we still have the secret in cache)
      for (final w in localWardrobe) {
        if (w.status != 'free') {
           slotsMap[w.id] = w;
        } else {
           // If it's free in wardrobe but we have it as forgotten in lost_found, 
           // the loop above already added it. 
           // If it's free and NOT in lost_found, it was probably picked up.
           if (!slotsMap.containsKey(w.id)) {
              slotsMap[w.id] = w.copyWith(status: 'picked_up');
           }
        }
      }

      if (slotsMap.isNotEmpty) {
        final sorted = slotsMap.values.toList()..sort((a, b) => a.id.compareTo(b.id));
        controller.add(sorted);
      } else {
        // 3. Fallback to Supabase
        try {
          // Check Wardrobe
          final wardrobeData = await _from('checket_garderobe')
              .select()
              .eq('group_id', groupId)
              .eq('secret', secret);
          
          final wardrobeSlots = (wardrobeData as List).map((json) => WardrobeSlot(
            id: json['id'] as int,
            status: json['status'] as String? ?? 'free',
            isPaid: json['is_paid'] as bool? ?? false,
            paymentMethod: json['payment_method'] as String? ?? 'none',
            secret: json['secret'] as String? ?? '',
            groupId: json['group_id'] as String? ?? '',
            updatedAt: DateTime.parse(json['updated_at'] as String),
          )).toList();

          // Check Lost Found
          final lostData = await _from('checket_lost_found')
              .select()
              .eq('group_id', groupId)
              .eq('secret', secret);

          final lostSlots = (lostData as List).map((json) => WardrobeSlot(
            id: json['original_slot_id'] as int,
            status: json['is_handed_over'] == true ? 'picked_up' : 'forgotten',
            isPaid: json['is_paid'] as bool? ?? false,
            paymentMethod: 'none',
            secret: json['secret'] as String? ?? '',
            groupId: json['group_id'] as String? ?? '',
            updatedAt: DateTime.parse(json['created_at'] as String),
          )).toList();

          final Map<int, WardrobeSlot> remoteMap = {};
          // Fill with lost slots first
          for (final s in lostSlots) remoteMap[s.id] = s;
          // Overwrite with active wardrobe slots if they still match secret
          for (final s in wardrobeSlots) {
            if (s.status != 'free') {
              remoteMap[s.id] = s;
            } else if (!remoteMap.containsKey(s.id)) {
              remoteMap[s.id] = s.copyWith(status: 'picked_up');
            }
          }

          if (remoteMap.isNotEmpty) {
            final sorted = remoteMap.values.toList()..sort((a, b) => a.id.compareTo(b.id));
            controller.add(sorted);
          }
        } catch (e) {
          print('watchGroup fallback error: $e');
        }
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

  Stream<WardrobeSlot?> watchTicket(int id, String secret) {
    final controller = StreamController<WardrobeSlot?>.broadcast();
    Future<void> update() async {
      if (controller.isClosed) return;
      
      // 1. Check local DB (WardrobeSlots)
      final localActive = await (db.select(db.wardrobeSlots)
            ..where((t) => t.id.equals(id) & t.secret.equals(secret)))
          .getSingleOrNull();
      
      // 2. Check local DB (LostItems)
      final localLost = await (db.select(db.lostItems)
            ..where((t) => t.originalSlotId.equals(id) & t.secret.equals(secret)))
          .getSingleOrNull();
      
      if (localLost != null) {
        controller.add(WardrobeSlot(
          id: localLost.originalSlotId,
          status: localLost.isHandedOver ? 'picked_up' : 'forgotten',
          isPaid: localLost.isPaid,
          paymentMethod: 'none',
          secret: localLost.secret,
          groupId: localLost.groupId,
          updatedAt: localLost.createdAt,
        ));
        return;
      }

      if (localActive != null) {
        if (localActive.status != 'free') {
           controller.add(localActive);
           return;
        } else {
           // If it's free in local DB, it was probably picked up
           controller.add(localActive.copyWith(status: 'picked_up'));
           return;
        }
      }

      // 3. Fallback to Supabase (important for guest view)
      try {
        // Check Lost Found first (archived state)
        final lostData = await _from('checket_lost_found')
            .select()
            .eq('original_slot_id', id)
            .eq('secret', secret)
            .maybeSingle();

        if (lostData != null) {
          final slot = WardrobeSlot(
            id: lostData['original_slot_id'] as int,
            status: lostData['is_handed_over'] == true ? 'picked_up' : 'forgotten',
            isPaid: lostData['is_paid'] as bool? ?? false,
            paymentMethod: 'none',
            secret: lostData['secret'] as String? ?? '',
            groupId: lostData['group_id'] as String? ?? '',
            updatedAt: DateTime.parse(lostData['created_at'] as String),
          );
          controller.add(slot);
          return;
        }

        // Check Wardrobe (live state)
        final wardrobeData = await _from('checket_garderobe')
            .select()
            .eq('id', id)
            .eq('secret', secret)
            .maybeSingle();
        
        if (wardrobeData != null) {
          final slot = WardrobeSlot(
            id: wardrobeData['id'] as int,
            status: wardrobeData['status'] as String? ?? 'free',
            isPaid: wardrobeData['is_paid'] as bool? ?? false,
            paymentMethod: wardrobeData['payment_method'] as String? ?? 'none',
            secret: wardrobeData['secret'] as String? ?? '',
            groupId: wardrobeData['group_id'] as String? ?? '',
            updatedAt: DateTime.parse(wardrobeData['updated_at'] as String),
          );
          
          if (slot.status != 'free') {
             controller.add(slot);
          } else {
             controller.add(slot.copyWith(status: 'picked_up'));
          }
          return;
        }
      } catch (e) {
        print('watchTicket fallback error: $e');
      }

      // 4. Default: No data found for this secret
      controller.add(null);
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
