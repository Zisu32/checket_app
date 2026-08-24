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
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
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
      [id, status, isPaid, paymentMethod, secret, groupId, updatedAt];
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
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
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
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
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
  final String groupId;
  final DateTime updatedAt;
  const WardrobeSlot(
      {required this.id,
      required this.status,
      required this.isPaid,
      required this.paymentMethod,
      required this.secret,
      required this.groupId,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['status'] = Variable<String>(status);
    map['is_paid'] = Variable<bool>(isPaid);
    map['payment_method'] = Variable<String>(paymentMethod);
    map['secret'] = Variable<String>(secret);
    map['group_id'] = Variable<String>(groupId);
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
      groupId: Value(groupId),
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
      groupId: serializer.fromJson<String>(json['groupId']),
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
      'groupId': serializer.toJson<String>(groupId),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WardrobeSlot copyWith(
          {int? id,
          String? status,
          bool? isPaid,
          String? paymentMethod,
          String? secret,
          String? groupId,
          DateTime? updatedAt}) =>
      WardrobeSlot(
        id: id ?? this.id,
        status: status ?? this.status,
        isPaid: isPaid ?? this.isPaid,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        secret: secret ?? this.secret,
        groupId: groupId ?? this.groupId,
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
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
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
          ..write('groupId: $groupId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, status, isPaid, paymentMethod, secret, groupId, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WardrobeSlot &&
          other.id == this.id &&
          other.status == this.status &&
          other.isPaid == this.isPaid &&
          other.paymentMethod == this.paymentMethod &&
          other.secret == this.secret &&
          other.groupId == this.groupId &&
          other.updatedAt == this.updatedAt);
}

class WardrobeSlotsCompanion extends UpdateCompanion<WardrobeSlot> {
  final Value<int> id;
  final Value<String> status;
  final Value<bool> isPaid;
  final Value<String> paymentMethod;
  final Value<String> secret;
  final Value<String> groupId;
  final Value<DateTime> updatedAt;
  const WardrobeSlotsCompanion({
    this.id = const Value.absent(),
    this.status = const Value.absent(),
    this.isPaid = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.secret = const Value.absent(),
    this.groupId = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  WardrobeSlotsCompanion.insert({
    this.id = const Value.absent(),
    this.status = const Value.absent(),
    this.isPaid = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.secret = const Value.absent(),
    this.groupId = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  static Insertable<WardrobeSlot> custom({
    Expression<int>? id,
    Expression<String>? status,
    Expression<bool>? isPaid,
    Expression<String>? paymentMethod,
    Expression<String>? secret,
    Expression<String>? groupId,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (status != null) 'status': status,
      if (isPaid != null) 'is_paid': isPaid,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (secret != null) 'secret': secret,
      if (groupId != null) 'group_id': groupId,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  WardrobeSlotsCompanion copyWith(
      {Value<int>? id,
      Value<String>? status,
      Value<bool>? isPaid,
      Value<String>? paymentMethod,
      Value<String>? secret,
      Value<String>? groupId,
      Value<DateTime>? updatedAt}) {
    return WardrobeSlotsCompanion(
      id: id ?? this.id,
      status: status ?? this.status,
      isPaid: isPaid ?? this.isPaid,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      secret: secret ?? this.secret,
      groupId: groupId ?? this.groupId,
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
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
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
          ..write('groupId: $groupId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LostItemsTable extends LostItems
    with TableInfo<$LostItemsTable, LostItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LostItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _originalSlotIdMeta =
      const VerificationMeta('originalSlotId');
  @override
  late final GeneratedColumn<int> originalSlotId = GeneratedColumn<int>(
      'original_slot_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _secretMeta = const VerificationMeta('secret');
  @override
  late final GeneratedColumn<String> secret = GeneratedColumn<String>(
      'secret', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isPaidMeta = const VerificationMeta('isPaid');
  @override
  late final GeneratedColumn<bool> isPaid = GeneratedColumn<bool>(
      'is_paid', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_paid" IN (0, 1))'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isHandedOverMeta =
      const VerificationMeta('isHandedOver');
  @override
  late final GeneratedColumn<bool> isHandedOver = GeneratedColumn<bool>(
      'is_handed_over', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_handed_over" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, originalSlotId, secret, isPaid, createdAt, isHandedOver];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'checket_lost_found';
  @override
  VerificationContext validateIntegrity(Insertable<LostItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('original_slot_id')) {
      context.handle(
          _originalSlotIdMeta,
          originalSlotId.isAcceptableOrUnknown(
              data['original_slot_id']!, _originalSlotIdMeta));
    } else if (isInserting) {
      context.missing(_originalSlotIdMeta);
    }
    if (data.containsKey('secret')) {
      context.handle(_secretMeta,
          secret.isAcceptableOrUnknown(data['secret']!, _secretMeta));
    } else if (isInserting) {
      context.missing(_secretMeta);
    }
    if (data.containsKey('is_paid')) {
      context.handle(_isPaidMeta,
          isPaid.isAcceptableOrUnknown(data['is_paid']!, _isPaidMeta));
    } else if (isInserting) {
      context.missing(_isPaidMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_handed_over')) {
      context.handle(
          _isHandedOverMeta,
          isHandedOver.isAcceptableOrUnknown(
              data['is_handed_over']!, _isHandedOverMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LostItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LostItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      originalSlotId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}original_slot_id'])!,
      secret: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}secret'])!,
      isPaid: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_paid'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isHandedOver: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_handed_over'])!,
    );
  }

  @override
  $LostItemsTable createAlias(String alias) {
    return $LostItemsTable(attachedDatabase, alias);
  }
}

class LostItem extends DataClass implements Insertable<LostItem> {
  final String id;
  final int originalSlotId;
  final String secret;
  final bool isPaid;
  final DateTime createdAt;
  final bool isHandedOver;
  const LostItem(
      {required this.id,
      required this.originalSlotId,
      required this.secret,
      required this.isPaid,
      required this.createdAt,
      required this.isHandedOver});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['original_slot_id'] = Variable<int>(originalSlotId);
    map['secret'] = Variable<String>(secret);
    map['is_paid'] = Variable<bool>(isPaid);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_handed_over'] = Variable<bool>(isHandedOver);
    return map;
  }

  LostItemsCompanion toCompanion(bool nullToAbsent) {
    return LostItemsCompanion(
      id: Value(id),
      originalSlotId: Value(originalSlotId),
      secret: Value(secret),
      isPaid: Value(isPaid),
      createdAt: Value(createdAt),
      isHandedOver: Value(isHandedOver),
    );
  }

  factory LostItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LostItem(
      id: serializer.fromJson<String>(json['id']),
      originalSlotId: serializer.fromJson<int>(json['originalSlotId']),
      secret: serializer.fromJson<String>(json['secret']),
      isPaid: serializer.fromJson<bool>(json['isPaid']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isHandedOver: serializer.fromJson<bool>(json['isHandedOver']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'originalSlotId': serializer.toJson<int>(originalSlotId),
      'secret': serializer.toJson<String>(secret),
      'isPaid': serializer.toJson<bool>(isPaid),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isHandedOver': serializer.toJson<bool>(isHandedOver),
    };
  }

  LostItem copyWith(
          {String? id,
          int? originalSlotId,
          String? secret,
          bool? isPaid,
          DateTime? createdAt,
          bool? isHandedOver}) =>
      LostItem(
        id: id ?? this.id,
        originalSlotId: originalSlotId ?? this.originalSlotId,
        secret: secret ?? this.secret,
        isPaid: isPaid ?? this.isPaid,
        createdAt: createdAt ?? this.createdAt,
        isHandedOver: isHandedOver ?? this.isHandedOver,
      );
  LostItem copyWithCompanion(LostItemsCompanion data) {
    return LostItem(
      id: data.id.present ? data.id.value : this.id,
      originalSlotId: data.originalSlotId.present
          ? data.originalSlotId.value
          : this.originalSlotId,
      secret: data.secret.present ? data.secret.value : this.secret,
      isPaid: data.isPaid.present ? data.isPaid.value : this.isPaid,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isHandedOver: data.isHandedOver.present
          ? data.isHandedOver.value
          : this.isHandedOver,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LostItem(')
          ..write('id: $id, ')
          ..write('originalSlotId: $originalSlotId, ')
          ..write('secret: $secret, ')
          ..write('isPaid: $isPaid, ')
          ..write('createdAt: $createdAt, ')
          ..write('isHandedOver: $isHandedOver')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, originalSlotId, secret, isPaid, createdAt, isHandedOver);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LostItem &&
          other.id == this.id &&
          other.originalSlotId == this.originalSlotId &&
          other.secret == this.secret &&
          other.isPaid == this.isPaid &&
          other.createdAt == this.createdAt &&
          other.isHandedOver == this.isHandedOver);
}

class LostItemsCompanion extends UpdateCompanion<LostItem> {
  final Value<String> id;
  final Value<int> originalSlotId;
  final Value<String> secret;
  final Value<bool> isPaid;
  final Value<DateTime> createdAt;
  final Value<bool> isHandedOver;
  final Value<int> rowid;
  const LostItemsCompanion({
    this.id = const Value.absent(),
    this.originalSlotId = const Value.absent(),
    this.secret = const Value.absent(),
    this.isPaid = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isHandedOver = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LostItemsCompanion.insert({
    required String id,
    required int originalSlotId,
    required String secret,
    required bool isPaid,
    required DateTime createdAt,
    this.isHandedOver = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        originalSlotId = Value(originalSlotId),
        secret = Value(secret),
        isPaid = Value(isPaid),
        createdAt = Value(createdAt);
  static Insertable<LostItem> custom({
    Expression<String>? id,
    Expression<int>? originalSlotId,
    Expression<String>? secret,
    Expression<bool>? isPaid,
    Expression<DateTime>? createdAt,
    Expression<bool>? isHandedOver,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (originalSlotId != null) 'original_slot_id': originalSlotId,
      if (secret != null) 'secret': secret,
      if (isPaid != null) 'is_paid': isPaid,
      if (createdAt != null) 'created_at': createdAt,
      if (isHandedOver != null) 'is_handed_over': isHandedOver,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LostItemsCompanion copyWith(
      {Value<String>? id,
      Value<int>? originalSlotId,
      Value<String>? secret,
      Value<bool>? isPaid,
      Value<DateTime>? createdAt,
      Value<bool>? isHandedOver,
      Value<int>? rowid}) {
    return LostItemsCompanion(
      id: id ?? this.id,
      originalSlotId: originalSlotId ?? this.originalSlotId,
      secret: secret ?? this.secret,
      isPaid: isPaid ?? this.isPaid,
      createdAt: createdAt ?? this.createdAt,
      isHandedOver: isHandedOver ?? this.isHandedOver,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (originalSlotId.present) {
      map['original_slot_id'] = Variable<int>(originalSlotId.value);
    }
    if (secret.present) {
      map['secret'] = Variable<String>(secret.value);
    }
    if (isPaid.present) {
      map['is_paid'] = Variable<bool>(isPaid.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isHandedOver.present) {
      map['is_handed_over'] = Variable<bool>(isHandedOver.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LostItemsCompanion(')
          ..write('id: $id, ')
          ..write('originalSlotId: $originalSlotId, ')
          ..write('secret: $secret, ')
          ..write('isPaid: $isPaid, ')
          ..write('createdAt: $createdAt, ')
          ..write('isHandedOver: $isHandedOver, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WardrobeSlotsTable wardrobeSlots = $WardrobeSlotsTable(this);
  late final $LostItemsTable lostItems = $LostItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [wardrobeSlots, lostItems];
}

typedef $$WardrobeSlotsTableCreateCompanionBuilder = WardrobeSlotsCompanion
    Function({
  Value<int> id,
  Value<String> status,
  Value<bool> isPaid,
  Value<String> paymentMethod,
  Value<String> secret,
  Value<String> groupId,
  Value<DateTime> updatedAt,
});
typedef $$WardrobeSlotsTableUpdateCompanionBuilder = WardrobeSlotsCompanion
    Function({
  Value<int> id,
  Value<String> status,
  Value<bool> isPaid,
  Value<String> paymentMethod,
  Value<String> secret,
  Value<String> groupId,
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

  ColumnFilters<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

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
            Value<String> groupId = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              WardrobeSlotsCompanion(
            id: id,
            status: status,
            isPaid: isPaid,
            paymentMethod: paymentMethod,
            secret: secret,
            groupId: groupId,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<bool> isPaid = const Value.absent(),
            Value<String> paymentMethod = const Value.absent(),
            Value<String> secret = const Value.absent(),
            Value<String> groupId = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              WardrobeSlotsCompanion.insert(
            id: id,
            status: status,
            isPaid: isPaid,
            paymentMethod: paymentMethod,
            secret: secret,
            groupId: groupId,
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
typedef $$LostItemsTableCreateCompanionBuilder = LostItemsCompanion Function({
  required String id,
  required int originalSlotId,
  required String secret,
  required bool isPaid,
  required DateTime createdAt,
  Value<bool> isHandedOver,
  Value<int> rowid,
});
typedef $$LostItemsTableUpdateCompanionBuilder = LostItemsCompanion Function({
  Value<String> id,
  Value<int> originalSlotId,
  Value<String> secret,
  Value<bool> isPaid,
  Value<DateTime> createdAt,
  Value<bool> isHandedOver,
  Value<int> rowid,
});

class $$LostItemsTableFilterComposer
    extends Composer<_$AppDatabase, $LostItemsTable> {
  $$LostItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get originalSlotId => $composableBuilder(
      column: $table.originalSlotId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get secret => $composableBuilder(
      column: $table.secret, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPaid => $composableBuilder(
      column: $table.isPaid, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isHandedOver => $composableBuilder(
      column: $table.isHandedOver, builder: (column) => ColumnFilters(column));
}

class $$LostItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $LostItemsTable> {
  $$LostItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get originalSlotId => $composableBuilder(
      column: $table.originalSlotId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get secret => $composableBuilder(
      column: $table.secret, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPaid => $composableBuilder(
      column: $table.isPaid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isHandedOver => $composableBuilder(
      column: $table.isHandedOver,
      builder: (column) => ColumnOrderings(column));
}

class $$LostItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LostItemsTable> {
  $$LostItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get originalSlotId => $composableBuilder(
      column: $table.originalSlotId, builder: (column) => column);

  GeneratedColumn<String> get secret =>
      $composableBuilder(column: $table.secret, builder: (column) => column);

  GeneratedColumn<bool> get isPaid =>
      $composableBuilder(column: $table.isPaid, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isHandedOver => $composableBuilder(
      column: $table.isHandedOver, builder: (column) => column);
}

class $$LostItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LostItemsTable,
    LostItem,
    $$LostItemsTableFilterComposer,
    $$LostItemsTableOrderingComposer,
    $$LostItemsTableAnnotationComposer,
    $$LostItemsTableCreateCompanionBuilder,
    $$LostItemsTableUpdateCompanionBuilder,
    (LostItem, BaseReferences<_$AppDatabase, $LostItemsTable, LostItem>),
    LostItem,
    PrefetchHooks Function()> {
  $$LostItemsTableTableManager(_$AppDatabase db, $LostItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LostItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LostItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LostItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> originalSlotId = const Value.absent(),
            Value<String> secret = const Value.absent(),
            Value<bool> isPaid = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isHandedOver = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LostItemsCompanion(
            id: id,
            originalSlotId: originalSlotId,
            secret: secret,
            isPaid: isPaid,
            createdAt: createdAt,
            isHandedOver: isHandedOver,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required int originalSlotId,
            required String secret,
            required bool isPaid,
            required DateTime createdAt,
            Value<bool> isHandedOver = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LostItemsCompanion.insert(
            id: id,
            originalSlotId: originalSlotId,
            secret: secret,
            isPaid: isPaid,
            createdAt: createdAt,
            isHandedOver: isHandedOver,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LostItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LostItemsTable,
    LostItem,
    $$LostItemsTableFilterComposer,
    $$LostItemsTableOrderingComposer,
    $$LostItemsTableAnnotationComposer,
    $$LostItemsTableCreateCompanionBuilder,
    $$LostItemsTableUpdateCompanionBuilder,
    (LostItem, BaseReferences<_$AppDatabase, $LostItemsTable, LostItem>),
    LostItem,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WardrobeSlotsTableTableManager get wardrobeSlots =>
      $$WardrobeSlotsTableTableManager(_db, _db.wardrobeSlots);
  $$LostItemsTableTableManager get lostItems =>
      $$LostItemsTableTableManager(_db, _db.lostItems);
}
