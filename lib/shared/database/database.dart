import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

@DataClassName('WardrobeSlot')
class WardrobeSlots extends Table {
  @override
  String get tableName => 'checket_garderobe';

  IntColumn get id => integer()();
  TextColumn get status => text().withDefault(const Constant('free'))();
  BoolColumn get isPaid => boolean().withDefault(const Constant(false))();
  TextColumn get paymentMethod => text().withDefault(const Constant('none'))();
  TextColumn get secret => text().withDefault(const Constant(''))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LostItem')
class LostItems extends Table {
  @override
  String get tableName => 'checket_lost_found';

  TextColumn get id => text()(); // UUID from Supabase
  IntColumn get originalSlotId => integer()();
  TextColumn get secret => text()();
  BoolColumn get isPaid => boolean()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isHandedOver => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [WardrobeSlots, LostItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase({String name = 'checket_db'}) : super(_openConnection(name));

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection(String name) {
    return driftDatabase(
      name: name,
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }
  
  // Helpers for WardrobeSlot
  WardrobeSlotsCompanion companionFromJson(Map<String, dynamic> json) {
    return WardrobeSlotsCompanion(
      id: Value(json['id'] as int),
      status: Value(json['status'] as String? ?? 'free'),
      isPaid: Value(json['is_paid'] as bool? ?? false),
      paymentMethod: Value(json['payment_method'] as String? ?? 'none'),
      secret: Value(json['secret'] as String? ?? ''),
      updatedAt: Value(DateTime.parse(json['updated_at'] as String)),
    );
  }

  Map<String, dynamic> toJson(WardrobeSlot entry) {
    return {
      'id': entry.id,
      'status': entry.status,
      'is_paid': entry.isPaid,
      'payment_method': entry.paymentMethod,
      'secret': entry.secret,
      'updated_at': entry.updatedAt.toIso8601String(),
    };
  }

  // Helpers for LostItem
  LostItemsCompanion lostItemCompanionFromJson(Map<String, dynamic> json) {
    return LostItemsCompanion(
      id: Value(json['id'] as String),
      originalSlotId: Value(json['original_slot_id'] as int),
      secret: Value(json['secret'] as String? ?? ''),
      isPaid: Value(json['is_paid'] as bool? ?? false),
      createdAt: Value(DateTime.parse(json['created_at'] as String)),
      isHandedOver: Value(json['is_handed_over'] as bool? ?? false),
    );
  }

  Map<String, dynamic> lostItemToJson(LostItem entry) {
    return {
      'id': entry.id,
      'original_slot_id': entry.originalSlotId,
      'secret': entry.secret,
      'is_paid': entry.isPaid,
      'created_at': entry.createdAt.toIso8601String(),
      'is_handed_over': entry.isHandedOver,
    };
  }
}
