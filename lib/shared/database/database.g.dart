// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $WardrobeSlotsTable extends WardrobeSlots
    with TableInfo<$WardrobeSlotsTable, WardrobeSlot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WardrobeSlotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('free'));
  static const VerificationMeta _isPaidMeta = const VerificationMeta('isPaid');
  @override
  late final GeneratedColumn<bool> isPaid = GeneratedColumn<bool>(
      'is_paid', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_paid" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _paymentMethodMeta =
      const VerificationMeta('paymentMethod');
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
      'payment_method', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('none'));
  static const VerificationMeta _secretMeta = const VerificationMeta('secret');
  @override
  late final GeneratedColumn<String> secret = GeneratedColumn<String>(
      'secret', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, status, isPaid, paymentMethod, secret, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'checket_garderobe';
  @override
  VerificationContext validateIntegrity(Insertable<WardrobeSlot> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('is_paid')) {
      context.handle(_isPaidMeta,
          isPaid.isAcceptableOrUnknown(data['is_paid']!, _isPaidMeta));
    }
    if (data.containsKey('payment_method')) {
      context.handle(
          _paymentMethodMeta,
          paymentMethod.isAcceptableOrUnknown(
              data['payment_method']!, _paymentMethodMeta));
    }
    if (data.containsKey('secret')) {
      context.handle(_secretMeta,
          secret.isAcceptableOrUnknown(data['secret']!, _secretMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WardrobeSlot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WardrobeSlot(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      isPaid: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_paid'])!,
      paymentMethod: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_method'])!,
      secret: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}secret'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $WardrobeSlotsTable createAlias(String alias) {
    return $WardrobeSlotsTable(attachedDatabase, alias);
  }
}

class WardrobeSlot extends DataClass implements Insertable<WardrobeSlot> {
  final int id;
  final String status;
  final bool isPaid;
  final String paymentMethod;
  final String secret;
  final DateTime updatedAt;
  const WardrobeSlot(
      {required this.id,
      required this.status,
      required this.isPaid,
      required this.paymentMethod,
      required this.secret,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['status'] = Variable<String>(status);
    map['is_paid'] = Variable<bool>(isPaid);
    map['payment_method'] = Variable<String>(paymentMethod);
    map['secret'] = Variable<String>(secret);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WardrobeSlotsCompanion toCompanion(bool nullToAbsent) {
    return WardrobeSlotsCompanion(
      id: Value(id),
      status: Value(status),
      isPaid: Value(isPaid),
      paymentMethod: Value(paymentMethod),
      secret: Value(secret),
      updatedAt: Value(updatedAt),
    );
  }

  factory WardrobeSlot.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WardrobeSlot(
      id: serializer.fromJson<int>(json['id']),
      status: serializer.fromJson<String>(json['status']),
      isPaid: serializer.fromJson<bool>(json['isPaid']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      secret: serializer.fromJson<String>(json['secret']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'status': serializer.toJson<String>(status),
      'isPaid': serializer.toJson<bool>(isPaid),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'secret': serializer.toJson<String>(secret),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WardrobeSlot copyWith(
          {int? id,
          String? status,
          bool? isPaid,
          String? paymentMethod,
          String? secret,
          DateTime? updatedAt}) =>
      WardrobeSlot(
        id: id ?? this.id,
        status: status ?? this.status,
        isPaid: isPaid ?? this.isPaid,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        secret: secret ?? this.secret,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  WardrobeSlot copyWithCompanion(WardrobeSlotsCompanion data) {
    return WardrobeSlot(
      id: data.id.present ? data.id.value : this.id,
      status: data.status.present ? data.status.value : this.status,
      isPaid: data.isPaid.present ? data.isPaid.value : this.isPaid,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      secret: data.secret.present ? data.secret.value : this.secret,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WardrobeSlot(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('isPaid: $isPaid, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('secret: $secret, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, status, isPaid, paymentMethod, secret, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WardrobeSlot &&
          other.id == this.id &&
          other.status == this.status &&
          other.isPaid == this.isPaid &&
          other.paymentMethod == this.paymentMethod &&
          other.secret == this.secret &&
          other.updatedAt == this.updatedAt);
}

class WardrobeSlotsCompanion extends UpdateCompanion<WardrobeSlot> {
  final Value<int> id;
  final Value<String> status;
  final Value<bool> isPaid;
  final Value<String> paymentMethod;
  final Value<String> secret;
  final Value<DateTime> updatedAt;
  const WardrobeSlotsCompanion({
    this.id = const Value.absent(),
    this.status = const Value.absent(),
    this.isPaid = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.secret = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  WardrobeSlotsCompanion.insert({
    this.id = const Value.absent(),
    this.status = const Value.absent(),
    this.isPaid = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.secret = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  static Insertable<WardrobeSlot> custom({
    Expression<int>? id,
    Expression<String>? status,
    Expression<bool>? isPaid,
    Expression<String>? paymentMethod,
    Expression<String>? secret,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (status != null) 'status': status,
      if (isPaid != null) 'is_paid': isPaid,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (secret != null) 'secret': secret,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  WardrobeSlotsCompanion copyWith(
      {Value<int>? id,
      Value<String>? status,
      Value<bool>? isPaid,
      Value<String>? paymentMethod,
      Value<String>? secret,
      Value<DateTime>? updatedAt}) {
    return WardrobeSlotsCompanion(
      id: id ?? this.id,
      status: status ?? this.status,
      isPaid: isPaid ?? this.isPaid,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      secret: secret ?? this.secret,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (isPaid.present) {
      map['is_paid'] = Variable<bool>(isPaid.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (secret.present) {
      map['secret'] = Variable<String>(secret.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WardrobeSlotsCompanion(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('isPaid: $isPaid, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('secret: $secret, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WardrobeSlotsTable wardrobeSlots = $WardrobeSlotsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [wardrobeSlots];
}

typedef $$WardrobeSlotsTableCreateCompanionBuilder = WardrobeSlotsCompanion
    Function({
  Value<int> id,
  Value<String> status,
  Value<bool> isPaid,
  Value<String> paymentMethod,
  Value<String> secret,
  Value<DateTime> updatedAt,
});
typedef $$WardrobeSlotsTableUpdateCompanionBuilder = WardrobeSlotsCompanion
    Function({
  Value<int> id,
  Value<String> status,
  Value<bool> isPaid,
  Value<String> paymentMethod,
  Value<String> secret,
  Value<DateTime> updatedAt,
});

class $$WardrobeSlotsTableFilterComposer
    extends Composer<_$AppDatabase, $WardrobeSlotsTable> {
  $$WardrobeSlotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPaid => $composableBuilder(
      column: $table.isPaid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get secret => $composableBuilder(
      column: $table.secret, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$WardrobeSlotsTableOrderingComposer
    extends Composer<_$AppDatabase, $WardrobeSlotsTable> {
  $$WardrobeSlotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPaid => $composableBuilder(
      column: $table.isPaid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get secret => $composableBuilder(
      column: $table.secret, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$WardrobeSlotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WardrobeSlotsTable> {
  $$WardrobeSlotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get isPaid =>
      $composableBuilder(column: $table.isPaid, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod, builder: (column) => column);

  GeneratedColumn<String> get secret =>
      $composableBuilder(column: $table.secret, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WardrobeSlotsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WardrobeSlotsTable,
    WardrobeSlot,
    $$WardrobeSlotsTableFilterComposer,
    $$WardrobeSlotsTableOrderingComposer,
    $$WardrobeSlotsTableAnnotationComposer,
    $$WardrobeSlotsTableCreateCompanionBuilder,
    $$WardrobeSlotsTableUpdateCompanionBuilder,
    (
      WardrobeSlot,
      BaseReferences<_$AppDatabase, $WardrobeSlotsTable, WardrobeSlot>
    ),
    WardrobeSlot,
    PrefetchHooks Function()> {
  $$WardrobeSlotsTableTableManager(_$AppDatabase db, $WardrobeSlotsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WardrobeSlotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WardrobeSlotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WardrobeSlotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<bool> isPaid = const Value.absent(),
            Value<String> paymentMethod = const Value.absent(),
            Value<String> secret = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              WardrobeSlotsCompanion(
            id: id,
            status: status,
            isPaid: isPaid,
            paymentMethod: paymentMethod,
            secret: secret,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<bool> isPaid = const Value.absent(),
            Value<String> paymentMethod = const Value.absent(),
            Value<String> secret = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              WardrobeSlotsCompanion.insert(
            id: id,
            status: status,
            isPaid: isPaid,
            paymentMethod: paymentMethod,
            secret: secret,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WardrobeSlotsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WardrobeSlotsTable,
    WardrobeSlot,
    $$WardrobeSlotsTableFilterComposer,
    $$WardrobeSlotsTableOrderingComposer,
    $$WardrobeSlotsTableAnnotationComposer,
    $$WardrobeSlotsTableCreateCompanionBuilder,
    $$WardrobeSlotsTableUpdateCompanionBuilder,
    (
      WardrobeSlot,
      BaseReferences<_$AppDatabase, $WardrobeSlotsTable, WardrobeSlot>
    ),
    WardrobeSlot,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WardrobeSlotsTableTableManager get wardrobeSlots =>
      $$WardrobeSlotsTableTableManager(_db, _db.wardrobeSlots);
}
