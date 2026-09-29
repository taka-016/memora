// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_database.dart';

// ignore_for_file: type=lint
class Members extends Table with TableInfo<Members, SqliteMemberRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Members(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES members(id)ON DELETE RESTRICT',
  );
  static const VerificationMeta _hiraganaFirstNameMeta = const VerificationMeta(
    'hiraganaFirstName',
  );
  late final GeneratedColumn<String> hiraganaFirstName =
      GeneratedColumn<String>(
        'hiragana_first_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: '',
      );
  static const VerificationMeta _hiraganaLastNameMeta = const VerificationMeta(
    'hiraganaLastName',
  );
  late final GeneratedColumn<String> hiraganaLastName = GeneratedColumn<String>(
    'hiragana_last_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _kanjiFirstNameMeta = const VerificationMeta(
    'kanjiFirstName',
  );
  late final GeneratedColumn<String> kanjiFirstName = GeneratedColumn<String>(
    'kanji_first_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _kanjiLastNameMeta = const VerificationMeta(
    'kanjiLastName',
  );
  late final GeneratedColumn<String> kanjiLastName = GeneratedColumn<String>(
    'kanji_last_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _firstNameMeta = const VerificationMeta(
    'firstName',
  );
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
    'first_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _lastNameMeta = const VerificationMeta(
    'lastName',
  );
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
    'last_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _birthdayMeta = const VerificationMeta(
    'birthday',
  );
  late final GeneratedColumn<int> birthday = GeneratedColumn<int>(
    'birthday',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
    'gender',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _phoneNumberMeta = const VerificationMeta(
    'phoneNumber',
  );
  late final GeneratedColumn<String> phoneNumber = GeneratedColumn<String>(
    'phone_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    ownerId,
    hiraganaFirstName,
    hiraganaLastName,
    kanjiFirstName,
    kanjiLastName,
    firstName,
    lastName,
    displayName,
    type,
    birthday,
    gender,
    email,
    phoneNumber,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'members';
  @override
  VerificationContext validateIntegrity(
    Insertable<SqliteMemberRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    }
    if (data.containsKey('hiragana_first_name')) {
      context.handle(
        _hiraganaFirstNameMeta,
        hiraganaFirstName.isAcceptableOrUnknown(
          data['hiragana_first_name']!,
          _hiraganaFirstNameMeta,
        ),
      );
    }
    if (data.containsKey('hiragana_last_name')) {
      context.handle(
        _hiraganaLastNameMeta,
        hiraganaLastName.isAcceptableOrUnknown(
          data['hiragana_last_name']!,
          _hiraganaLastNameMeta,
        ),
      );
    }
    if (data.containsKey('kanji_first_name')) {
      context.handle(
        _kanjiFirstNameMeta,
        kanjiFirstName.isAcceptableOrUnknown(
          data['kanji_first_name']!,
          _kanjiFirstNameMeta,
        ),
      );
    }
    if (data.containsKey('kanji_last_name')) {
      context.handle(
        _kanjiLastNameMeta,
        kanjiLastName.isAcceptableOrUnknown(
          data['kanji_last_name']!,
          _kanjiLastNameMeta,
        ),
      );
    }
    if (data.containsKey('first_name')) {
      context.handle(
        _firstNameMeta,
        firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta),
      );
    }
    if (data.containsKey('last_name')) {
      context.handle(
        _lastNameMeta,
        lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta),
      );
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('birthday')) {
      context.handle(
        _birthdayMeta,
        birthday.isAcceptableOrUnknown(data['birthday']!, _birthdayMeta),
      );
    }
    if (data.containsKey('gender')) {
      context.handle(
        _genderMeta,
        gender.isAcceptableOrUnknown(data['gender']!, _genderMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('phone_number')) {
      context.handle(
        _phoneNumberMeta,
        phoneNumber.isAcceptableOrUnknown(
          data['phone_number']!,
          _phoneNumberMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {accountId},
  ];
  @override
  SqliteMemberRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SqliteMemberRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      ),
      hiraganaFirstName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hiragana_first_name'],
      ),
      hiraganaLastName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hiragana_last_name'],
      ),
      kanjiFirstName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kanji_first_name'],
      ),
      kanjiLastName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kanji_last_name'],
      ),
      firstName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_name'],
      ),
      lastName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_name'],
      ),
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      ),
      birthday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}birthday'],
      ),
      gender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gender'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      phoneNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone_number'],
      ),
    );
  }

  @override
  Members createAlias(String alias) {
    return Members(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['UNIQUE(account_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class SqliteMemberRow extends DataClass implements Insertable<SqliteMemberRow> {
  final String id;
  final String? accountId;
  final String? ownerId;
  final String? hiraganaFirstName;
  final String? hiraganaLastName;
  final String? kanjiFirstName;
  final String? kanjiLastName;
  final String? firstName;
  final String? lastName;
  final String displayName;
  final String? type;
  final int? birthday;
  final String? gender;
  final String? email;
  final String? phoneNumber;
  const SqliteMemberRow({
    required this.id,
    this.accountId,
    this.ownerId,
    this.hiraganaFirstName,
    this.hiraganaLastName,
    this.kanjiFirstName,
    this.kanjiLastName,
    this.firstName,
    this.lastName,
    required this.displayName,
    this.type,
    this.birthday,
    this.gender,
    this.email,
    this.phoneNumber,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    if (!nullToAbsent || ownerId != null) {
      map['owner_id'] = Variable<String>(ownerId);
    }
    if (!nullToAbsent || hiraganaFirstName != null) {
      map['hiragana_first_name'] = Variable<String>(hiraganaFirstName);
    }
    if (!nullToAbsent || hiraganaLastName != null) {
      map['hiragana_last_name'] = Variable<String>(hiraganaLastName);
    }
    if (!nullToAbsent || kanjiFirstName != null) {
      map['kanji_first_name'] = Variable<String>(kanjiFirstName);
    }
    if (!nullToAbsent || kanjiLastName != null) {
      map['kanji_last_name'] = Variable<String>(kanjiLastName);
    }
    if (!nullToAbsent || firstName != null) {
      map['first_name'] = Variable<String>(firstName);
    }
    if (!nullToAbsent || lastName != null) {
      map['last_name'] = Variable<String>(lastName);
    }
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || type != null) {
      map['type'] = Variable<String>(type);
    }
    if (!nullToAbsent || birthday != null) {
      map['birthday'] = Variable<int>(birthday);
    }
    if (!nullToAbsent || gender != null) {
      map['gender'] = Variable<String>(gender);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || phoneNumber != null) {
      map['phone_number'] = Variable<String>(phoneNumber);
    }
    return map;
  }

  MembersCompanion toCompanion(bool nullToAbsent) {
    return MembersCompanion(
      id: Value(id),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      ownerId: ownerId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerId),
      hiraganaFirstName: hiraganaFirstName == null && nullToAbsent
          ? const Value.absent()
          : Value(hiraganaFirstName),
      hiraganaLastName: hiraganaLastName == null && nullToAbsent
          ? const Value.absent()
          : Value(hiraganaLastName),
      kanjiFirstName: kanjiFirstName == null && nullToAbsent
          ? const Value.absent()
          : Value(kanjiFirstName),
      kanjiLastName: kanjiLastName == null && nullToAbsent
          ? const Value.absent()
          : Value(kanjiLastName),
      firstName: firstName == null && nullToAbsent
          ? const Value.absent()
          : Value(firstName),
      lastName: lastName == null && nullToAbsent
          ? const Value.absent()
          : Value(lastName),
      displayName: Value(displayName),
      type: type == null && nullToAbsent ? const Value.absent() : Value(type),
      birthday: birthday == null && nullToAbsent
          ? const Value.absent()
          : Value(birthday),
      gender: gender == null && nullToAbsent
          ? const Value.absent()
          : Value(gender),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      phoneNumber: phoneNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneNumber),
    );
  }

  factory SqliteMemberRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SqliteMemberRow(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String?>(json['account_id']),
      ownerId: serializer.fromJson<String?>(json['owner_id']),
      hiraganaFirstName: serializer.fromJson<String?>(
        json['hiragana_first_name'],
      ),
      hiraganaLastName: serializer.fromJson<String?>(
        json['hiragana_last_name'],
      ),
      kanjiFirstName: serializer.fromJson<String?>(json['kanji_first_name']),
      kanjiLastName: serializer.fromJson<String?>(json['kanji_last_name']),
      firstName: serializer.fromJson<String?>(json['first_name']),
      lastName: serializer.fromJson<String?>(json['last_name']),
      displayName: serializer.fromJson<String>(json['display_name']),
      type: serializer.fromJson<String?>(json['type']),
      birthday: serializer.fromJson<int?>(json['birthday']),
      gender: serializer.fromJson<String?>(json['gender']),
      email: serializer.fromJson<String?>(json['email']),
      phoneNumber: serializer.fromJson<String?>(json['phone_number']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'account_id': serializer.toJson<String?>(accountId),
      'owner_id': serializer.toJson<String?>(ownerId),
      'hiragana_first_name': serializer.toJson<String?>(hiraganaFirstName),
      'hiragana_last_name': serializer.toJson<String?>(hiraganaLastName),
      'kanji_first_name': serializer.toJson<String?>(kanjiFirstName),
      'kanji_last_name': serializer.toJson<String?>(kanjiLastName),
      'first_name': serializer.toJson<String?>(firstName),
      'last_name': serializer.toJson<String?>(lastName),
      'display_name': serializer.toJson<String>(displayName),
      'type': serializer.toJson<String?>(type),
      'birthday': serializer.toJson<int?>(birthday),
      'gender': serializer.toJson<String?>(gender),
      'email': serializer.toJson<String?>(email),
      'phone_number': serializer.toJson<String?>(phoneNumber),
    };
  }

  SqliteMemberRow copyWith({
    String? id,
    Value<String?> accountId = const Value.absent(),
    Value<String?> ownerId = const Value.absent(),
    Value<String?> hiraganaFirstName = const Value.absent(),
    Value<String?> hiraganaLastName = const Value.absent(),
    Value<String?> kanjiFirstName = const Value.absent(),
    Value<String?> kanjiLastName = const Value.absent(),
    Value<String?> firstName = const Value.absent(),
    Value<String?> lastName = const Value.absent(),
    String? displayName,
    Value<String?> type = const Value.absent(),
    Value<int?> birthday = const Value.absent(),
    Value<String?> gender = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<String?> phoneNumber = const Value.absent(),
  }) => SqliteMemberRow(
    id: id ?? this.id,
    accountId: accountId.present ? accountId.value : this.accountId,
    ownerId: ownerId.present ? ownerId.value : this.ownerId,
    hiraganaFirstName: hiraganaFirstName.present
        ? hiraganaFirstName.value
        : this.hiraganaFirstName,
    hiraganaLastName: hiraganaLastName.present
        ? hiraganaLastName.value
        : this.hiraganaLastName,
    kanjiFirstName: kanjiFirstName.present
        ? kanjiFirstName.value
        : this.kanjiFirstName,
    kanjiLastName: kanjiLastName.present
        ? kanjiLastName.value
        : this.kanjiLastName,
    firstName: firstName.present ? firstName.value : this.firstName,
    lastName: lastName.present ? lastName.value : this.lastName,
    displayName: displayName ?? this.displayName,
    type: type.present ? type.value : this.type,
    birthday: birthday.present ? birthday.value : this.birthday,
    gender: gender.present ? gender.value : this.gender,
    email: email.present ? email.value : this.email,
    phoneNumber: phoneNumber.present ? phoneNumber.value : this.phoneNumber,
  );
  SqliteMemberRow copyWithCompanion(MembersCompanion data) {
    return SqliteMemberRow(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      hiraganaFirstName: data.hiraganaFirstName.present
          ? data.hiraganaFirstName.value
          : this.hiraganaFirstName,
      hiraganaLastName: data.hiraganaLastName.present
          ? data.hiraganaLastName.value
          : this.hiraganaLastName,
      kanjiFirstName: data.kanjiFirstName.present
          ? data.kanjiFirstName.value
          : this.kanjiFirstName,
      kanjiLastName: data.kanjiLastName.present
          ? data.kanjiLastName.value
          : this.kanjiLastName,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      type: data.type.present ? data.type.value : this.type,
      birthday: data.birthday.present ? data.birthday.value : this.birthday,
      gender: data.gender.present ? data.gender.value : this.gender,
      email: data.email.present ? data.email.value : this.email,
      phoneNumber: data.phoneNumber.present
          ? data.phoneNumber.value
          : this.phoneNumber,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SqliteMemberRow(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('ownerId: $ownerId, ')
          ..write('hiraganaFirstName: $hiraganaFirstName, ')
          ..write('hiraganaLastName: $hiraganaLastName, ')
          ..write('kanjiFirstName: $kanjiFirstName, ')
          ..write('kanjiLastName: $kanjiLastName, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('displayName: $displayName, ')
          ..write('type: $type, ')
          ..write('birthday: $birthday, ')
          ..write('gender: $gender, ')
          ..write('email: $email, ')
          ..write('phoneNumber: $phoneNumber')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    ownerId,
    hiraganaFirstName,
    hiraganaLastName,
    kanjiFirstName,
    kanjiLastName,
    firstName,
    lastName,
    displayName,
    type,
    birthday,
    gender,
    email,
    phoneNumber,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SqliteMemberRow &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.ownerId == this.ownerId &&
          other.hiraganaFirstName == this.hiraganaFirstName &&
          other.hiraganaLastName == this.hiraganaLastName &&
          other.kanjiFirstName == this.kanjiFirstName &&
          other.kanjiLastName == this.kanjiLastName &&
          other.firstName == this.firstName &&
          other.lastName == this.lastName &&
          other.displayName == this.displayName &&
          other.type == this.type &&
          other.birthday == this.birthday &&
          other.gender == this.gender &&
          other.email == this.email &&
          other.phoneNumber == this.phoneNumber);
}

class MembersCompanion extends UpdateCompanion<SqliteMemberRow> {
  final Value<String> id;
  final Value<String?> accountId;
  final Value<String?> ownerId;
  final Value<String?> hiraganaFirstName;
  final Value<String?> hiraganaLastName;
  final Value<String?> kanjiFirstName;
  final Value<String?> kanjiLastName;
  final Value<String?> firstName;
  final Value<String?> lastName;
  final Value<String> displayName;
  final Value<String?> type;
  final Value<int?> birthday;
  final Value<String?> gender;
  final Value<String?> email;
  final Value<String?> phoneNumber;
  final Value<int> rowid;
  const MembersCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.hiraganaFirstName = const Value.absent(),
    this.hiraganaLastName = const Value.absent(),
    this.kanjiFirstName = const Value.absent(),
    this.kanjiLastName = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.displayName = const Value.absent(),
    this.type = const Value.absent(),
    this.birthday = const Value.absent(),
    this.gender = const Value.absent(),
    this.email = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MembersCompanion.insert({
    required String id,
    this.accountId = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.hiraganaFirstName = const Value.absent(),
    this.hiraganaLastName = const Value.absent(),
    this.kanjiFirstName = const Value.absent(),
    this.kanjiLastName = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    required String displayName,
    this.type = const Value.absent(),
    this.birthday = const Value.absent(),
    this.gender = const Value.absent(),
    this.email = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       displayName = Value(displayName);
  static Insertable<SqliteMemberRow> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? ownerId,
    Expression<String>? hiraganaFirstName,
    Expression<String>? hiraganaLastName,
    Expression<String>? kanjiFirstName,
    Expression<String>? kanjiLastName,
    Expression<String>? firstName,
    Expression<String>? lastName,
    Expression<String>? displayName,
    Expression<String>? type,
    Expression<int>? birthday,
    Expression<String>? gender,
    Expression<String>? email,
    Expression<String>? phoneNumber,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (ownerId != null) 'owner_id': ownerId,
      if (hiraganaFirstName != null) 'hiragana_first_name': hiraganaFirstName,
      if (hiraganaLastName != null) 'hiragana_last_name': hiraganaLastName,
      if (kanjiFirstName != null) 'kanji_first_name': kanjiFirstName,
      if (kanjiLastName != null) 'kanji_last_name': kanjiLastName,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (displayName != null) 'display_name': displayName,
      if (type != null) 'type': type,
      if (birthday != null) 'birthday': birthday,
      if (gender != null) 'gender': gender,
      if (email != null) 'email': email,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MembersCompanion copyWith({
    Value<String>? id,
    Value<String?>? accountId,
    Value<String?>? ownerId,
    Value<String?>? hiraganaFirstName,
    Value<String?>? hiraganaLastName,
    Value<String?>? kanjiFirstName,
    Value<String?>? kanjiLastName,
    Value<String?>? firstName,
    Value<String?>? lastName,
    Value<String>? displayName,
    Value<String?>? type,
    Value<int?>? birthday,
    Value<String?>? gender,
    Value<String?>? email,
    Value<String?>? phoneNumber,
    Value<int>? rowid,
  }) {
    return MembersCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      ownerId: ownerId ?? this.ownerId,
      hiraganaFirstName: hiraganaFirstName ?? this.hiraganaFirstName,
      hiraganaLastName: hiraganaLastName ?? this.hiraganaLastName,
      kanjiFirstName: kanjiFirstName ?? this.kanjiFirstName,
      kanjiLastName: kanjiLastName ?? this.kanjiLastName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      displayName: displayName ?? this.displayName,
      type: type ?? this.type,
      birthday: birthday ?? this.birthday,
      gender: gender ?? this.gender,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (hiraganaFirstName.present) {
      map['hiragana_first_name'] = Variable<String>(hiraganaFirstName.value);
    }
    if (hiraganaLastName.present) {
      map['hiragana_last_name'] = Variable<String>(hiraganaLastName.value);
    }
    if (kanjiFirstName.present) {
      map['kanji_first_name'] = Variable<String>(kanjiFirstName.value);
    }
    if (kanjiLastName.present) {
      map['kanji_last_name'] = Variable<String>(kanjiLastName.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (birthday.present) {
      map['birthday'] = Variable<int>(birthday.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (phoneNumber.present) {
      map['phone_number'] = Variable<String>(phoneNumber.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MembersCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('ownerId: $ownerId, ')
          ..write('hiraganaFirstName: $hiraganaFirstName, ')
          ..write('hiraganaLastName: $hiraganaLastName, ')
          ..write('kanjiFirstName: $kanjiFirstName, ')
          ..write('kanjiLastName: $kanjiLastName, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('displayName: $displayName, ')
          ..write('type: $type, ')
          ..write('birthday: $birthday, ')
          ..write('gender: $gender, ')
          ..write('email: $email, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Groups extends Table with TableInfo<Groups, SqliteGroupRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Groups(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES members(id)ON DELETE RESTRICT',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [id, ownerId, name, memo];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<SqliteGroupRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SqliteGroupRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SqliteGroupRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      ),
    );
  }

  @override
  Groups createAlias(String alias) {
    return Groups(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SqliteGroupRow extends DataClass implements Insertable<SqliteGroupRow> {
  final String id;
  final String ownerId;
  final String name;
  final String? memo;
  const SqliteGroupRow({
    required this.id,
    required this.ownerId,
    required this.name,
    this.memo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['owner_id'] = Variable<String>(ownerId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    return map;
  }

  GroupsCompanion toCompanion(bool nullToAbsent) {
    return GroupsCompanion(
      id: Value(id),
      ownerId: Value(ownerId),
      name: Value(name),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
    );
  }

  factory SqliteGroupRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SqliteGroupRow(
      id: serializer.fromJson<String>(json['id']),
      ownerId: serializer.fromJson<String>(json['owner_id']),
      name: serializer.fromJson<String>(json['name']),
      memo: serializer.fromJson<String?>(json['memo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'owner_id': serializer.toJson<String>(ownerId),
      'name': serializer.toJson<String>(name),
      'memo': serializer.toJson<String?>(memo),
    };
  }

  SqliteGroupRow copyWith({
    String? id,
    String? ownerId,
    String? name,
    Value<String?> memo = const Value.absent(),
  }) => SqliteGroupRow(
    id: id ?? this.id,
    ownerId: ownerId ?? this.ownerId,
    name: name ?? this.name,
    memo: memo.present ? memo.value : this.memo,
  );
  SqliteGroupRow copyWithCompanion(GroupsCompanion data) {
    return SqliteGroupRow(
      id: data.id.present ? data.id.value : this.id,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      name: data.name.present ? data.name.value : this.name,
      memo: data.memo.present ? data.memo.value : this.memo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SqliteGroupRow(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('name: $name, ')
          ..write('memo: $memo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ownerId, name, memo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SqliteGroupRow &&
          other.id == this.id &&
          other.ownerId == this.ownerId &&
          other.name == this.name &&
          other.memo == this.memo);
}

class GroupsCompanion extends UpdateCompanion<SqliteGroupRow> {
  final Value<String> id;
  final Value<String> ownerId;
  final Value<String> name;
  final Value<String?> memo;
  final Value<int> rowid;
  const GroupsCompanion({
    this.id = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.name = const Value.absent(),
    this.memo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupsCompanion.insert({
    required String id,
    required String ownerId,
    required String name,
    this.memo = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ownerId = Value(ownerId),
       name = Value(name);
  static Insertable<SqliteGroupRow> custom({
    Expression<String>? id,
    Expression<String>? ownerId,
    Expression<String>? name,
    Expression<String>? memo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerId != null) 'owner_id': ownerId,
      if (name != null) 'name': name,
      if (memo != null) 'memo': memo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupsCompanion copyWith({
    Value<String>? id,
    Value<String>? ownerId,
    Value<String>? name,
    Value<String?>? memo,
    Value<int>? rowid,
  }) {
    return GroupsCompanion(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      memo: memo ?? this.memo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupsCompanion(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('name: $name, ')
          ..write('memo: $memo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class GroupMembers extends Table
    with TableInfo<GroupMembers, SqliteGroupMemberRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  GroupMembers(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES "groups"(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES members(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _isAdministratorMeta = const VerificationMeta(
    'isAdministrator',
  );
  late final GeneratedColumn<int> isAdministrator = GeneratedColumn<int>(
    'is_administrator',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (is_administrator IN (0, 1))',
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    groupId,
    memberId,
    isAdministrator,
    orderIndex,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'group_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<SqliteGroupMemberRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('is_administrator')) {
      context.handle(
        _isAdministratorMeta,
        isAdministrator.isAcceptableOrUnknown(
          data['is_administrator']!,
          _isAdministratorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isAdministratorMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId, memberId};
  @override
  SqliteGroupMemberRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SqliteGroupMemberRow(
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      isAdministrator: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_administrator'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
    );
  }

  @override
  GroupMembers createAlias(String alias) {
    return GroupMembers(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(group_id, member_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class SqliteGroupMemberRow extends DataClass
    implements Insertable<SqliteGroupMemberRow> {
  final String groupId;
  final String memberId;
  final int isAdministrator;
  final int orderIndex;
  const SqliteGroupMemberRow({
    required this.groupId,
    required this.memberId,
    required this.isAdministrator,
    required this.orderIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<String>(groupId);
    map['member_id'] = Variable<String>(memberId);
    map['is_administrator'] = Variable<int>(isAdministrator);
    map['order_index'] = Variable<int>(orderIndex);
    return map;
  }

  GroupMembersCompanion toCompanion(bool nullToAbsent) {
    return GroupMembersCompanion(
      groupId: Value(groupId),
      memberId: Value(memberId),
      isAdministrator: Value(isAdministrator),
      orderIndex: Value(orderIndex),
    );
  }

  factory SqliteGroupMemberRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SqliteGroupMemberRow(
      groupId: serializer.fromJson<String>(json['group_id']),
      memberId: serializer.fromJson<String>(json['member_id']),
      isAdministrator: serializer.fromJson<int>(json['is_administrator']),
      orderIndex: serializer.fromJson<int>(json['order_index']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'group_id': serializer.toJson<String>(groupId),
      'member_id': serializer.toJson<String>(memberId),
      'is_administrator': serializer.toJson<int>(isAdministrator),
      'order_index': serializer.toJson<int>(orderIndex),
    };
  }

  SqliteGroupMemberRow copyWith({
    String? groupId,
    String? memberId,
    int? isAdministrator,
    int? orderIndex,
  }) => SqliteGroupMemberRow(
    groupId: groupId ?? this.groupId,
    memberId: memberId ?? this.memberId,
    isAdministrator: isAdministrator ?? this.isAdministrator,
    orderIndex: orderIndex ?? this.orderIndex,
  );
  SqliteGroupMemberRow copyWithCompanion(GroupMembersCompanion data) {
    return SqliteGroupMemberRow(
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      isAdministrator: data.isAdministrator.present
          ? data.isAdministrator.value
          : this.isAdministrator,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SqliteGroupMemberRow(')
          ..write('groupId: $groupId, ')
          ..write('memberId: $memberId, ')
          ..write('isAdministrator: $isAdministrator, ')
          ..write('orderIndex: $orderIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(groupId, memberId, isAdministrator, orderIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SqliteGroupMemberRow &&
          other.groupId == this.groupId &&
          other.memberId == this.memberId &&
          other.isAdministrator == this.isAdministrator &&
          other.orderIndex == this.orderIndex);
}

class GroupMembersCompanion extends UpdateCompanion<SqliteGroupMemberRow> {
  final Value<String> groupId;
  final Value<String> memberId;
  final Value<int> isAdministrator;
  final Value<int> orderIndex;
  final Value<int> rowid;
  const GroupMembersCompanion({
    this.groupId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.isAdministrator = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupMembersCompanion.insert({
    required String groupId,
    required String memberId,
    required int isAdministrator,
    required int orderIndex,
    this.rowid = const Value.absent(),
  }) : groupId = Value(groupId),
       memberId = Value(memberId),
       isAdministrator = Value(isAdministrator),
       orderIndex = Value(orderIndex);
  static Insertable<SqliteGroupMemberRow> custom({
    Expression<String>? groupId,
    Expression<String>? memberId,
    Expression<int>? isAdministrator,
    Expression<int>? orderIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (memberId != null) 'member_id': memberId,
      if (isAdministrator != null) 'is_administrator': isAdministrator,
      if (orderIndex != null) 'order_index': orderIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupMembersCompanion copyWith({
    Value<String>? groupId,
    Value<String>? memberId,
    Value<int>? isAdministrator,
    Value<int>? orderIndex,
    Value<int>? rowid,
  }) {
    return GroupMembersCompanion(
      groupId: groupId ?? this.groupId,
      memberId: memberId ?? this.memberId,
      isAdministrator: isAdministrator ?? this.isAdministrator,
      orderIndex: orderIndex ?? this.orderIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (isAdministrator.present) {
      map['is_administrator'] = Variable<int>(isAdministrator.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupMembersCompanion(')
          ..write('groupId: $groupId, ')
          ..write('memberId: $memberId, ')
          ..write('isAdministrator: $isAdministrator, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class TripEntries extends Table
    with TableInfo<TripEntries, SqliteTripEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  TripEntries(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES "groups"(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  late final GeneratedColumn<int> startDate = GeneratedColumn<int>(
    'start_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  late final GeneratedColumn<int> endDate = GeneratedColumn<int>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    year,
    name,
    startDate,
    endDate,
    memo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trip_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SqliteTripEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SqliteTripEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SqliteTripEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_date'],
      ),
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_date'],
      ),
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      ),
    );
  }

  @override
  TripEntries createAlias(String alias) {
    return TripEntries(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SqliteTripEntryRow extends DataClass
    implements Insertable<SqliteTripEntryRow> {
  final String id;
  final String groupId;
  final int year;
  final String? name;
  final int? startDate;
  final int? endDate;
  final String? memo;
  const SqliteTripEntryRow({
    required this.id,
    required this.groupId,
    required this.year,
    this.name,
    this.startDate,
    this.endDate,
    this.memo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['year'] = Variable<int>(year);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<int>(startDate);
    }
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<int>(endDate);
    }
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    return map;
  }

  TripEntriesCompanion toCompanion(bool nullToAbsent) {
    return TripEntriesCompanion(
      id: Value(id),
      groupId: Value(groupId),
      year: Value(year),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
    );
  }

  factory SqliteTripEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SqliteTripEntryRow(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['group_id']),
      year: serializer.fromJson<int>(json['year']),
      name: serializer.fromJson<String?>(json['name']),
      startDate: serializer.fromJson<int?>(json['start_date']),
      endDate: serializer.fromJson<int?>(json['end_date']),
      memo: serializer.fromJson<String?>(json['memo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'group_id': serializer.toJson<String>(groupId),
      'year': serializer.toJson<int>(year),
      'name': serializer.toJson<String?>(name),
      'start_date': serializer.toJson<int?>(startDate),
      'end_date': serializer.toJson<int?>(endDate),
      'memo': serializer.toJson<String?>(memo),
    };
  }

  SqliteTripEntryRow copyWith({
    String? id,
    String? groupId,
    int? year,
    Value<String?> name = const Value.absent(),
    Value<int?> startDate = const Value.absent(),
    Value<int?> endDate = const Value.absent(),
    Value<String?> memo = const Value.absent(),
  }) => SqliteTripEntryRow(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    year: year ?? this.year,
    name: name.present ? name.value : this.name,
    startDate: startDate.present ? startDate.value : this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    memo: memo.present ? memo.value : this.memo,
  );
  SqliteTripEntryRow copyWithCompanion(TripEntriesCompanion data) {
    return SqliteTripEntryRow(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      year: data.year.present ? data.year.value : this.year,
      name: data.name.present ? data.name.value : this.name,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      memo: data.memo.present ? data.memo.value : this.memo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SqliteTripEntryRow(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('year: $year, ')
          ..write('name: $name, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('memo: $memo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, groupId, year, name, startDate, endDate, memo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SqliteTripEntryRow &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.year == this.year &&
          other.name == this.name &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.memo == this.memo);
}

class TripEntriesCompanion extends UpdateCompanion<SqliteTripEntryRow> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<int> year;
  final Value<String?> name;
  final Value<int?> startDate;
  final Value<int?> endDate;
  final Value<String?> memo;
  final Value<int> rowid;
  const TripEntriesCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.year = const Value.absent(),
    this.name = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.memo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TripEntriesCompanion.insert({
    required String id,
    required String groupId,
    required int year,
    this.name = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.memo = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       year = Value(year);
  static Insertable<SqliteTripEntryRow> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<int>? year,
    Expression<String>? name,
    Expression<int>? startDate,
    Expression<int>? endDate,
    Expression<String>? memo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (year != null) 'year': year,
      if (name != null) 'name': name,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (memo != null) 'memo': memo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TripEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? groupId,
    Value<int>? year,
    Value<String?>? name,
    Value<int?>? startDate,
    Value<int?>? endDate,
    Value<String?>? memo,
    Value<int>? rowid,
  }) {
    return TripEntriesCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      year: year ?? this.year,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      memo: memo ?? this.memo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<int>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<int>(endDate.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TripEntriesCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('year: $year, ')
          ..write('name: $name, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('memo: $memo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Tasks extends Table with TableInfo<Tasks, SqliteTaskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Tasks(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES trip_entries(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _parentTaskIdMeta = const VerificationMeta(
    'parentTaskId',
  );
  late final GeneratedColumn<String> parentTaskId = GeneratedColumn<String>(
    'parent_task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  late final GeneratedColumn<int> isCompleted = GeneratedColumn<int>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (is_completed IN (0, 1))',
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  late final GeneratedColumn<int> dueDate = GeneratedColumn<int>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _assignedMemberIdMeta = const VerificationMeta(
    'assignedMemberId',
  );
  late final GeneratedColumn<String> assignedMemberId = GeneratedColumn<String>(
    'assigned_member_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES members(id)ON DELETE SET NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tripId,
    orderIndex,
    parentTaskId,
    name,
    isCompleted,
    dueDate,
    memo,
    assignedMemberId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<SqliteTaskRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('parent_task_id')) {
      context.handle(
        _parentTaskIdMeta,
        parentTaskId.isAcceptableOrUnknown(
          data['parent_task_id']!,
          _parentTaskIdMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isCompletedMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    if (data.containsKey('assigned_member_id')) {
      context.handle(
        _assignedMemberIdMeta,
        assignedMemberId.isAcceptableOrUnknown(
          data['assigned_member_id']!,
          _assignedMemberIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {id, tripId},
  ];
  @override
  SqliteTaskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SqliteTaskRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      parentTaskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_task_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_completed'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_date'],
      ),
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      ),
      assignedMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assigned_member_id'],
      ),
    );
  }

  @override
  Tasks createAlias(String alias) {
    return Tasks(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'UNIQUE(id, trip_id)',
    'FOREIGN KEY(parent_task_id, trip_id)REFERENCES tasks(id, trip_id)DEFERRABLE INITIALLY DEFERRED',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class SqliteTaskRow extends DataClass implements Insertable<SqliteTaskRow> {
  final String id;
  final String tripId;
  final int orderIndex;
  final String? parentTaskId;
  final String name;
  final int isCompleted;
  final int? dueDate;
  final String? memo;
  final String? assignedMemberId;
  const SqliteTaskRow({
    required this.id,
    required this.tripId,
    required this.orderIndex,
    this.parentTaskId,
    required this.name,
    required this.isCompleted,
    this.dueDate,
    this.memo,
    this.assignedMemberId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['trip_id'] = Variable<String>(tripId);
    map['order_index'] = Variable<int>(orderIndex);
    if (!nullToAbsent || parentTaskId != null) {
      map['parent_task_id'] = Variable<String>(parentTaskId);
    }
    map['name'] = Variable<String>(name);
    map['is_completed'] = Variable<int>(isCompleted);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<int>(dueDate);
    }
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    if (!nullToAbsent || assignedMemberId != null) {
      map['assigned_member_id'] = Variable<String>(assignedMemberId);
    }
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      tripId: Value(tripId),
      orderIndex: Value(orderIndex),
      parentTaskId: parentTaskId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentTaskId),
      name: Value(name),
      isCompleted: Value(isCompleted),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      assignedMemberId: assignedMemberId == null && nullToAbsent
          ? const Value.absent()
          : Value(assignedMemberId),
    );
  }

  factory SqliteTaskRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SqliteTaskRow(
      id: serializer.fromJson<String>(json['id']),
      tripId: serializer.fromJson<String>(json['trip_id']),
      orderIndex: serializer.fromJson<int>(json['order_index']),
      parentTaskId: serializer.fromJson<String?>(json['parent_task_id']),
      name: serializer.fromJson<String>(json['name']),
      isCompleted: serializer.fromJson<int>(json['is_completed']),
      dueDate: serializer.fromJson<int?>(json['due_date']),
      memo: serializer.fromJson<String?>(json['memo']),
      assignedMemberId: serializer.fromJson<String?>(
        json['assigned_member_id'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'trip_id': serializer.toJson<String>(tripId),
      'order_index': serializer.toJson<int>(orderIndex),
      'parent_task_id': serializer.toJson<String?>(parentTaskId),
      'name': serializer.toJson<String>(name),
      'is_completed': serializer.toJson<int>(isCompleted),
      'due_date': serializer.toJson<int?>(dueDate),
      'memo': serializer.toJson<String?>(memo),
      'assigned_member_id': serializer.toJson<String?>(assignedMemberId),
    };
  }

  SqliteTaskRow copyWith({
    String? id,
    String? tripId,
    int? orderIndex,
    Value<String?> parentTaskId = const Value.absent(),
    String? name,
    int? isCompleted,
    Value<int?> dueDate = const Value.absent(),
    Value<String?> memo = const Value.absent(),
    Value<String?> assignedMemberId = const Value.absent(),
  }) => SqliteTaskRow(
    id: id ?? this.id,
    tripId: tripId ?? this.tripId,
    orderIndex: orderIndex ?? this.orderIndex,
    parentTaskId: parentTaskId.present ? parentTaskId.value : this.parentTaskId,
    name: name ?? this.name,
    isCompleted: isCompleted ?? this.isCompleted,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    memo: memo.present ? memo.value : this.memo,
    assignedMemberId: assignedMemberId.present
        ? assignedMemberId.value
        : this.assignedMemberId,
  );
  SqliteTaskRow copyWithCompanion(TasksCompanion data) {
    return SqliteTaskRow(
      id: data.id.present ? data.id.value : this.id,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      parentTaskId: data.parentTaskId.present
          ? data.parentTaskId.value
          : this.parentTaskId,
      name: data.name.present ? data.name.value : this.name,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      memo: data.memo.present ? data.memo.value : this.memo,
      assignedMemberId: data.assignedMemberId.present
          ? data.assignedMemberId.value
          : this.assignedMemberId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SqliteTaskRow(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('parentTaskId: $parentTaskId, ')
          ..write('name: $name, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('dueDate: $dueDate, ')
          ..write('memo: $memo, ')
          ..write('assignedMemberId: $assignedMemberId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tripId,
    orderIndex,
    parentTaskId,
    name,
    isCompleted,
    dueDate,
    memo,
    assignedMemberId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SqliteTaskRow &&
          other.id == this.id &&
          other.tripId == this.tripId &&
          other.orderIndex == this.orderIndex &&
          other.parentTaskId == this.parentTaskId &&
          other.name == this.name &&
          other.isCompleted == this.isCompleted &&
          other.dueDate == this.dueDate &&
          other.memo == this.memo &&
          other.assignedMemberId == this.assignedMemberId);
}

class TasksCompanion extends UpdateCompanion<SqliteTaskRow> {
  final Value<String> id;
  final Value<String> tripId;
  final Value<int> orderIndex;
  final Value<String?> parentTaskId;
  final Value<String> name;
  final Value<int> isCompleted;
  final Value<int?> dueDate;
  final Value<String?> memo;
  final Value<String?> assignedMemberId;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.tripId = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.parentTaskId = const Value.absent(),
    this.name = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.memo = const Value.absent(),
    this.assignedMemberId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required String tripId,
    required int orderIndex,
    this.parentTaskId = const Value.absent(),
    required String name,
    required int isCompleted,
    this.dueDate = const Value.absent(),
    this.memo = const Value.absent(),
    this.assignedMemberId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tripId = Value(tripId),
       orderIndex = Value(orderIndex),
       name = Value(name),
       isCompleted = Value(isCompleted);
  static Insertable<SqliteTaskRow> custom({
    Expression<String>? id,
    Expression<String>? tripId,
    Expression<int>? orderIndex,
    Expression<String>? parentTaskId,
    Expression<String>? name,
    Expression<int>? isCompleted,
    Expression<int>? dueDate,
    Expression<String>? memo,
    Expression<String>? assignedMemberId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tripId != null) 'trip_id': tripId,
      if (orderIndex != null) 'order_index': orderIndex,
      if (parentTaskId != null) 'parent_task_id': parentTaskId,
      if (name != null) 'name': name,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (dueDate != null) 'due_date': dueDate,
      if (memo != null) 'memo': memo,
      if (assignedMemberId != null) 'assigned_member_id': assignedMemberId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<String>? tripId,
    Value<int>? orderIndex,
    Value<String?>? parentTaskId,
    Value<String>? name,
    Value<int>? isCompleted,
    Value<int?>? dueDate,
    Value<String?>? memo,
    Value<String?>? assignedMemberId,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      orderIndex: orderIndex ?? this.orderIndex,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      name: name ?? this.name,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      memo: memo ?? this.memo,
      assignedMemberId: assignedMemberId ?? this.assignedMemberId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (parentTaskId.present) {
      map['parent_task_id'] = Variable<String>(parentTaskId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<int>(isCompleted.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<int>(dueDate.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (assignedMemberId.present) {
      map['assigned_member_id'] = Variable<String>(assignedMemberId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('parentTaskId: $parentTaskId, ')
          ..write('name: $name, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('dueDate: $dueDate, ')
          ..write('memo: $memo, ')
          ..write('assignedMemberId: $assignedMemberId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ItineraryItems extends Table
    with TableInfo<ItineraryItems, SqliteItineraryItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ItineraryItems(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES trip_entries(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _startDateTimeMeta = const VerificationMeta(
    'startDateTime',
  );
  late final GeneratedColumn<int> startDateTime = GeneratedColumn<int>(
    'start_date_time',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _endDateTimeMeta = const VerificationMeta(
    'endDateTime',
  );
  late final GeneratedColumn<int> endDateTime = GeneratedColumn<int>(
    'end_date_time',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tripId,
    name,
    startDateTime,
    endDateTime,
    memo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'itinerary_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SqliteItineraryItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('start_date_time')) {
      context.handle(
        _startDateTimeMeta,
        startDateTime.isAcceptableOrUnknown(
          data['start_date_time']!,
          _startDateTimeMeta,
        ),
      );
    }
    if (data.containsKey('end_date_time')) {
      context.handle(
        _endDateTimeMeta,
        endDateTime.isAcceptableOrUnknown(
          data['end_date_time']!,
          _endDateTimeMeta,
        ),
      );
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SqliteItineraryItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SqliteItineraryItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      startDateTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_date_time'],
      ),
      endDateTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_date_time'],
      ),
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      ),
    );
  }

  @override
  ItineraryItems createAlias(String alias) {
    return ItineraryItems(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SqliteItineraryItemRow extends DataClass
    implements Insertable<SqliteItineraryItemRow> {
  final String id;
  final String tripId;
  final String name;
  final int? startDateTime;
  final int? endDateTime;
  final String? memo;
  const SqliteItineraryItemRow({
    required this.id,
    required this.tripId,
    required this.name,
    this.startDateTime,
    this.endDateTime,
    this.memo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['trip_id'] = Variable<String>(tripId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || startDateTime != null) {
      map['start_date_time'] = Variable<int>(startDateTime);
    }
    if (!nullToAbsent || endDateTime != null) {
      map['end_date_time'] = Variable<int>(endDateTime);
    }
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    return map;
  }

  ItineraryItemsCompanion toCompanion(bool nullToAbsent) {
    return ItineraryItemsCompanion(
      id: Value(id),
      tripId: Value(tripId),
      name: Value(name),
      startDateTime: startDateTime == null && nullToAbsent
          ? const Value.absent()
          : Value(startDateTime),
      endDateTime: endDateTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endDateTime),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
    );
  }

  factory SqliteItineraryItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SqliteItineraryItemRow(
      id: serializer.fromJson<String>(json['id']),
      tripId: serializer.fromJson<String>(json['trip_id']),
      name: serializer.fromJson<String>(json['name']),
      startDateTime: serializer.fromJson<int?>(json['start_date_time']),
      endDateTime: serializer.fromJson<int?>(json['end_date_time']),
      memo: serializer.fromJson<String?>(json['memo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'trip_id': serializer.toJson<String>(tripId),
      'name': serializer.toJson<String>(name),
      'start_date_time': serializer.toJson<int?>(startDateTime),
      'end_date_time': serializer.toJson<int?>(endDateTime),
      'memo': serializer.toJson<String?>(memo),
    };
  }

  SqliteItineraryItemRow copyWith({
    String? id,
    String? tripId,
    String? name,
    Value<int?> startDateTime = const Value.absent(),
    Value<int?> endDateTime = const Value.absent(),
    Value<String?> memo = const Value.absent(),
  }) => SqliteItineraryItemRow(
    id: id ?? this.id,
    tripId: tripId ?? this.tripId,
    name: name ?? this.name,
    startDateTime: startDateTime.present
        ? startDateTime.value
        : this.startDateTime,
    endDateTime: endDateTime.present ? endDateTime.value : this.endDateTime,
    memo: memo.present ? memo.value : this.memo,
  );
  SqliteItineraryItemRow copyWithCompanion(ItineraryItemsCompanion data) {
    return SqliteItineraryItemRow(
      id: data.id.present ? data.id.value : this.id,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      name: data.name.present ? data.name.value : this.name,
      startDateTime: data.startDateTime.present
          ? data.startDateTime.value
          : this.startDateTime,
      endDateTime: data.endDateTime.present
          ? data.endDateTime.value
          : this.endDateTime,
      memo: data.memo.present ? data.memo.value : this.memo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SqliteItineraryItemRow(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('name: $name, ')
          ..write('startDateTime: $startDateTime, ')
          ..write('endDateTime: $endDateTime, ')
          ..write('memo: $memo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, tripId, name, startDateTime, endDateTime, memo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SqliteItineraryItemRow &&
          other.id == this.id &&
          other.tripId == this.tripId &&
          other.name == this.name &&
          other.startDateTime == this.startDateTime &&
          other.endDateTime == this.endDateTime &&
          other.memo == this.memo);
}

class ItineraryItemsCompanion extends UpdateCompanion<SqliteItineraryItemRow> {
  final Value<String> id;
  final Value<String> tripId;
  final Value<String> name;
  final Value<int?> startDateTime;
  final Value<int?> endDateTime;
  final Value<String?> memo;
  final Value<int> rowid;
  const ItineraryItemsCompanion({
    this.id = const Value.absent(),
    this.tripId = const Value.absent(),
    this.name = const Value.absent(),
    this.startDateTime = const Value.absent(),
    this.endDateTime = const Value.absent(),
    this.memo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItineraryItemsCompanion.insert({
    required String id,
    required String tripId,
    required String name,
    this.startDateTime = const Value.absent(),
    this.endDateTime = const Value.absent(),
    this.memo = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tripId = Value(tripId),
       name = Value(name);
  static Insertable<SqliteItineraryItemRow> custom({
    Expression<String>? id,
    Expression<String>? tripId,
    Expression<String>? name,
    Expression<int>? startDateTime,
    Expression<int>? endDateTime,
    Expression<String>? memo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tripId != null) 'trip_id': tripId,
      if (name != null) 'name': name,
      if (startDateTime != null) 'start_date_time': startDateTime,
      if (endDateTime != null) 'end_date_time': endDateTime,
      if (memo != null) 'memo': memo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItineraryItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? tripId,
    Value<String>? name,
    Value<int?>? startDateTime,
    Value<int?>? endDateTime,
    Value<String?>? memo,
    Value<int>? rowid,
  }) {
    return ItineraryItemsCompanion(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      name: name ?? this.name,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      memo: memo ?? this.memo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (startDateTime.present) {
      map['start_date_time'] = Variable<int>(startDateTime.value);
    }
    if (endDateTime.present) {
      map['end_date_time'] = Variable<int>(endDateTime.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItineraryItemsCompanion(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('name: $name, ')
          ..write('startDateTime: $startDateTime, ')
          ..write('endDateTime: $endDateTime, ')
          ..write('memo: $memo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class MemberEvents extends Table
    with TableInfo<MemberEvents, SqliteMemberEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  MemberEvents(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES members(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [id, memberId, year, memo];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'member_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<SqliteMemberEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    } else if (isInserting) {
      context.missing(_memoMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {memberId, year},
  ];
  @override
  SqliteMemberEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SqliteMemberEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      )!,
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      )!,
    );
  }

  @override
  MemberEvents createAlias(String alias) {
    return MemberEvents(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['UNIQUE(member_id, year)'];
  @override
  bool get dontWriteConstraints => true;
}

class SqliteMemberEventRow extends DataClass
    implements Insertable<SqliteMemberEventRow> {
  final String id;
  final String memberId;
  final int year;
  final String memo;
  const SqliteMemberEventRow({
    required this.id,
    required this.memberId,
    required this.year,
    required this.memo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['member_id'] = Variable<String>(memberId);
    map['year'] = Variable<int>(year);
    map['memo'] = Variable<String>(memo);
    return map;
  }

  MemberEventsCompanion toCompanion(bool nullToAbsent) {
    return MemberEventsCompanion(
      id: Value(id),
      memberId: Value(memberId),
      year: Value(year),
      memo: Value(memo),
    );
  }

  factory SqliteMemberEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SqliteMemberEventRow(
      id: serializer.fromJson<String>(json['id']),
      memberId: serializer.fromJson<String>(json['member_id']),
      year: serializer.fromJson<int>(json['year']),
      memo: serializer.fromJson<String>(json['memo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'member_id': serializer.toJson<String>(memberId),
      'year': serializer.toJson<int>(year),
      'memo': serializer.toJson<String>(memo),
    };
  }

  SqliteMemberEventRow copyWith({
    String? id,
    String? memberId,
    int? year,
    String? memo,
  }) => SqliteMemberEventRow(
    id: id ?? this.id,
    memberId: memberId ?? this.memberId,
    year: year ?? this.year,
    memo: memo ?? this.memo,
  );
  SqliteMemberEventRow copyWithCompanion(MemberEventsCompanion data) {
    return SqliteMemberEventRow(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      year: data.year.present ? data.year.value : this.year,
      memo: data.memo.present ? data.memo.value : this.memo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SqliteMemberEventRow(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('year: $year, ')
          ..write('memo: $memo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, memberId, year, memo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SqliteMemberEventRow &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.year == this.year &&
          other.memo == this.memo);
}

class MemberEventsCompanion extends UpdateCompanion<SqliteMemberEventRow> {
  final Value<String> id;
  final Value<String> memberId;
  final Value<int> year;
  final Value<String> memo;
  final Value<int> rowid;
  const MemberEventsCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.year = const Value.absent(),
    this.memo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemberEventsCompanion.insert({
    required String id,
    required String memberId,
    required int year,
    required String memo,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       memberId = Value(memberId),
       year = Value(year),
       memo = Value(memo);
  static Insertable<SqliteMemberEventRow> custom({
    Expression<String>? id,
    Expression<String>? memberId,
    Expression<int>? year,
    Expression<String>? memo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (year != null) 'year': year,
      if (memo != null) 'memo': memo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemberEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? memberId,
    Value<int>? year,
    Value<String>? memo,
    Value<int>? rowid,
  }) {
    return MemberEventsCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      year: year ?? this.year,
      memo: memo ?? this.memo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemberEventsCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('year: $year, ')
          ..write('memo: $memo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class GroupEvents extends Table
    with TableInfo<GroupEvents, SqliteGroupEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  GroupEvents(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES "groups"(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [id, groupId, year, memo];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'group_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<SqliteGroupEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    } else if (isInserting) {
      context.missing(_memoMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SqliteGroupEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SqliteGroupEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      )!,
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      )!,
    );
  }

  @override
  GroupEvents createAlias(String alias) {
    return GroupEvents(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SqliteGroupEventRow extends DataClass
    implements Insertable<SqliteGroupEventRow> {
  final String id;
  final String groupId;
  final int year;
  final String memo;
  const SqliteGroupEventRow({
    required this.id,
    required this.groupId,
    required this.year,
    required this.memo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['year'] = Variable<int>(year);
    map['memo'] = Variable<String>(memo);
    return map;
  }

  GroupEventsCompanion toCompanion(bool nullToAbsent) {
    return GroupEventsCompanion(
      id: Value(id),
      groupId: Value(groupId),
      year: Value(year),
      memo: Value(memo),
    );
  }

  factory SqliteGroupEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SqliteGroupEventRow(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['group_id']),
      year: serializer.fromJson<int>(json['year']),
      memo: serializer.fromJson<String>(json['memo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'group_id': serializer.toJson<String>(groupId),
      'year': serializer.toJson<int>(year),
      'memo': serializer.toJson<String>(memo),
    };
  }

  SqliteGroupEventRow copyWith({
    String? id,
    String? groupId,
    int? year,
    String? memo,
  }) => SqliteGroupEventRow(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    year: year ?? this.year,
    memo: memo ?? this.memo,
  );
  SqliteGroupEventRow copyWithCompanion(GroupEventsCompanion data) {
    return SqliteGroupEventRow(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      year: data.year.present ? data.year.value : this.year,
      memo: data.memo.present ? data.memo.value : this.memo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SqliteGroupEventRow(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('year: $year, ')
          ..write('memo: $memo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, groupId, year, memo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SqliteGroupEventRow &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.year == this.year &&
          other.memo == this.memo);
}

class GroupEventsCompanion extends UpdateCompanion<SqliteGroupEventRow> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<int> year;
  final Value<String> memo;
  final Value<int> rowid;
  const GroupEventsCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.year = const Value.absent(),
    this.memo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupEventsCompanion.insert({
    required String id,
    required String groupId,
    required int year,
    required String memo,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       year = Value(year),
       memo = Value(memo);
  static Insertable<SqliteGroupEventRow> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<int>? year,
    Expression<String>? memo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (year != null) 'year': year,
      if (memo != null) 'memo': memo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? groupId,
    Value<int>? year,
    Value<String>? memo,
    Value<int>? rowid,
  }) {
    return GroupEventsCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      year: year ?? this.year,
      memo: memo ?? this.memo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupEventsCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('year: $year, ')
          ..write('memo: $memo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class DvcPointContracts extends Table
    with TableInfo<DvcPointContracts, SqliteDvcPointContractRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  DvcPointContracts(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES "groups"(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _contractNameMeta = const VerificationMeta(
    'contractName',
  );
  late final GeneratedColumn<String> contractName = GeneratedColumn<String>(
    'contract_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _contractStartYearMonthMeta =
      const VerificationMeta('contractStartYearMonth');
  late final GeneratedColumn<int> contractStartYearMonth = GeneratedColumn<int>(
    'contract_start_year_month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _contractEndYearMonthMeta =
      const VerificationMeta('contractEndYearMonth');
  late final GeneratedColumn<int> contractEndYearMonth = GeneratedColumn<int>(
    'contract_end_year_month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _useYearStartMonthMeta = const VerificationMeta(
    'useYearStartMonth',
  );
  late final GeneratedColumn<int> useYearStartMonth = GeneratedColumn<int>(
    'use_year_start_month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _annualPointMeta = const VerificationMeta(
    'annualPoint',
  );
  late final GeneratedColumn<int> annualPoint = GeneratedColumn<int>(
    'annual_point',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    contractName,
    contractStartYearMonth,
    contractEndYearMonth,
    useYearStartMonth,
    annualPoint,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dvc_point_contracts';
  @override
  VerificationContext validateIntegrity(
    Insertable<SqliteDvcPointContractRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('contract_name')) {
      context.handle(
        _contractNameMeta,
        contractName.isAcceptableOrUnknown(
          data['contract_name']!,
          _contractNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contractNameMeta);
    }
    if (data.containsKey('contract_start_year_month')) {
      context.handle(
        _contractStartYearMonthMeta,
        contractStartYearMonth.isAcceptableOrUnknown(
          data['contract_start_year_month']!,
          _contractStartYearMonthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contractStartYearMonthMeta);
    }
    if (data.containsKey('contract_end_year_month')) {
      context.handle(
        _contractEndYearMonthMeta,
        contractEndYearMonth.isAcceptableOrUnknown(
          data['contract_end_year_month']!,
          _contractEndYearMonthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contractEndYearMonthMeta);
    }
    if (data.containsKey('use_year_start_month')) {
      context.handle(
        _useYearStartMonthMeta,
        useYearStartMonth.isAcceptableOrUnknown(
          data['use_year_start_month']!,
          _useYearStartMonthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_useYearStartMonthMeta);
    }
    if (data.containsKey('annual_point')) {
      context.handle(
        _annualPointMeta,
        annualPoint.isAcceptableOrUnknown(
          data['annual_point']!,
          _annualPointMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_annualPointMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SqliteDvcPointContractRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SqliteDvcPointContractRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      contractName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contract_name'],
      )!,
      contractStartYearMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}contract_start_year_month'],
      )!,
      contractEndYearMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}contract_end_year_month'],
      )!,
      useYearStartMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}use_year_start_month'],
      )!,
      annualPoint: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}annual_point'],
      )!,
    );
  }

  @override
  DvcPointContracts createAlias(String alias) {
    return DvcPointContracts(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SqliteDvcPointContractRow extends DataClass
    implements Insertable<SqliteDvcPointContractRow> {
  final String id;
  final String groupId;
  final String contractName;
  final int contractStartYearMonth;
  final int contractEndYearMonth;
  final int useYearStartMonth;
  final int annualPoint;
  const SqliteDvcPointContractRow({
    required this.id,
    required this.groupId,
    required this.contractName,
    required this.contractStartYearMonth,
    required this.contractEndYearMonth,
    required this.useYearStartMonth,
    required this.annualPoint,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['contract_name'] = Variable<String>(contractName);
    map['contract_start_year_month'] = Variable<int>(contractStartYearMonth);
    map['contract_end_year_month'] = Variable<int>(contractEndYearMonth);
    map['use_year_start_month'] = Variable<int>(useYearStartMonth);
    map['annual_point'] = Variable<int>(annualPoint);
    return map;
  }

  DvcPointContractsCompanion toCompanion(bool nullToAbsent) {
    return DvcPointContractsCompanion(
      id: Value(id),
      groupId: Value(groupId),
      contractName: Value(contractName),
      contractStartYearMonth: Value(contractStartYearMonth),
      contractEndYearMonth: Value(contractEndYearMonth),
      useYearStartMonth: Value(useYearStartMonth),
      annualPoint: Value(annualPoint),
    );
  }

  factory SqliteDvcPointContractRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SqliteDvcPointContractRow(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['group_id']),
      contractName: serializer.fromJson<String>(json['contract_name']),
      contractStartYearMonth: serializer.fromJson<int>(
        json['contract_start_year_month'],
      ),
      contractEndYearMonth: serializer.fromJson<int>(
        json['contract_end_year_month'],
      ),
      useYearStartMonth: serializer.fromJson<int>(json['use_year_start_month']),
      annualPoint: serializer.fromJson<int>(json['annual_point']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'group_id': serializer.toJson<String>(groupId),
      'contract_name': serializer.toJson<String>(contractName),
      'contract_start_year_month': serializer.toJson<int>(
        contractStartYearMonth,
      ),
      'contract_end_year_month': serializer.toJson<int>(contractEndYearMonth),
      'use_year_start_month': serializer.toJson<int>(useYearStartMonth),
      'annual_point': serializer.toJson<int>(annualPoint),
    };
  }

  SqliteDvcPointContractRow copyWith({
    String? id,
    String? groupId,
    String? contractName,
    int? contractStartYearMonth,
    int? contractEndYearMonth,
    int? useYearStartMonth,
    int? annualPoint,
  }) => SqliteDvcPointContractRow(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    contractName: contractName ?? this.contractName,
    contractStartYearMonth:
        contractStartYearMonth ?? this.contractStartYearMonth,
    contractEndYearMonth: contractEndYearMonth ?? this.contractEndYearMonth,
    useYearStartMonth: useYearStartMonth ?? this.useYearStartMonth,
    annualPoint: annualPoint ?? this.annualPoint,
  );
  SqliteDvcPointContractRow copyWithCompanion(DvcPointContractsCompanion data) {
    return SqliteDvcPointContractRow(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      contractName: data.contractName.present
          ? data.contractName.value
          : this.contractName,
      contractStartYearMonth: data.contractStartYearMonth.present
          ? data.contractStartYearMonth.value
          : this.contractStartYearMonth,
      contractEndYearMonth: data.contractEndYearMonth.present
          ? data.contractEndYearMonth.value
          : this.contractEndYearMonth,
      useYearStartMonth: data.useYearStartMonth.present
          ? data.useYearStartMonth.value
          : this.useYearStartMonth,
      annualPoint: data.annualPoint.present
          ? data.annualPoint.value
          : this.annualPoint,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SqliteDvcPointContractRow(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('contractName: $contractName, ')
          ..write('contractStartYearMonth: $contractStartYearMonth, ')
          ..write('contractEndYearMonth: $contractEndYearMonth, ')
          ..write('useYearStartMonth: $useYearStartMonth, ')
          ..write('annualPoint: $annualPoint')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    groupId,
    contractName,
    contractStartYearMonth,
    contractEndYearMonth,
    useYearStartMonth,
    annualPoint,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SqliteDvcPointContractRow &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.contractName == this.contractName &&
          other.contractStartYearMonth == this.contractStartYearMonth &&
          other.contractEndYearMonth == this.contractEndYearMonth &&
          other.useYearStartMonth == this.useYearStartMonth &&
          other.annualPoint == this.annualPoint);
}

class DvcPointContractsCompanion
    extends UpdateCompanion<SqliteDvcPointContractRow> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> contractName;
  final Value<int> contractStartYearMonth;
  final Value<int> contractEndYearMonth;
  final Value<int> useYearStartMonth;
  final Value<int> annualPoint;
  final Value<int> rowid;
  const DvcPointContractsCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.contractName = const Value.absent(),
    this.contractStartYearMonth = const Value.absent(),
    this.contractEndYearMonth = const Value.absent(),
    this.useYearStartMonth = const Value.absent(),
    this.annualPoint = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DvcPointContractsCompanion.insert({
    required String id,
    required String groupId,
    required String contractName,
    required int contractStartYearMonth,
    required int contractEndYearMonth,
    required int useYearStartMonth,
    required int annualPoint,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       contractName = Value(contractName),
       contractStartYearMonth = Value(contractStartYearMonth),
       contractEndYearMonth = Value(contractEndYearMonth),
       useYearStartMonth = Value(useYearStartMonth),
       annualPoint = Value(annualPoint);
  static Insertable<SqliteDvcPointContractRow> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? contractName,
    Expression<int>? contractStartYearMonth,
    Expression<int>? contractEndYearMonth,
    Expression<int>? useYearStartMonth,
    Expression<int>? annualPoint,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (contractName != null) 'contract_name': contractName,
      if (contractStartYearMonth != null)
        'contract_start_year_month': contractStartYearMonth,
      if (contractEndYearMonth != null)
        'contract_end_year_month': contractEndYearMonth,
      if (useYearStartMonth != null) 'use_year_start_month': useYearStartMonth,
      if (annualPoint != null) 'annual_point': annualPoint,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DvcPointContractsCompanion copyWith({
    Value<String>? id,
    Value<String>? groupId,
    Value<String>? contractName,
    Value<int>? contractStartYearMonth,
    Value<int>? contractEndYearMonth,
    Value<int>? useYearStartMonth,
    Value<int>? annualPoint,
    Value<int>? rowid,
  }) {
    return DvcPointContractsCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      contractName: contractName ?? this.contractName,
      contractStartYearMonth:
          contractStartYearMonth ?? this.contractStartYearMonth,
      contractEndYearMonth: contractEndYearMonth ?? this.contractEndYearMonth,
      useYearStartMonth: useYearStartMonth ?? this.useYearStartMonth,
      annualPoint: annualPoint ?? this.annualPoint,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (contractName.present) {
      map['contract_name'] = Variable<String>(contractName.value);
    }
    if (contractStartYearMonth.present) {
      map['contract_start_year_month'] = Variable<int>(
        contractStartYearMonth.value,
      );
    }
    if (contractEndYearMonth.present) {
      map['contract_end_year_month'] = Variable<int>(
        contractEndYearMonth.value,
      );
    }
    if (useYearStartMonth.present) {
      map['use_year_start_month'] = Variable<int>(useYearStartMonth.value);
    }
    if (annualPoint.present) {
      map['annual_point'] = Variable<int>(annualPoint.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DvcPointContractsCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('contractName: $contractName, ')
          ..write('contractStartYearMonth: $contractStartYearMonth, ')
          ..write('contractEndYearMonth: $contractEndYearMonth, ')
          ..write('useYearStartMonth: $useYearStartMonth, ')
          ..write('annualPoint: $annualPoint, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class DvcLimitedPoints extends Table
    with TableInfo<DvcLimitedPoints, SqliteDvcLimitedPointRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  DvcLimitedPoints(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES "groups"(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _startYearMonthMeta = const VerificationMeta(
    'startYearMonth',
  );
  late final GeneratedColumn<int> startYearMonth = GeneratedColumn<int>(
    'start_year_month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _endYearMonthMeta = const VerificationMeta(
    'endYearMonth',
  );
  late final GeneratedColumn<int> endYearMonth = GeneratedColumn<int>(
    'end_year_month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _pointMeta = const VerificationMeta('point');
  late final GeneratedColumn<int> point = GeneratedColumn<int>(
    'point',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    startYearMonth,
    endYearMonth,
    point,
    memo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dvc_limited_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<SqliteDvcLimitedPointRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('start_year_month')) {
      context.handle(
        _startYearMonthMeta,
        startYearMonth.isAcceptableOrUnknown(
          data['start_year_month']!,
          _startYearMonthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startYearMonthMeta);
    }
    if (data.containsKey('end_year_month')) {
      context.handle(
        _endYearMonthMeta,
        endYearMonth.isAcceptableOrUnknown(
          data['end_year_month']!,
          _endYearMonthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_endYearMonthMeta);
    }
    if (data.containsKey('point')) {
      context.handle(
        _pointMeta,
        point.isAcceptableOrUnknown(data['point']!, _pointMeta),
      );
    } else if (isInserting) {
      context.missing(_pointMeta);
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SqliteDvcLimitedPointRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SqliteDvcLimitedPointRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      startYearMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_year_month'],
      )!,
      endYearMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_year_month'],
      )!,
      point: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}point'],
      )!,
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      ),
    );
  }

  @override
  DvcLimitedPoints createAlias(String alias) {
    return DvcLimitedPoints(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SqliteDvcLimitedPointRow extends DataClass
    implements Insertable<SqliteDvcLimitedPointRow> {
  final String id;
  final String groupId;
  final int startYearMonth;
  final int endYearMonth;
  final int point;
  final String? memo;
  const SqliteDvcLimitedPointRow({
    required this.id,
    required this.groupId,
    required this.startYearMonth,
    required this.endYearMonth,
    required this.point,
    this.memo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['start_year_month'] = Variable<int>(startYearMonth);
    map['end_year_month'] = Variable<int>(endYearMonth);
    map['point'] = Variable<int>(point);
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    return map;
  }

  DvcLimitedPointsCompanion toCompanion(bool nullToAbsent) {
    return DvcLimitedPointsCompanion(
      id: Value(id),
      groupId: Value(groupId),
      startYearMonth: Value(startYearMonth),
      endYearMonth: Value(endYearMonth),
      point: Value(point),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
    );
  }

  factory SqliteDvcLimitedPointRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SqliteDvcLimitedPointRow(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['group_id']),
      startYearMonth: serializer.fromJson<int>(json['start_year_month']),
      endYearMonth: serializer.fromJson<int>(json['end_year_month']),
      point: serializer.fromJson<int>(json['point']),
      memo: serializer.fromJson<String?>(json['memo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'group_id': serializer.toJson<String>(groupId),
      'start_year_month': serializer.toJson<int>(startYearMonth),
      'end_year_month': serializer.toJson<int>(endYearMonth),
      'point': serializer.toJson<int>(point),
      'memo': serializer.toJson<String?>(memo),
    };
  }

  SqliteDvcLimitedPointRow copyWith({
    String? id,
    String? groupId,
    int? startYearMonth,
    int? endYearMonth,
    int? point,
    Value<String?> memo = const Value.absent(),
  }) => SqliteDvcLimitedPointRow(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    startYearMonth: startYearMonth ?? this.startYearMonth,
    endYearMonth: endYearMonth ?? this.endYearMonth,
    point: point ?? this.point,
    memo: memo.present ? memo.value : this.memo,
  );
  SqliteDvcLimitedPointRow copyWithCompanion(DvcLimitedPointsCompanion data) {
    return SqliteDvcLimitedPointRow(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      startYearMonth: data.startYearMonth.present
          ? data.startYearMonth.value
          : this.startYearMonth,
      endYearMonth: data.endYearMonth.present
          ? data.endYearMonth.value
          : this.endYearMonth,
      point: data.point.present ? data.point.value : this.point,
      memo: data.memo.present ? data.memo.value : this.memo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SqliteDvcLimitedPointRow(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('startYearMonth: $startYearMonth, ')
          ..write('endYearMonth: $endYearMonth, ')
          ..write('point: $point, ')
          ..write('memo: $memo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, groupId, startYearMonth, endYearMonth, point, memo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SqliteDvcLimitedPointRow &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.startYearMonth == this.startYearMonth &&
          other.endYearMonth == this.endYearMonth &&
          other.point == this.point &&
          other.memo == this.memo);
}

class DvcLimitedPointsCompanion
    extends UpdateCompanion<SqliteDvcLimitedPointRow> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<int> startYearMonth;
  final Value<int> endYearMonth;
  final Value<int> point;
  final Value<String?> memo;
  final Value<int> rowid;
  const DvcLimitedPointsCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.startYearMonth = const Value.absent(),
    this.endYearMonth = const Value.absent(),
    this.point = const Value.absent(),
    this.memo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DvcLimitedPointsCompanion.insert({
    required String id,
    required String groupId,
    required int startYearMonth,
    required int endYearMonth,
    required int point,
    this.memo = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       startYearMonth = Value(startYearMonth),
       endYearMonth = Value(endYearMonth),
       point = Value(point);
  static Insertable<SqliteDvcLimitedPointRow> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<int>? startYearMonth,
    Expression<int>? endYearMonth,
    Expression<int>? point,
    Expression<String>? memo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (startYearMonth != null) 'start_year_month': startYearMonth,
      if (endYearMonth != null) 'end_year_month': endYearMonth,
      if (point != null) 'point': point,
      if (memo != null) 'memo': memo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DvcLimitedPointsCompanion copyWith({
    Value<String>? id,
    Value<String>? groupId,
    Value<int>? startYearMonth,
    Value<int>? endYearMonth,
    Value<int>? point,
    Value<String?>? memo,
    Value<int>? rowid,
  }) {
    return DvcLimitedPointsCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      startYearMonth: startYearMonth ?? this.startYearMonth,
      endYearMonth: endYearMonth ?? this.endYearMonth,
      point: point ?? this.point,
      memo: memo ?? this.memo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (startYearMonth.present) {
      map['start_year_month'] = Variable<int>(startYearMonth.value);
    }
    if (endYearMonth.present) {
      map['end_year_month'] = Variable<int>(endYearMonth.value);
    }
    if (point.present) {
      map['point'] = Variable<int>(point.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DvcLimitedPointsCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('startYearMonth: $startYearMonth, ')
          ..write('endYearMonth: $endYearMonth, ')
          ..write('point: $point, ')
          ..write('memo: $memo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class DvcPointUsages extends Table
    with TableInfo<DvcPointUsages, SqliteDvcPointUsageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  DvcPointUsages(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES "groups"(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _usageYearMonthMeta = const VerificationMeta(
    'usageYearMonth',
  );
  late final GeneratedColumn<int> usageYearMonth = GeneratedColumn<int>(
    'usage_year_month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _usedPointMeta = const VerificationMeta(
    'usedPoint',
  );
  late final GeneratedColumn<int> usedPoint = GeneratedColumn<int>(
    'used_point',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    usageYearMonth,
    usedPoint,
    memo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dvc_point_usages';
  @override
  VerificationContext validateIntegrity(
    Insertable<SqliteDvcPointUsageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('usage_year_month')) {
      context.handle(
        _usageYearMonthMeta,
        usageYearMonth.isAcceptableOrUnknown(
          data['usage_year_month']!,
          _usageYearMonthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_usageYearMonthMeta);
    }
    if (data.containsKey('used_point')) {
      context.handle(
        _usedPointMeta,
        usedPoint.isAcceptableOrUnknown(data['used_point']!, _usedPointMeta),
      );
    } else if (isInserting) {
      context.missing(_usedPointMeta);
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SqliteDvcPointUsageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SqliteDvcPointUsageRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      usageYearMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}usage_year_month'],
      )!,
      usedPoint: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}used_point'],
      )!,
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      ),
    );
  }

  @override
  DvcPointUsages createAlias(String alias) {
    return DvcPointUsages(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SqliteDvcPointUsageRow extends DataClass
    implements Insertable<SqliteDvcPointUsageRow> {
  final String id;
  final String groupId;
  final int usageYearMonth;
  final int usedPoint;
  final String? memo;
  const SqliteDvcPointUsageRow({
    required this.id,
    required this.groupId,
    required this.usageYearMonth,
    required this.usedPoint,
    this.memo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['usage_year_month'] = Variable<int>(usageYearMonth);
    map['used_point'] = Variable<int>(usedPoint);
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    return map;
  }

  DvcPointUsagesCompanion toCompanion(bool nullToAbsent) {
    return DvcPointUsagesCompanion(
      id: Value(id),
      groupId: Value(groupId),
      usageYearMonth: Value(usageYearMonth),
      usedPoint: Value(usedPoint),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
    );
  }

  factory SqliteDvcPointUsageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SqliteDvcPointUsageRow(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['group_id']),
      usageYearMonth: serializer.fromJson<int>(json['usage_year_month']),
      usedPoint: serializer.fromJson<int>(json['used_point']),
      memo: serializer.fromJson<String?>(json['memo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'group_id': serializer.toJson<String>(groupId),
      'usage_year_month': serializer.toJson<int>(usageYearMonth),
      'used_point': serializer.toJson<int>(usedPoint),
      'memo': serializer.toJson<String?>(memo),
    };
  }

  SqliteDvcPointUsageRow copyWith({
    String? id,
    String? groupId,
    int? usageYearMonth,
    int? usedPoint,
    Value<String?> memo = const Value.absent(),
  }) => SqliteDvcPointUsageRow(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    usageYearMonth: usageYearMonth ?? this.usageYearMonth,
    usedPoint: usedPoint ?? this.usedPoint,
    memo: memo.present ? memo.value : this.memo,
  );
  SqliteDvcPointUsageRow copyWithCompanion(DvcPointUsagesCompanion data) {
    return SqliteDvcPointUsageRow(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      usageYearMonth: data.usageYearMonth.present
          ? data.usageYearMonth.value
          : this.usageYearMonth,
      usedPoint: data.usedPoint.present ? data.usedPoint.value : this.usedPoint,
      memo: data.memo.present ? data.memo.value : this.memo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SqliteDvcPointUsageRow(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('usageYearMonth: $usageYearMonth, ')
          ..write('usedPoint: $usedPoint, ')
          ..write('memo: $memo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, groupId, usageYearMonth, usedPoint, memo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SqliteDvcPointUsageRow &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.usageYearMonth == this.usageYearMonth &&
          other.usedPoint == this.usedPoint &&
          other.memo == this.memo);
}

class DvcPointUsagesCompanion extends UpdateCompanion<SqliteDvcPointUsageRow> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<int> usageYearMonth;
  final Value<int> usedPoint;
  final Value<String?> memo;
  final Value<int> rowid;
  const DvcPointUsagesCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.usageYearMonth = const Value.absent(),
    this.usedPoint = const Value.absent(),
    this.memo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DvcPointUsagesCompanion.insert({
    required String id,
    required String groupId,
    required int usageYearMonth,
    required int usedPoint,
    this.memo = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       usageYearMonth = Value(usageYearMonth),
       usedPoint = Value(usedPoint);
  static Insertable<SqliteDvcPointUsageRow> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<int>? usageYearMonth,
    Expression<int>? usedPoint,
    Expression<String>? memo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (usageYearMonth != null) 'usage_year_month': usageYearMonth,
      if (usedPoint != null) 'used_point': usedPoint,
      if (memo != null) 'memo': memo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DvcPointUsagesCompanion copyWith({
    Value<String>? id,
    Value<String>? groupId,
    Value<int>? usageYearMonth,
    Value<int>? usedPoint,
    Value<String?>? memo,
    Value<int>? rowid,
  }) {
    return DvcPointUsagesCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      usageYearMonth: usageYearMonth ?? this.usageYearMonth,
      usedPoint: usedPoint ?? this.usedPoint,
      memo: memo ?? this.memo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (usageYearMonth.present) {
      map['usage_year_month'] = Variable<int>(usageYearMonth.value);
    }
    if (usedPoint.present) {
      map['used_point'] = Variable<int>(usedPoint.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DvcPointUsagesCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('usageYearMonth: $usageYearMonth, ')
          ..write('usedPoint: $usedPoint, ')
          ..write('memo: $memo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$OfflineDatabase extends GeneratedDatabase {
  _$OfflineDatabase(QueryExecutor e) : super(e);
  late final Members members = Members(this);
  late final Index membersOwnerIdIdx = Index(
    'members_owner_id_idx',
    'CREATE INDEX members_owner_id_idx ON members (owner_id)',
  );
  late final Groups groups = Groups(this);
  late final Index groupsOwnerIdIdx = Index(
    'groups_owner_id_idx',
    'CREATE INDEX groups_owner_id_idx ON "groups" (owner_id)',
  );
  late final GroupMembers groupMembers = GroupMembers(this);
  late final Index groupMembersGroupIdIdx = Index(
    'group_members_group_id_idx',
    'CREATE INDEX group_members_group_id_idx ON group_members (group_id, order_index)',
  );
  late final Index groupMembersMemberIdIdx = Index(
    'group_members_member_id_idx',
    'CREATE INDEX group_members_member_id_idx ON group_members (member_id, order_index)',
  );
  late final TripEntries tripEntries = TripEntries(this);
  late final Index tripEntriesGroupIdIdx = Index(
    'trip_entries_group_id_idx',
    'CREATE INDEX trip_entries_group_id_idx ON trip_entries (group_id, year)',
  );
  late final Tasks tasks = Tasks(this);
  late final Index tasksTripIdIdx = Index(
    'tasks_trip_id_idx',
    'CREATE INDEX tasks_trip_id_idx ON tasks (trip_id, order_index)',
  );
  late final Index tasksAssignedMemberIdIdx = Index(
    'tasks_assigned_member_id_idx',
    'CREATE INDEX tasks_assigned_member_id_idx ON tasks (assigned_member_id, order_index)',
  );
  late final Index tasksParentTaskIdIdx = Index(
    'tasks_parent_task_id_idx',
    'CREATE INDEX tasks_parent_task_id_idx ON tasks (parent_task_id, order_index)',
  );
  late final ItineraryItems itineraryItems = ItineraryItems(this);
  late final Index itineraryItemsTripIdIdx = Index(
    'itinerary_items_trip_id_idx',
    'CREATE INDEX itinerary_items_trip_id_idx ON itinerary_items (trip_id, start_date_time)',
  );
  late final MemberEvents memberEvents = MemberEvents(this);
  late final GroupEvents groupEvents = GroupEvents(this);
  late final DvcPointContracts dvcPointContracts = DvcPointContracts(this);
  late final DvcLimitedPoints dvcLimitedPoints = DvcLimitedPoints(this);
  late final DvcPointUsages dvcPointUsages = DvcPointUsages(this);
  late final Index groupEventsGroupYearIdx = Index(
    'group_events_group_year_idx',
    'CREATE INDEX group_events_group_year_idx ON group_events (group_id, year)',
  );
  late final Index dvcPointContractsGroupStartIdx = Index(
    'dvc_point_contracts_group_start_idx',
    'CREATE INDEX dvc_point_contracts_group_start_idx ON dvc_point_contracts (group_id, contract_start_year_month)',
  );
  late final Index dvcLimitedPointsGroupStartIdx = Index(
    'dvc_limited_points_group_start_idx',
    'CREATE INDEX dvc_limited_points_group_start_idx ON dvc_limited_points (group_id, start_year_month)',
  );
  late final Index dvcPointUsagesGroupMonthIdx = Index(
    'dvc_point_usages_group_month_idx',
    'CREATE INDEX dvc_point_usages_group_month_idx ON dvc_point_usages (group_id, usage_year_month)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    members,
    membersOwnerIdIdx,
    groups,
    groupsOwnerIdIdx,
    groupMembers,
    groupMembersGroupIdIdx,
    groupMembersMemberIdIdx,
    tripEntries,
    tripEntriesGroupIdIdx,
    tasks,
    tasksTripIdIdx,
    tasksAssignedMemberIdIdx,
    tasksParentTaskIdIdx,
    itineraryItems,
    itineraryItemsTripIdIdx,
    memberEvents,
    groupEvents,
    dvcPointContracts,
    dvcLimitedPoints,
    dvcPointUsages,
    groupEventsGroupYearIdx,
    dvcPointContractsGroupStartIdx,
    dvcLimitedPointsGroupStartIdx,
    dvcPointUsagesGroupMonthIdx,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'groups',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('group_members', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'members',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('group_members', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'groups',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('trip_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'trip_entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tasks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'members',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tasks', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'trip_entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('itinerary_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'members',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('member_events', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'groups',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('group_events', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'groups',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('dvc_point_contracts', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'groups',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('dvc_limited_points', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'groups',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('dvc_point_usages', kind: UpdateKind.delete)],
    ),
  ]);
}
