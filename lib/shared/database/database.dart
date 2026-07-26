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

@DriftDatabase(tables: [WardrobeSlots])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'checket_db',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }
  
  // Helper to convert Supabase JSON to Drift Companion
  WardrobeSlotsCompanion companionFromJson(Map<String, dynamic> json) {
    return WardrobeSlotsCompanion.insert(
      id: Value(json['id'] as int),
      status: Value(json['status'] as String? ?? 'free'),
      isPaid: Value(json['is_paid'] as bool? ?? false),
      paymentMethod: Value(json['payment_method'] as String? ?? 'none'),
      secret: Value(json['secret'] as String? ?? ''),
      updatedAt: Value(DateTime.parse(json['updated_at'] as String)),
    );
  }

  // Helper to convert Drift Data Class to Supabase JSON
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
}
