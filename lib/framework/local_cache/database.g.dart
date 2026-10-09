// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CachedUsersTable extends CachedUsers
    with TableInfo<$CachedUsersTable, CachedUser> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedUsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userNameMeta = const VerificationMeta(
    'userName',
  );
  @override
  late final GeneratedColumn<String> userName = GeneratedColumn<String>(
    'user_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _nickNameMeta = const VerificationMeta(
    'nickName',
  );
  @override
  late final GeneratedColumn<String> nickName = GeneratedColumn<String>(
    'nick_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _phoneNumberMeta = const VerificationMeta(
    'phoneNumber',
  );
  @override
  late final GeneratedColumn<String> phoneNumber = GeneratedColumn<String>(
    'phone_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sexMeta = const VerificationMeta('sex');
  @override
  late final GeneratedColumn<String> sex = GeneratedColumn<String>(
    'sex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('2'),
  );
  static const VerificationMeta _avatarMeta = const VerificationMeta('avatar');
  @override
  late final GeneratedColumn<String> avatar = GeneratedColumn<String>(
    'avatar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    userName,
    nickName,
    email,
    phoneNumber,
    sex,
    avatar,
    createdAt,
    updatedAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_users';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedUser> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('user_name')) {
      context.handle(
        _userNameMeta,
        userName.isAcceptableOrUnknown(data['user_name']!, _userNameMeta),
      );
    }
    if (data.containsKey('nick_name')) {
      context.handle(
        _nickNameMeta,
        nickName.isAcceptableOrUnknown(data['nick_name']!, _nickNameMeta),
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
    if (data.containsKey('sex')) {
      context.handle(
        _sexMeta,
        sex.isAcceptableOrUnknown(data['sex']!, _sexMeta),
      );
    }
    if (data.containsKey('avatar')) {
      context.handle(
        _avatarMeta,
        avatar.isAcceptableOrUnknown(data['avatar']!, _avatarMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  CachedUser map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedUser(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      userName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_name'],
      )!,
      nickName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nick_name'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      phoneNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone_number'],
      )!,
      sex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sex'],
      )!,
      avatar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedUsersTable createAlias(String alias) {
    return $CachedUsersTable(attachedDatabase, alias);
  }
}

class CachedUser extends DataClass implements Insertable<CachedUser> {
  final int userId;
  final String userName;
  final String nickName;
  final String email;
  final String phoneNumber;
  final String sex;
  final String avatar;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime cachedAt;
  const CachedUser({
    required this.userId,
    required this.userName,
    required this.nickName,
    required this.email,
    required this.phoneNumber,
    required this.sex,
    required this.avatar,
    this.createdAt,
    this.updatedAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<int>(userId);
    map['user_name'] = Variable<String>(userName);
    map['nick_name'] = Variable<String>(nickName);
    map['email'] = Variable<String>(email);
    map['phone_number'] = Variable<String>(phoneNumber);
    map['sex'] = Variable<String>(sex);
    map['avatar'] = Variable<String>(avatar);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedUsersCompanion toCompanion(bool nullToAbsent) {
    return CachedUsersCompanion(
      userId: Value(userId),
      userName: Value(userName),
      nickName: Value(nickName),
      email: Value(email),
      phoneNumber: Value(phoneNumber),
      sex: Value(sex),
      avatar: Value(avatar),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedUser.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedUser(
      userId: serializer.fromJson<int>(json['userId']),
      userName: serializer.fromJson<String>(json['userName']),
      nickName: serializer.fromJson<String>(json['nickName']),
      email: serializer.fromJson<String>(json['email']),
      phoneNumber: serializer.fromJson<String>(json['phoneNumber']),
      sex: serializer.fromJson<String>(json['sex']),
      avatar: serializer.fromJson<String>(json['avatar']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<int>(userId),
      'userName': serializer.toJson<String>(userName),
      'nickName': serializer.toJson<String>(nickName),
      'email': serializer.toJson<String>(email),
      'phoneNumber': serializer.toJson<String>(phoneNumber),
      'sex': serializer.toJson<String>(sex),
      'avatar': serializer.toJson<String>(avatar),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedUser copyWith({
    int? userId,
    String? userName,
    String? nickName,
    String? email,
    String? phoneNumber,
    String? sex,
    String? avatar,
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
    DateTime? cachedAt,
  }) => CachedUser(
    userId: userId ?? this.userId,
    userName: userName ?? this.userName,
    nickName: nickName ?? this.nickName,
    email: email ?? this.email,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    sex: sex ?? this.sex,
    avatar: avatar ?? this.avatar,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedUser copyWithCompanion(CachedUsersCompanion data) {
    return CachedUser(
      userId: data.userId.present ? data.userId.value : this.userId,
      userName: data.userName.present ? data.userName.value : this.userName,
      nickName: data.nickName.present ? data.nickName.value : this.nickName,
      email: data.email.present ? data.email.value : this.email,
      phoneNumber: data.phoneNumber.present
          ? data.phoneNumber.value
          : this.phoneNumber,
      sex: data.sex.present ? data.sex.value : this.sex,
      avatar: data.avatar.present ? data.avatar.value : this.avatar,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedUser(')
          ..write('userId: $userId, ')
          ..write('userName: $userName, ')
          ..write('nickName: $nickName, ')
          ..write('email: $email, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('sex: $sex, ')
          ..write('avatar: $avatar, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    userName,
    nickName,
    email,
    phoneNumber,
    sex,
    avatar,
    createdAt,
    updatedAt,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedUser &&
          other.userId == this.userId &&
          other.userName == this.userName &&
          other.nickName == this.nickName &&
          other.email == this.email &&
          other.phoneNumber == this.phoneNumber &&
          other.sex == this.sex &&
          other.avatar == this.avatar &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.cachedAt == this.cachedAt);
}

class CachedUsersCompanion extends UpdateCompanion<CachedUser> {
  final Value<int> userId;
  final Value<String> userName;
  final Value<String> nickName;
  final Value<String> email;
  final Value<String> phoneNumber;
  final Value<String> sex;
  final Value<String> avatar;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<DateTime> cachedAt;
  const CachedUsersCompanion({
    this.userId = const Value.absent(),
    this.userName = const Value.absent(),
    this.nickName = const Value.absent(),
    this.email = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.sex = const Value.absent(),
    this.avatar = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CachedUsersCompanion.insert({
    this.userId = const Value.absent(),
    this.userName = const Value.absent(),
    this.nickName = const Value.absent(),
    this.email = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.sex = const Value.absent(),
    this.avatar = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required DateTime cachedAt,
  }) : cachedAt = Value(cachedAt);
  static Insertable<CachedUser> custom({
    Expression<int>? userId,
    Expression<String>? userName,
    Expression<String>? nickName,
    Expression<String>? email,
    Expression<String>? phoneNumber,
    Expression<String>? sex,
    Expression<String>? avatar,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (userName != null) 'user_name': userName,
      if (nickName != null) 'nick_name': nickName,
      if (email != null) 'email': email,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (sex != null) 'sex': sex,
      if (avatar != null) 'avatar': avatar,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CachedUsersCompanion copyWith({
    Value<int>? userId,
    Value<String>? userName,
    Value<String>? nickName,
    Value<String>? email,
    Value<String>? phoneNumber,
    Value<String>? sex,
    Value<String>? avatar,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<DateTime>? cachedAt,
  }) {
    return CachedUsersCompanion(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      nickName: nickName ?? this.nickName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      sex: sex ?? this.sex,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (userName.present) {
      map['user_name'] = Variable<String>(userName.value);
    }
    if (nickName.present) {
      map['nick_name'] = Variable<String>(nickName.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (phoneNumber.present) {
      map['phone_number'] = Variable<String>(phoneNumber.value);
    }
    if (sex.present) {
      map['sex'] = Variable<String>(sex.value);
    }
    if (avatar.present) {
      map['avatar'] = Variable<String>(avatar.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedUsersCompanion(')
          ..write('userId: $userId, ')
          ..write('userName: $userName, ')
          ..write('nickName: $nickName, ')
          ..write('email: $email, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('sex: $sex, ')
          ..write('avatar: $avatar, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $ConversationsTable extends Conversations
    with TableInfo<$ConversationsTable, CachedConversation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarMeta = const VerificationMeta('avatar');
  @override
  late final GeneratedColumn<String> avatar = GeneratedColumn<String>(
    'avatar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<int> type = GeneratedColumn<int>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _peerIdMeta = const VerificationMeta('peerId');
  @override
  late final GeneratedColumn<int> peerId = GeneratedColumn<int>(
    'peer_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cached_users (user_id)',
    ),
  );
  static const VerificationMeta _unreadCountMeta = const VerificationMeta(
    'unreadCount',
  );
  @override
  late final GeneratedColumn<int> unreadCount = GeneratedColumn<int>(
    'unread_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastReadSeqMeta = const VerificationMeta(
    'lastReadSeq',
  );
  @override
  late final GeneratedColumn<int> lastReadSeq = GeneratedColumn<int>(
    'last_read_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastMessageIdMeta = const VerificationMeta(
    'lastMessageId',
  );
  @override
  late final GeneratedColumn<String> lastMessageId = GeneratedColumn<String>(
    'last_message_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMessagePreviewMeta =
      const VerificationMeta('lastMessagePreview');
  @override
  late final GeneratedColumn<String> lastMessagePreview =
      GeneratedColumn<String>(
        'last_message_preview',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastMessageTypeMeta = const VerificationMeta(
    'lastMessageType',
  );
  @override
  late final GeneratedColumn<int> lastMessageType = GeneratedColumn<int>(
    'last_message_type',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMessageSeqMeta = const VerificationMeta(
    'lastMessageSeq',
  );
  @override
  late final GeneratedColumn<int> lastMessageSeq = GeneratedColumn<int>(
    'last_message_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMessageAtMeta = const VerificationMeta(
    'lastMessageAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastMessageAt =
      GeneratedColumn<DateTime>(
        'last_message_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    avatar,
    description,
    type,
    status,
    peerId,
    unreadCount,
    lastReadSeq,
    lastMessageId,
    lastMessagePreview,
    lastMessageType,
    lastMessageSeq,
    lastMessageAt,
    createdAt,
    updatedAt,
    cachedAt,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversations';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedConversation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('avatar')) {
      context.handle(
        _avatarMeta,
        avatar.isAcceptableOrUnknown(data['avatar']!, _avatarMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('peer_id')) {
      context.handle(
        _peerIdMeta,
        peerId.isAcceptableOrUnknown(data['peer_id']!, _peerIdMeta),
      );
    }
    if (data.containsKey('unread_count')) {
      context.handle(
        _unreadCountMeta,
        unreadCount.isAcceptableOrUnknown(
          data['unread_count']!,
          _unreadCountMeta,
        ),
      );
    }
    if (data.containsKey('last_read_seq')) {
      context.handle(
        _lastReadSeqMeta,
        lastReadSeq.isAcceptableOrUnknown(
          data['last_read_seq']!,
          _lastReadSeqMeta,
        ),
      );
    }
    if (data.containsKey('last_message_id')) {
      context.handle(
        _lastMessageIdMeta,
        lastMessageId.isAcceptableOrUnknown(
          data['last_message_id']!,
          _lastMessageIdMeta,
        ),
      );
    }
    if (data.containsKey('last_message_preview')) {
      context.handle(
        _lastMessagePreviewMeta,
        lastMessagePreview.isAcceptableOrUnknown(
          data['last_message_preview']!,
          _lastMessagePreviewMeta,
        ),
      );
    }
    if (data.containsKey('last_message_type')) {
      context.handle(
        _lastMessageTypeMeta,
        lastMessageType.isAcceptableOrUnknown(
          data['last_message_type']!,
          _lastMessageTypeMeta,
        ),
      );
    }
    if (data.containsKey('last_message_seq')) {
      context.handle(
        _lastMessageSeqMeta,
        lastMessageSeq.isAcceptableOrUnknown(
          data['last_message_seq']!,
          _lastMessageSeqMeta,
        ),
      );
    }
    if (data.containsKey('last_message_at')) {
      context.handle(
        _lastMessageAtMeta,
        lastMessageAt.isAcceptableOrUnknown(
          data['last_message_at']!,
          _lastMessageAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedConversation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedConversation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      avatar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}type'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      peerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}peer_id'],
      ),
      unreadCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unread_count'],
      )!,
      lastReadSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_read_seq'],
      )!,
      lastMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_id'],
      ),
      lastMessagePreview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_preview'],
      ),
      lastMessageType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_message_type'],
      ),
      lastMessageSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_message_seq'],
      ),
      lastMessageAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_message_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $ConversationsTable createAlias(String alias) {
    return $ConversationsTable(attachedDatabase, alias);
  }
}

class CachedConversation extends DataClass
    implements Insertable<CachedConversation> {
  final String id;
  final String? name;
  final String? avatar;
  final String? description;
  final int type;
  final int status;
  final int? peerId;
  final int unreadCount;
  final int lastReadSeq;
  final String? lastMessageId;
  final String? lastMessagePreview;
  final int? lastMessageType;
  final int? lastMessageSeq;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final DateTime updatedAt;
  final DateTime cachedAt;
  final bool isDeleted;
  const CachedConversation({
    required this.id,
    this.name,
    this.avatar,
    this.description,
    required this.type,
    required this.status,
    this.peerId,
    required this.unreadCount,
    required this.lastReadSeq,
    this.lastMessageId,
    this.lastMessagePreview,
    this.lastMessageType,
    this.lastMessageSeq,
    this.lastMessageAt,
    this.createdAt,
    required this.updatedAt,
    required this.cachedAt,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || avatar != null) {
      map['avatar'] = Variable<String>(avatar);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['type'] = Variable<int>(type);
    map['status'] = Variable<int>(status);
    if (!nullToAbsent || peerId != null) {
      map['peer_id'] = Variable<int>(peerId);
    }
    map['unread_count'] = Variable<int>(unreadCount);
    map['last_read_seq'] = Variable<int>(lastReadSeq);
    if (!nullToAbsent || lastMessageId != null) {
      map['last_message_id'] = Variable<String>(lastMessageId);
    }
    if (!nullToAbsent || lastMessagePreview != null) {
      map['last_message_preview'] = Variable<String>(lastMessagePreview);
    }
    if (!nullToAbsent || lastMessageType != null) {
      map['last_message_type'] = Variable<int>(lastMessageType);
    }
    if (!nullToAbsent || lastMessageSeq != null) {
      map['last_message_seq'] = Variable<int>(lastMessageSeq);
    }
    if (!nullToAbsent || lastMessageAt != null) {
      map['last_message_at'] = Variable<DateTime>(lastMessageAt);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  ConversationsCompanion toCompanion(bool nullToAbsent) {
    return ConversationsCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      avatar: avatar == null && nullToAbsent
          ? const Value.absent()
          : Value(avatar),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      type: Value(type),
      status: Value(status),
      peerId: peerId == null && nullToAbsent
          ? const Value.absent()
          : Value(peerId),
      unreadCount: Value(unreadCount),
      lastReadSeq: Value(lastReadSeq),
      lastMessageId: lastMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageId),
      lastMessagePreview: lastMessagePreview == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessagePreview),
      lastMessageType: lastMessageType == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageType),
      lastMessageSeq: lastMessageSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageSeq),
      lastMessageAt: lastMessageAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageAt),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: Value(updatedAt),
      cachedAt: Value(cachedAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory CachedConversation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedConversation(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      avatar: serializer.fromJson<String?>(json['avatar']),
      description: serializer.fromJson<String?>(json['description']),
      type: serializer.fromJson<int>(json['type']),
      status: serializer.fromJson<int>(json['status']),
      peerId: serializer.fromJson<int?>(json['peerId']),
      unreadCount: serializer.fromJson<int>(json['unreadCount']),
      lastReadSeq: serializer.fromJson<int>(json['lastReadSeq']),
      lastMessageId: serializer.fromJson<String?>(json['lastMessageId']),
      lastMessagePreview: serializer.fromJson<String?>(
        json['lastMessagePreview'],
      ),
      lastMessageType: serializer.fromJson<int?>(json['lastMessageType']),
      lastMessageSeq: serializer.fromJson<int?>(json['lastMessageSeq']),
      lastMessageAt: serializer.fromJson<DateTime?>(json['lastMessageAt']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String?>(name),
      'avatar': serializer.toJson<String?>(avatar),
      'description': serializer.toJson<String?>(description),
      'type': serializer.toJson<int>(type),
      'status': serializer.toJson<int>(status),
      'peerId': serializer.toJson<int?>(peerId),
      'unreadCount': serializer.toJson<int>(unreadCount),
      'lastReadSeq': serializer.toJson<int>(lastReadSeq),
      'lastMessageId': serializer.toJson<String?>(lastMessageId),
      'lastMessagePreview': serializer.toJson<String?>(lastMessagePreview),
      'lastMessageType': serializer.toJson<int?>(lastMessageType),
      'lastMessageSeq': serializer.toJson<int?>(lastMessageSeq),
      'lastMessageAt': serializer.toJson<DateTime?>(lastMessageAt),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  CachedConversation copyWith({
    String? id,
    Value<String?> name = const Value.absent(),
    Value<String?> avatar = const Value.absent(),
    Value<String?> description = const Value.absent(),
    int? type,
    int? status,
    Value<int?> peerId = const Value.absent(),
    int? unreadCount,
    int? lastReadSeq,
    Value<String?> lastMessageId = const Value.absent(),
    Value<String?> lastMessagePreview = const Value.absent(),
    Value<int?> lastMessageType = const Value.absent(),
    Value<int?> lastMessageSeq = const Value.absent(),
    Value<DateTime?> lastMessageAt = const Value.absent(),
    Value<DateTime?> createdAt = const Value.absent(),
    DateTime? updatedAt,
    DateTime? cachedAt,
    bool? isDeleted,
  }) => CachedConversation(
    id: id ?? this.id,
    name: name.present ? name.value : this.name,
    avatar: avatar.present ? avatar.value : this.avatar,
    description: description.present ? description.value : this.description,
    type: type ?? this.type,
    status: status ?? this.status,
    peerId: peerId.present ? peerId.value : this.peerId,
    unreadCount: unreadCount ?? this.unreadCount,
    lastReadSeq: lastReadSeq ?? this.lastReadSeq,
    lastMessageId: lastMessageId.present
        ? lastMessageId.value
        : this.lastMessageId,
    lastMessagePreview: lastMessagePreview.present
        ? lastMessagePreview.value
        : this.lastMessagePreview,
    lastMessageType: lastMessageType.present
        ? lastMessageType.value
        : this.lastMessageType,
    lastMessageSeq: lastMessageSeq.present
        ? lastMessageSeq.value
        : this.lastMessageSeq,
    lastMessageAt: lastMessageAt.present
        ? lastMessageAt.value
        : this.lastMessageAt,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    cachedAt: cachedAt ?? this.cachedAt,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  CachedConversation copyWithCompanion(ConversationsCompanion data) {
    return CachedConversation(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      avatar: data.avatar.present ? data.avatar.value : this.avatar,
      description: data.description.present
          ? data.description.value
          : this.description,
      type: data.type.present ? data.type.value : this.type,
      status: data.status.present ? data.status.value : this.status,
      peerId: data.peerId.present ? data.peerId.value : this.peerId,
      unreadCount: data.unreadCount.present
          ? data.unreadCount.value
          : this.unreadCount,
      lastReadSeq: data.lastReadSeq.present
          ? data.lastReadSeq.value
          : this.lastReadSeq,
      lastMessageId: data.lastMessageId.present
          ? data.lastMessageId.value
          : this.lastMessageId,
      lastMessagePreview: data.lastMessagePreview.present
          ? data.lastMessagePreview.value
          : this.lastMessagePreview,
      lastMessageType: data.lastMessageType.present
          ? data.lastMessageType.value
          : this.lastMessageType,
      lastMessageSeq: data.lastMessageSeq.present
          ? data.lastMessageSeq.value
          : this.lastMessageSeq,
      lastMessageAt: data.lastMessageAt.present
          ? data.lastMessageAt.value
          : this.lastMessageAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedConversation(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('avatar: $avatar, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('peerId: $peerId, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('lastReadSeq: $lastReadSeq, ')
          ..write('lastMessageId: $lastMessageId, ')
          ..write('lastMessagePreview: $lastMessagePreview, ')
          ..write('lastMessageType: $lastMessageType, ')
          ..write('lastMessageSeq: $lastMessageSeq, ')
          ..write('lastMessageAt: $lastMessageAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    avatar,
    description,
    type,
    status,
    peerId,
    unreadCount,
    lastReadSeq,
    lastMessageId,
    lastMessagePreview,
    lastMessageType,
    lastMessageSeq,
    lastMessageAt,
    createdAt,
    updatedAt,
    cachedAt,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedConversation &&
          other.id == this.id &&
          other.name == this.name &&
          other.avatar == this.avatar &&
          other.description == this.description &&
          other.type == this.type &&
          other.status == this.status &&
          other.peerId == this.peerId &&
          other.unreadCount == this.unreadCount &&
          other.lastReadSeq == this.lastReadSeq &&
          other.lastMessageId == this.lastMessageId &&
          other.lastMessagePreview == this.lastMessagePreview &&
          other.lastMessageType == this.lastMessageType &&
          other.lastMessageSeq == this.lastMessageSeq &&
          other.lastMessageAt == this.lastMessageAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.cachedAt == this.cachedAt &&
          other.isDeleted == this.isDeleted);
}

class ConversationsCompanion extends UpdateCompanion<CachedConversation> {
  final Value<String> id;
  final Value<String?> name;
  final Value<String?> avatar;
  final Value<String?> description;
  final Value<int> type;
  final Value<int> status;
  final Value<int?> peerId;
  final Value<int> unreadCount;
  final Value<int> lastReadSeq;
  final Value<String?> lastMessageId;
  final Value<String?> lastMessagePreview;
  final Value<int?> lastMessageType;
  final Value<int?> lastMessageSeq;
  final Value<DateTime?> lastMessageAt;
  final Value<DateTime?> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime> cachedAt;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const ConversationsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.avatar = const Value.absent(),
    this.description = const Value.absent(),
    this.type = const Value.absent(),
    this.status = const Value.absent(),
    this.peerId = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.lastReadSeq = const Value.absent(),
    this.lastMessageId = const Value.absent(),
    this.lastMessagePreview = const Value.absent(),
    this.lastMessageType = const Value.absent(),
    this.lastMessageSeq = const Value.absent(),
    this.lastMessageAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConversationsCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    this.avatar = const Value.absent(),
    this.description = const Value.absent(),
    this.type = const Value.absent(),
    this.status = const Value.absent(),
    this.peerId = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.lastReadSeq = const Value.absent(),
    this.lastMessageId = const Value.absent(),
    this.lastMessagePreview = const Value.absent(),
    this.lastMessageType = const Value.absent(),
    this.lastMessageSeq = const Value.absent(),
    this.lastMessageAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    required DateTime updatedAt,
    required DateTime cachedAt,
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       cachedAt = Value(cachedAt);
  static Insertable<CachedConversation> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? avatar,
    Expression<String>? description,
    Expression<int>? type,
    Expression<int>? status,
    Expression<int>? peerId,
    Expression<int>? unreadCount,
    Expression<int>? lastReadSeq,
    Expression<String>? lastMessageId,
    Expression<String>? lastMessagePreview,
    Expression<int>? lastMessageType,
    Expression<int>? lastMessageSeq,
    Expression<DateTime>? lastMessageAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? cachedAt,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (avatar != null) 'avatar': avatar,
      if (description != null) 'description': description,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (peerId != null) 'peer_id': peerId,
      if (unreadCount != null) 'unread_count': unreadCount,
      if (lastReadSeq != null) 'last_read_seq': lastReadSeq,
      if (lastMessageId != null) 'last_message_id': lastMessageId,
      if (lastMessagePreview != null)
        'last_message_preview': lastMessagePreview,
      if (lastMessageType != null) 'last_message_type': lastMessageType,
      if (lastMessageSeq != null) 'last_message_seq': lastMessageSeq,
      if (lastMessageAt != null) 'last_message_at': lastMessageAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConversationsCompanion copyWith({
    Value<String>? id,
    Value<String?>? name,
    Value<String?>? avatar,
    Value<String?>? description,
    Value<int>? type,
    Value<int>? status,
    Value<int?>? peerId,
    Value<int>? unreadCount,
    Value<int>? lastReadSeq,
    Value<String?>? lastMessageId,
    Value<String?>? lastMessagePreview,
    Value<int?>? lastMessageType,
    Value<int?>? lastMessageSeq,
    Value<DateTime?>? lastMessageAt,
    Value<DateTime?>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime>? cachedAt,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return ConversationsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      peerId: peerId ?? this.peerId,
      unreadCount: unreadCount ?? this.unreadCount,
      lastReadSeq: lastReadSeq ?? this.lastReadSeq,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageSeq: lastMessageSeq ?? this.lastMessageSeq,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (avatar.present) {
      map['avatar'] = Variable<String>(avatar.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (peerId.present) {
      map['peer_id'] = Variable<int>(peerId.value);
    }
    if (unreadCount.present) {
      map['unread_count'] = Variable<int>(unreadCount.value);
    }
    if (lastReadSeq.present) {
      map['last_read_seq'] = Variable<int>(lastReadSeq.value);
    }
    if (lastMessageId.present) {
      map['last_message_id'] = Variable<String>(lastMessageId.value);
    }
    if (lastMessagePreview.present) {
      map['last_message_preview'] = Variable<String>(lastMessagePreview.value);
    }
    if (lastMessageType.present) {
      map['last_message_type'] = Variable<int>(lastMessageType.value);
    }
    if (lastMessageSeq.present) {
      map['last_message_seq'] = Variable<int>(lastMessageSeq.value);
    }
    if (lastMessageAt.present) {
      map['last_message_at'] = Variable<DateTime>(lastMessageAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('avatar: $avatar, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('peerId: $peerId, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('lastReadSeq: $lastReadSeq, ')
          ..write('lastMessageId: $lastMessageId, ')
          ..write('lastMessagePreview: $lastMessagePreview, ')
          ..write('lastMessageType: $lastMessageType, ')
          ..write('lastMessageSeq: $lastMessageSeq, ')
          ..write('lastMessageAt: $lastMessageAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages
    with TableInfo<$MessagesTable, CachedMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientMsgIdMeta = const VerificationMeta(
    'clientMsgId',
  );
  @override
  late final GeneratedColumn<String> clientMsgId = GeneratedColumn<String>(
    'client_msg_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES conversations (id)',
    ),
  );
  static const VerificationMeta _senderIdMeta = const VerificationMeta(
    'senderId',
  );
  @override
  late final GeneratedColumn<int> senderId = GeneratedColumn<int>(
    'sender_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cached_users (user_id)',
    ),
  );
  static const VerificationMeta _messageTypeMeta = const VerificationMeta(
    'messageType',
  );
  @override
  late final GeneratedColumn<int> messageType = GeneratedColumn<int>(
    'message_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _propertiesJsonMeta = const VerificationMeta(
    'propertiesJson',
  );
  @override
  late final GeneratedColumn<String> propertiesJson = GeneratedColumn<String>(
    'properties_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deliveryStatusMeta = const VerificationMeta(
    'deliveryStatus',
  );
  @override
  late final GeneratedColumn<String> deliveryStatus = GeneratedColumn<String>(
    'delivery_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('SENT'),
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<DateTime> sentAt = GeneratedColumn<DateTime>(
    'sent_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localCreatedAtMeta = const VerificationMeta(
    'localCreatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localCreatedAt =
      GeneratedColumn<DateTime>(
        'local_created_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientMsgId,
    conversationId,
    senderId,
    messageType,
    content,
    payloadJson,
    propertiesJson,
    deliveryStatus,
    seq,
    sentAt,
    localCreatedAt,
    updatedAt,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedMessage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('client_msg_id')) {
      context.handle(
        _clientMsgIdMeta,
        clientMsgId.isAcceptableOrUnknown(
          data['client_msg_id']!,
          _clientMsgIdMeta,
        ),
      );
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('sender_id')) {
      context.handle(
        _senderIdMeta,
        senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta),
      );
    }
    if (data.containsKey('message_type')) {
      context.handle(
        _messageTypeMeta,
        messageType.isAcceptableOrUnknown(
          data['message_type']!,
          _messageTypeMeta,
        ),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    }
    if (data.containsKey('properties_json')) {
      context.handle(
        _propertiesJsonMeta,
        propertiesJson.isAcceptableOrUnknown(
          data['properties_json']!,
          _propertiesJsonMeta,
        ),
      );
    }
    if (data.containsKey('delivery_status')) {
      context.handle(
        _deliveryStatusMeta,
        deliveryStatus.isAcceptableOrUnknown(
          data['delivery_status']!,
          _deliveryStatusMeta,
        ),
      );
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    }
    if (data.containsKey('local_created_at')) {
      context.handle(
        _localCreatedAtMeta,
        localCreatedAt.isAcceptableOrUnknown(
          data['local_created_at']!,
          _localCreatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localCreatedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedMessage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clientMsgId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_msg_id'],
      ),
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      senderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sender_id'],
      ),
      messageType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}message_type'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      ),
      propertiesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}properties_json'],
      ),
      deliveryStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delivery_status'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sent_at'],
      ),
      localCreatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class CachedMessage extends DataClass implements Insertable<CachedMessage> {
  final String id;
  final String? clientMsgId;
  final String conversationId;
  final int? senderId;
  final int messageType;
  final String content;
  final String? payloadJson;
  final String? propertiesJson;
  final String deliveryStatus;
  final int seq;
  final DateTime? sentAt;
  final DateTime localCreatedAt;
  final DateTime updatedAt;
  final bool isDeleted;
  const CachedMessage({
    required this.id,
    this.clientMsgId,
    required this.conversationId,
    this.senderId,
    required this.messageType,
    required this.content,
    this.payloadJson,
    this.propertiesJson,
    required this.deliveryStatus,
    required this.seq,
    this.sentAt,
    required this.localCreatedAt,
    required this.updatedAt,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || clientMsgId != null) {
      map['client_msg_id'] = Variable<String>(clientMsgId);
    }
    map['conversation_id'] = Variable<String>(conversationId);
    if (!nullToAbsent || senderId != null) {
      map['sender_id'] = Variable<int>(senderId);
    }
    map['message_type'] = Variable<int>(messageType);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || payloadJson != null) {
      map['payload_json'] = Variable<String>(payloadJson);
    }
    if (!nullToAbsent || propertiesJson != null) {
      map['properties_json'] = Variable<String>(propertiesJson);
    }
    map['delivery_status'] = Variable<String>(deliveryStatus);
    map['seq'] = Variable<int>(seq);
    if (!nullToAbsent || sentAt != null) {
      map['sent_at'] = Variable<DateTime>(sentAt);
    }
    map['local_created_at'] = Variable<DateTime>(localCreatedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      clientMsgId: clientMsgId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientMsgId),
      conversationId: Value(conversationId),
      senderId: senderId == null && nullToAbsent
          ? const Value.absent()
          : Value(senderId),
      messageType: Value(messageType),
      content: Value(content),
      payloadJson: payloadJson == null && nullToAbsent
          ? const Value.absent()
          : Value(payloadJson),
      propertiesJson: propertiesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(propertiesJson),
      deliveryStatus: Value(deliveryStatus),
      seq: Value(seq),
      sentAt: sentAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sentAt),
      localCreatedAt: Value(localCreatedAt),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory CachedMessage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedMessage(
      id: serializer.fromJson<String>(json['id']),
      clientMsgId: serializer.fromJson<String?>(json['clientMsgId']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      senderId: serializer.fromJson<int?>(json['senderId']),
      messageType: serializer.fromJson<int>(json['messageType']),
      content: serializer.fromJson<String>(json['content']),
      payloadJson: serializer.fromJson<String?>(json['payloadJson']),
      propertiesJson: serializer.fromJson<String?>(json['propertiesJson']),
      deliveryStatus: serializer.fromJson<String>(json['deliveryStatus']),
      seq: serializer.fromJson<int>(json['seq']),
      sentAt: serializer.fromJson<DateTime?>(json['sentAt']),
      localCreatedAt: serializer.fromJson<DateTime>(json['localCreatedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clientMsgId': serializer.toJson<String?>(clientMsgId),
      'conversationId': serializer.toJson<String>(conversationId),
      'senderId': serializer.toJson<int?>(senderId),
      'messageType': serializer.toJson<int>(messageType),
      'content': serializer.toJson<String>(content),
      'payloadJson': serializer.toJson<String?>(payloadJson),
      'propertiesJson': serializer.toJson<String?>(propertiesJson),
      'deliveryStatus': serializer.toJson<String>(deliveryStatus),
      'seq': serializer.toJson<int>(seq),
      'sentAt': serializer.toJson<DateTime?>(sentAt),
      'localCreatedAt': serializer.toJson<DateTime>(localCreatedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  CachedMessage copyWith({
    String? id,
    Value<String?> clientMsgId = const Value.absent(),
    String? conversationId,
    Value<int?> senderId = const Value.absent(),
    int? messageType,
    String? content,
    Value<String?> payloadJson = const Value.absent(),
    Value<String?> propertiesJson = const Value.absent(),
    String? deliveryStatus,
    int? seq,
    Value<DateTime?> sentAt = const Value.absent(),
    DateTime? localCreatedAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) => CachedMessage(
    id: id ?? this.id,
    clientMsgId: clientMsgId.present ? clientMsgId.value : this.clientMsgId,
    conversationId: conversationId ?? this.conversationId,
    senderId: senderId.present ? senderId.value : this.senderId,
    messageType: messageType ?? this.messageType,
    content: content ?? this.content,
    payloadJson: payloadJson.present ? payloadJson.value : this.payloadJson,
    propertiesJson: propertiesJson.present
        ? propertiesJson.value
        : this.propertiesJson,
    deliveryStatus: deliveryStatus ?? this.deliveryStatus,
    seq: seq ?? this.seq,
    sentAt: sentAt.present ? sentAt.value : this.sentAt,
    localCreatedAt: localCreatedAt ?? this.localCreatedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  CachedMessage copyWithCompanion(MessagesCompanion data) {
    return CachedMessage(
      id: data.id.present ? data.id.value : this.id,
      clientMsgId: data.clientMsgId.present
          ? data.clientMsgId.value
          : this.clientMsgId,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      senderId: data.senderId.present ? data.senderId.value : this.senderId,
      messageType: data.messageType.present
          ? data.messageType.value
          : this.messageType,
      content: data.content.present ? data.content.value : this.content,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      propertiesJson: data.propertiesJson.present
          ? data.propertiesJson.value
          : this.propertiesJson,
      deliveryStatus: data.deliveryStatus.present
          ? data.deliveryStatus.value
          : this.deliveryStatus,
      seq: data.seq.present ? data.seq.value : this.seq,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      localCreatedAt: data.localCreatedAt.present
          ? data.localCreatedAt.value
          : this.localCreatedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedMessage(')
          ..write('id: $id, ')
          ..write('clientMsgId: $clientMsgId, ')
          ..write('conversationId: $conversationId, ')
          ..write('senderId: $senderId, ')
          ..write('messageType: $messageType, ')
          ..write('content: $content, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('propertiesJson: $propertiesJson, ')
          ..write('deliveryStatus: $deliveryStatus, ')
          ..write('seq: $seq, ')
          ..write('sentAt: $sentAt, ')
          ..write('localCreatedAt: $localCreatedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientMsgId,
    conversationId,
    senderId,
    messageType,
    content,
    payloadJson,
    propertiesJson,
    deliveryStatus,
    seq,
    sentAt,
    localCreatedAt,
    updatedAt,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedMessage &&
          other.id == this.id &&
          other.clientMsgId == this.clientMsgId &&
          other.conversationId == this.conversationId &&
          other.senderId == this.senderId &&
          other.messageType == this.messageType &&
          other.content == this.content &&
          other.payloadJson == this.payloadJson &&
          other.propertiesJson == this.propertiesJson &&
          other.deliveryStatus == this.deliveryStatus &&
          other.seq == this.seq &&
          other.sentAt == this.sentAt &&
          other.localCreatedAt == this.localCreatedAt &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted);
}

class MessagesCompanion extends UpdateCompanion<CachedMessage> {
  final Value<String> id;
  final Value<String?> clientMsgId;
  final Value<String> conversationId;
  final Value<int?> senderId;
  final Value<int> messageType;
  final Value<String> content;
  final Value<String?> payloadJson;
  final Value<String?> propertiesJson;
  final Value<String> deliveryStatus;
  final Value<int> seq;
  final Value<DateTime?> sentAt;
  final Value<DateTime> localCreatedAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.clientMsgId = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.messageType = const Value.absent(),
    this.content = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.propertiesJson = const Value.absent(),
    this.deliveryStatus = const Value.absent(),
    this.seq = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.localCreatedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesCompanion.insert({
    required String id,
    this.clientMsgId = const Value.absent(),
    required String conversationId,
    this.senderId = const Value.absent(),
    this.messageType = const Value.absent(),
    this.content = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.propertiesJson = const Value.absent(),
    this.deliveryStatus = const Value.absent(),
    this.seq = const Value.absent(),
    this.sentAt = const Value.absent(),
    required DateTime localCreatedAt,
    required DateTime updatedAt,
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       conversationId = Value(conversationId),
       localCreatedAt = Value(localCreatedAt),
       updatedAt = Value(updatedAt);
  static Insertable<CachedMessage> custom({
    Expression<String>? id,
    Expression<String>? clientMsgId,
    Expression<String>? conversationId,
    Expression<int>? senderId,
    Expression<int>? messageType,
    Expression<String>? content,
    Expression<String>? payloadJson,
    Expression<String>? propertiesJson,
    Expression<String>? deliveryStatus,
    Expression<int>? seq,
    Expression<DateTime>? sentAt,
    Expression<DateTime>? localCreatedAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientMsgId != null) 'client_msg_id': clientMsgId,
      if (conversationId != null) 'conversation_id': conversationId,
      if (senderId != null) 'sender_id': senderId,
      if (messageType != null) 'message_type': messageType,
      if (content != null) 'content': content,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (propertiesJson != null) 'properties_json': propertiesJson,
      if (deliveryStatus != null) 'delivery_status': deliveryStatus,
      if (seq != null) 'seq': seq,
      if (sentAt != null) 'sent_at': sentAt,
      if (localCreatedAt != null) 'local_created_at': localCreatedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesCompanion copyWith({
    Value<String>? id,
    Value<String?>? clientMsgId,
    Value<String>? conversationId,
    Value<int?>? senderId,
    Value<int>? messageType,
    Value<String>? content,
    Value<String?>? payloadJson,
    Value<String?>? propertiesJson,
    Value<String>? deliveryStatus,
    Value<int>? seq,
    Value<DateTime?>? sentAt,
    Value<DateTime>? localCreatedAt,
    Value<DateTime>? updatedAt,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return MessagesCompanion(
      id: id ?? this.id,
      clientMsgId: clientMsgId ?? this.clientMsgId,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      messageType: messageType ?? this.messageType,
      content: content ?? this.content,
      payloadJson: payloadJson ?? this.payloadJson,
      propertiesJson: propertiesJson ?? this.propertiesJson,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      seq: seq ?? this.seq,
      sentAt: sentAt ?? this.sentAt,
      localCreatedAt: localCreatedAt ?? this.localCreatedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clientMsgId.present) {
      map['client_msg_id'] = Variable<String>(clientMsgId.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<int>(senderId.value);
    }
    if (messageType.present) {
      map['message_type'] = Variable<int>(messageType.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (propertiesJson.present) {
      map['properties_json'] = Variable<String>(propertiesJson.value);
    }
    if (deliveryStatus.present) {
      map['delivery_status'] = Variable<String>(deliveryStatus.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<DateTime>(sentAt.value);
    }
    if (localCreatedAt.present) {
      map['local_created_at'] = Variable<DateTime>(localCreatedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('clientMsgId: $clientMsgId, ')
          ..write('conversationId: $conversationId, ')
          ..write('senderId: $senderId, ')
          ..write('messageType: $messageType, ')
          ..write('content: $content, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('propertiesJson: $propertiesJson, ')
          ..write('deliveryStatus: $deliveryStatus, ')
          ..write('seq: $seq, ')
          ..write('sentAt: $sentAt, ')
          ..write('localCreatedAt: $localCreatedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStatesTable extends SyncStates
    with TableInfo<$SyncStatesTable, SyncState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeIdMeta = const VerificationMeta(
    'scopeId',
  );
  @override
  late final GeneratedColumn<String> scopeId = GeneratedColumn<String>(
    'scope_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('global'),
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSeqMeta = const VerificationMeta(
    'lastSeq',
  );
  @override
  late final GeneratedColumn<int> lastSeq = GeneratedColumn<int>(
    'last_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    scope,
    scopeId,
    lastSyncedAt,
    lastSeq,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('scope')) {
      context.handle(
        _scopeMeta,
        scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('scope_id')) {
      context.handle(
        _scopeIdMeta,
        scopeId.isAcceptableOrUnknown(data['scope_id']!, _scopeIdMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_seq')) {
      context.handle(
        _lastSeqMeta,
        lastSeq.isAcceptableOrUnknown(data['last_seq']!, _lastSeqMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scope, scopeId};
  @override
  SyncState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncState(
      scope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope'],
      )!,
      scopeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_id'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      lastSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_seq'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SyncStatesTable createAlias(String alias) {
    return $SyncStatesTable(attachedDatabase, alias);
  }
}

class SyncState extends DataClass implements Insertable<SyncState> {
  final String scope;
  final String scopeId;
  final DateTime? lastSyncedAt;
  final int lastSeq;
  final DateTime updatedAt;
  const SyncState({
    required this.scope,
    required this.scopeId,
    this.lastSyncedAt,
    required this.lastSeq,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['scope'] = Variable<String>(scope);
    map['scope_id'] = Variable<String>(scopeId);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['last_seq'] = Variable<int>(lastSeq);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SyncStatesCompanion toCompanion(bool nullToAbsent) {
    return SyncStatesCompanion(
      scope: Value(scope),
      scopeId: Value(scopeId),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      lastSeq: Value(lastSeq),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncState(
      scope: serializer.fromJson<String>(json['scope']),
      scopeId: serializer.fromJson<String>(json['scopeId']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      lastSeq: serializer.fromJson<int>(json['lastSeq']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'scope': serializer.toJson<String>(scope),
      'scopeId': serializer.toJson<String>(scopeId),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'lastSeq': serializer.toJson<int>(lastSeq),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SyncState copyWith({
    String? scope,
    String? scopeId,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    int? lastSeq,
    DateTime? updatedAt,
  }) => SyncState(
    scope: scope ?? this.scope,
    scopeId: scopeId ?? this.scopeId,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    lastSeq: lastSeq ?? this.lastSeq,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SyncState copyWithCompanion(SyncStatesCompanion data) {
    return SyncState(
      scope: data.scope.present ? data.scope.value : this.scope,
      scopeId: data.scopeId.present ? data.scopeId.value : this.scopeId,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      lastSeq: data.lastSeq.present ? data.lastSeq.value : this.lastSeq,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncState(')
          ..write('scope: $scope, ')
          ..write('scopeId: $scopeId, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('lastSeq: $lastSeq, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(scope, scopeId, lastSyncedAt, lastSeq, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncState &&
          other.scope == this.scope &&
          other.scopeId == this.scopeId &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.lastSeq == this.lastSeq &&
          other.updatedAt == this.updatedAt);
}

class SyncStatesCompanion extends UpdateCompanion<SyncState> {
  final Value<String> scope;
  final Value<String> scopeId;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> lastSeq;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SyncStatesCompanion({
    this.scope = const Value.absent(),
    this.scopeId = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.lastSeq = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStatesCompanion.insert({
    required String scope,
    this.scopeId = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.lastSeq = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : scope = Value(scope),
       updatedAt = Value(updatedAt);
  static Insertable<SyncState> custom({
    Expression<String>? scope,
    Expression<String>? scopeId,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? lastSeq,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (scope != null) 'scope': scope,
      if (scopeId != null) 'scope_id': scopeId,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (lastSeq != null) 'last_seq': lastSeq,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStatesCompanion copyWith({
    Value<String>? scope,
    Value<String>? scopeId,
    Value<DateTime?>? lastSyncedAt,
    Value<int>? lastSeq,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SyncStatesCompanion(
      scope: scope ?? this.scope,
      scopeId: scopeId ?? this.scopeId,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastSeq: lastSeq ?? this.lastSeq,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (scopeId.present) {
      map['scope_id'] = Variable<String>(scopeId.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (lastSeq.present) {
      map['last_seq'] = Variable<int>(lastSeq.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStatesCompanion(')
          ..write('scope: $scope, ')
          ..write('scopeId: $scopeId, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('lastSeq: $lastSeq, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncLogsTable extends SyncLogs
    with TableInfo<$SyncLogsTable, SyncLogEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeIdMeta = const VerificationMeta(
    'scopeId',
  );
  @override
  late final GeneratedColumn<String> scopeId = GeneratedColumn<String>(
    'scope_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nextRetryAtMeta = const VerificationMeta(
    'nextRetryAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextRetryAt = GeneratedColumn<DateTime>(
    'next_retry_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scope,
    scopeId,
    action,
    status,
    message,
    createdAt,
    nextRetryAt,
    retryCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncLogEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('scope')) {
      context.handle(
        _scopeMeta,
        scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('scope_id')) {
      context.handle(
        _scopeIdMeta,
        scopeId.isAcceptableOrUnknown(data['scope_id']!, _scopeIdMeta),
      );
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
        _nextRetryAtMeta,
        nextRetryAt.isAcceptableOrUnknown(
          data['next_retry_at']!,
          _nextRetryAtMeta,
        ),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncLogEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncLogEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      scope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope'],
      )!,
      scopeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_id'],
      ),
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      nextRetryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_retry_at'],
      ),
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
    );
  }

  @override
  $SyncLogsTable createAlias(String alias) {
    return $SyncLogsTable(attachedDatabase, alias);
  }
}

class SyncLogEntry extends DataClass implements Insertable<SyncLogEntry> {
  final int id;
  final String scope;
  final String? scopeId;
  final String action;
  final String status;
  final String? message;
  final DateTime createdAt;
  final DateTime? nextRetryAt;
  final int retryCount;
  const SyncLogEntry({
    required this.id,
    required this.scope,
    this.scopeId,
    required this.action,
    required this.status,
    this.message,
    required this.createdAt,
    this.nextRetryAt,
    required this.retryCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['scope'] = Variable<String>(scope);
    if (!nullToAbsent || scopeId != null) {
      map['scope_id'] = Variable<String>(scopeId);
    }
    map['action'] = Variable<String>(action);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || message != null) {
      map['message'] = Variable<String>(message);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || nextRetryAt != null) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt);
    }
    map['retry_count'] = Variable<int>(retryCount);
    return map;
  }

  SyncLogsCompanion toCompanion(bool nullToAbsent) {
    return SyncLogsCompanion(
      id: Value(id),
      scope: Value(scope),
      scopeId: scopeId == null && nullToAbsent
          ? const Value.absent()
          : Value(scopeId),
      action: Value(action),
      status: Value(status),
      message: message == null && nullToAbsent
          ? const Value.absent()
          : Value(message),
      createdAt: Value(createdAt),
      nextRetryAt: nextRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRetryAt),
      retryCount: Value(retryCount),
    );
  }

  factory SyncLogEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncLogEntry(
      id: serializer.fromJson<int>(json['id']),
      scope: serializer.fromJson<String>(json['scope']),
      scopeId: serializer.fromJson<String?>(json['scopeId']),
      action: serializer.fromJson<String>(json['action']),
      status: serializer.fromJson<String>(json['status']),
      message: serializer.fromJson<String?>(json['message']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      nextRetryAt: serializer.fromJson<DateTime?>(json['nextRetryAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'scope': serializer.toJson<String>(scope),
      'scopeId': serializer.toJson<String?>(scopeId),
      'action': serializer.toJson<String>(action),
      'status': serializer.toJson<String>(status),
      'message': serializer.toJson<String?>(message),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'nextRetryAt': serializer.toJson<DateTime?>(nextRetryAt),
      'retryCount': serializer.toJson<int>(retryCount),
    };
  }

  SyncLogEntry copyWith({
    int? id,
    String? scope,
    Value<String?> scopeId = const Value.absent(),
    String? action,
    String? status,
    Value<String?> message = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> nextRetryAt = const Value.absent(),
    int? retryCount,
  }) => SyncLogEntry(
    id: id ?? this.id,
    scope: scope ?? this.scope,
    scopeId: scopeId.present ? scopeId.value : this.scopeId,
    action: action ?? this.action,
    status: status ?? this.status,
    message: message.present ? message.value : this.message,
    createdAt: createdAt ?? this.createdAt,
    nextRetryAt: nextRetryAt.present ? nextRetryAt.value : this.nextRetryAt,
    retryCount: retryCount ?? this.retryCount,
  );
  SyncLogEntry copyWithCompanion(SyncLogsCompanion data) {
    return SyncLogEntry(
      id: data.id.present ? data.id.value : this.id,
      scope: data.scope.present ? data.scope.value : this.scope,
      scopeId: data.scopeId.present ? data.scopeId.value : this.scopeId,
      action: data.action.present ? data.action.value : this.action,
      status: data.status.present ? data.status.value : this.status,
      message: data.message.present ? data.message.value : this.message,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      nextRetryAt: data.nextRetryAt.present
          ? data.nextRetryAt.value
          : this.nextRetryAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncLogEntry(')
          ..write('id: $id, ')
          ..write('scope: $scope, ')
          ..write('scopeId: $scopeId, ')
          ..write('action: $action, ')
          ..write('status: $status, ')
          ..write('message: $message, ')
          ..write('createdAt: $createdAt, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scope,
    scopeId,
    action,
    status,
    message,
    createdAt,
    nextRetryAt,
    retryCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncLogEntry &&
          other.id == this.id &&
          other.scope == this.scope &&
          other.scopeId == this.scopeId &&
          other.action == this.action &&
          other.status == this.status &&
          other.message == this.message &&
          other.createdAt == this.createdAt &&
          other.nextRetryAt == this.nextRetryAt &&
          other.retryCount == this.retryCount);
}

class SyncLogsCompanion extends UpdateCompanion<SyncLogEntry> {
  final Value<int> id;
  final Value<String> scope;
  final Value<String?> scopeId;
  final Value<String> action;
  final Value<String> status;
  final Value<String?> message;
  final Value<DateTime> createdAt;
  final Value<DateTime?> nextRetryAt;
  final Value<int> retryCount;
  const SyncLogsCompanion({
    this.id = const Value.absent(),
    this.scope = const Value.absent(),
    this.scopeId = const Value.absent(),
    this.action = const Value.absent(),
    this.status = const Value.absent(),
    this.message = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.retryCount = const Value.absent(),
  });
  SyncLogsCompanion.insert({
    this.id = const Value.absent(),
    required String scope,
    this.scopeId = const Value.absent(),
    required String action,
    required String status,
    this.message = const Value.absent(),
    required DateTime createdAt,
    this.nextRetryAt = const Value.absent(),
    this.retryCount = const Value.absent(),
  }) : scope = Value(scope),
       action = Value(action),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<SyncLogEntry> custom({
    Expression<int>? id,
    Expression<String>? scope,
    Expression<String>? scopeId,
    Expression<String>? action,
    Expression<String>? status,
    Expression<String>? message,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? nextRetryAt,
    Expression<int>? retryCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scope != null) 'scope': scope,
      if (scopeId != null) 'scope_id': scopeId,
      if (action != null) 'action': action,
      if (status != null) 'status': status,
      if (message != null) 'message': message,
      if (createdAt != null) 'created_at': createdAt,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (retryCount != null) 'retry_count': retryCount,
    });
  }

  SyncLogsCompanion copyWith({
    Value<int>? id,
    Value<String>? scope,
    Value<String?>? scopeId,
    Value<String>? action,
    Value<String>? status,
    Value<String?>? message,
    Value<DateTime>? createdAt,
    Value<DateTime?>? nextRetryAt,
    Value<int>? retryCount,
  }) {
    return SyncLogsCompanion(
      id: id ?? this.id,
      scope: scope ?? this.scope,
      scopeId: scopeId ?? this.scopeId,
      action: action ?? this.action,
      status: status ?? this.status,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (scopeId.present) {
      map['scope_id'] = Variable<String>(scopeId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncLogsCompanion(')
          ..write('id: $id, ')
          ..write('scope: $scope, ')
          ..write('scopeId: $scopeId, ')
          ..write('action: $action, ')
          ..write('status: $status, ')
          ..write('message: $message, ')
          ..write('createdAt: $createdAt, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }
}

class $CachedContactsTable extends CachedContacts
    with TableInfo<$CachedContactsTable, CachedContact> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedContactsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _contactIdMeta = const VerificationMeta(
    'contactId',
  );
  @override
  late final GeneratedColumn<int> contactId = GeneratedColumn<int>(
    'contact_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remarkMeta = const VerificationMeta('remark');
  @override
  late final GeneratedColumn<String> remark = GeneratedColumn<String>(
    'remark',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nickNameMeta = const VerificationMeta(
    'nickName',
  );
  @override
  late final GeneratedColumn<String> nickName = GeneratedColumn<String>(
    'nick_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarMeta = const VerificationMeta('avatar');
  @override
  late final GeneratedColumn<String> avatar = GeneratedColumn<String>(
    'avatar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sexMeta = const VerificationMeta('sex');
  @override
  late final GeneratedColumn<String> sex = GeneratedColumn<String>(
    'sex',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _onlineStatusMeta = const VerificationMeta(
    'onlineStatus',
  );
  @override
  late final GeneratedColumn<bool> onlineStatus = GeneratedColumn<bool>(
    'online_status',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("online_status" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    contactId,
    remark,
    nickName,
    avatar,
    sex,
    onlineStatus,
    updatedAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_contacts';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedContact> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('contact_id')) {
      context.handle(
        _contactIdMeta,
        contactId.isAcceptableOrUnknown(data['contact_id']!, _contactIdMeta),
      );
    }
    if (data.containsKey('remark')) {
      context.handle(
        _remarkMeta,
        remark.isAcceptableOrUnknown(data['remark']!, _remarkMeta),
      );
    }
    if (data.containsKey('nick_name')) {
      context.handle(
        _nickNameMeta,
        nickName.isAcceptableOrUnknown(data['nick_name']!, _nickNameMeta),
      );
    }
    if (data.containsKey('avatar')) {
      context.handle(
        _avatarMeta,
        avatar.isAcceptableOrUnknown(data['avatar']!, _avatarMeta),
      );
    }
    if (data.containsKey('sex')) {
      context.handle(
        _sexMeta,
        sex.isAcceptableOrUnknown(data['sex']!, _sexMeta),
      );
    }
    if (data.containsKey('online_status')) {
      context.handle(
        _onlineStatusMeta,
        onlineStatus.isAcceptableOrUnknown(
          data['online_status']!,
          _onlineStatusMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {contactId};
  @override
  CachedContact map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedContact(
      contactId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}contact_id'],
      )!,
      remark: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remark'],
      ),
      nickName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nick_name'],
      ),
      avatar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar'],
      ),
      sex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sex'],
      ),
      onlineStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}online_status'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedContactsTable createAlias(String alias) {
    return $CachedContactsTable(attachedDatabase, alias);
  }
}

class CachedContact extends DataClass implements Insertable<CachedContact> {
  /// 联系人用户 ID（主键）
  final int contactId;

  /// 备注名（用户自定义，优先展示）
  final String? remark;

  /// 昵称
  final String? nickName;

  /// 头像 URL
  final String? avatar;

  /// 性别
  final String? sex;

  /// 在线状态（由 WebSocket 维护，不作为持久化数据依赖）
  final bool onlineStatus;

  /// 服务端最后更新时间（用于增量同步判断）
  final DateTime? updatedAt;
  final DateTime cachedAt;
  const CachedContact({
    required this.contactId,
    this.remark,
    this.nickName,
    this.avatar,
    this.sex,
    required this.onlineStatus,
    this.updatedAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['contact_id'] = Variable<int>(contactId);
    if (!nullToAbsent || remark != null) {
      map['remark'] = Variable<String>(remark);
    }
    if (!nullToAbsent || nickName != null) {
      map['nick_name'] = Variable<String>(nickName);
    }
    if (!nullToAbsent || avatar != null) {
      map['avatar'] = Variable<String>(avatar);
    }
    if (!nullToAbsent || sex != null) {
      map['sex'] = Variable<String>(sex);
    }
    map['online_status'] = Variable<bool>(onlineStatus);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedContactsCompanion toCompanion(bool nullToAbsent) {
    return CachedContactsCompanion(
      contactId: Value(contactId),
      remark: remark == null && nullToAbsent
          ? const Value.absent()
          : Value(remark),
      nickName: nickName == null && nullToAbsent
          ? const Value.absent()
          : Value(nickName),
      avatar: avatar == null && nullToAbsent
          ? const Value.absent()
          : Value(avatar),
      sex: sex == null && nullToAbsent ? const Value.absent() : Value(sex),
      onlineStatus: Value(onlineStatus),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedContact.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedContact(
      contactId: serializer.fromJson<int>(json['contactId']),
      remark: serializer.fromJson<String?>(json['remark']),
      nickName: serializer.fromJson<String?>(json['nickName']),
      avatar: serializer.fromJson<String?>(json['avatar']),
      sex: serializer.fromJson<String?>(json['sex']),
      onlineStatus: serializer.fromJson<bool>(json['onlineStatus']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'contactId': serializer.toJson<int>(contactId),
      'remark': serializer.toJson<String?>(remark),
      'nickName': serializer.toJson<String?>(nickName),
      'avatar': serializer.toJson<String?>(avatar),
      'sex': serializer.toJson<String?>(sex),
      'onlineStatus': serializer.toJson<bool>(onlineStatus),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedContact copyWith({
    int? contactId,
    Value<String?> remark = const Value.absent(),
    Value<String?> nickName = const Value.absent(),
    Value<String?> avatar = const Value.absent(),
    Value<String?> sex = const Value.absent(),
    bool? onlineStatus,
    Value<DateTime?> updatedAt = const Value.absent(),
    DateTime? cachedAt,
  }) => CachedContact(
    contactId: contactId ?? this.contactId,
    remark: remark.present ? remark.value : this.remark,
    nickName: nickName.present ? nickName.value : this.nickName,
    avatar: avatar.present ? avatar.value : this.avatar,
    sex: sex.present ? sex.value : this.sex,
    onlineStatus: onlineStatus ?? this.onlineStatus,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedContact copyWithCompanion(CachedContactsCompanion data) {
    return CachedContact(
      contactId: data.contactId.present ? data.contactId.value : this.contactId,
      remark: data.remark.present ? data.remark.value : this.remark,
      nickName: data.nickName.present ? data.nickName.value : this.nickName,
      avatar: data.avatar.present ? data.avatar.value : this.avatar,
      sex: data.sex.present ? data.sex.value : this.sex,
      onlineStatus: data.onlineStatus.present
          ? data.onlineStatus.value
          : this.onlineStatus,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedContact(')
          ..write('contactId: $contactId, ')
          ..write('remark: $remark, ')
          ..write('nickName: $nickName, ')
          ..write('avatar: $avatar, ')
          ..write('sex: $sex, ')
          ..write('onlineStatus: $onlineStatus, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    contactId,
    remark,
    nickName,
    avatar,
    sex,
    onlineStatus,
    updatedAt,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedContact &&
          other.contactId == this.contactId &&
          other.remark == this.remark &&
          other.nickName == this.nickName &&
          other.avatar == this.avatar &&
          other.sex == this.sex &&
          other.onlineStatus == this.onlineStatus &&
          other.updatedAt == this.updatedAt &&
          other.cachedAt == this.cachedAt);
}

class CachedContactsCompanion extends UpdateCompanion<CachedContact> {
  final Value<int> contactId;
  final Value<String?> remark;
  final Value<String?> nickName;
  final Value<String?> avatar;
  final Value<String?> sex;
  final Value<bool> onlineStatus;
  final Value<DateTime?> updatedAt;
  final Value<DateTime> cachedAt;
  const CachedContactsCompanion({
    this.contactId = const Value.absent(),
    this.remark = const Value.absent(),
    this.nickName = const Value.absent(),
    this.avatar = const Value.absent(),
    this.sex = const Value.absent(),
    this.onlineStatus = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CachedContactsCompanion.insert({
    this.contactId = const Value.absent(),
    this.remark = const Value.absent(),
    this.nickName = const Value.absent(),
    this.avatar = const Value.absent(),
    this.sex = const Value.absent(),
    this.onlineStatus = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required DateTime cachedAt,
  }) : cachedAt = Value(cachedAt);
  static Insertable<CachedContact> custom({
    Expression<int>? contactId,
    Expression<String>? remark,
    Expression<String>? nickName,
    Expression<String>? avatar,
    Expression<String>? sex,
    Expression<bool>? onlineStatus,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (contactId != null) 'contact_id': contactId,
      if (remark != null) 'remark': remark,
      if (nickName != null) 'nick_name': nickName,
      if (avatar != null) 'avatar': avatar,
      if (sex != null) 'sex': sex,
      if (onlineStatus != null) 'online_status': onlineStatus,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CachedContactsCompanion copyWith({
    Value<int>? contactId,
    Value<String?>? remark,
    Value<String?>? nickName,
    Value<String?>? avatar,
    Value<String?>? sex,
    Value<bool>? onlineStatus,
    Value<DateTime?>? updatedAt,
    Value<DateTime>? cachedAt,
  }) {
    return CachedContactsCompanion(
      contactId: contactId ?? this.contactId,
      remark: remark ?? this.remark,
      nickName: nickName ?? this.nickName,
      avatar: avatar ?? this.avatar,
      sex: sex ?? this.sex,
      onlineStatus: onlineStatus ?? this.onlineStatus,
      updatedAt: updatedAt ?? this.updatedAt,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (contactId.present) {
      map['contact_id'] = Variable<int>(contactId.value);
    }
    if (remark.present) {
      map['remark'] = Variable<String>(remark.value);
    }
    if (nickName.present) {
      map['nick_name'] = Variable<String>(nickName.value);
    }
    if (avatar.present) {
      map['avatar'] = Variable<String>(avatar.value);
    }
    if (sex.present) {
      map['sex'] = Variable<String>(sex.value);
    }
    if (onlineStatus.present) {
      map['online_status'] = Variable<bool>(onlineStatus.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedContactsCompanion(')
          ..write('contactId: $contactId, ')
          ..write('remark: $remark, ')
          ..write('nickName: $nickName, ')
          ..write('avatar: $avatar, ')
          ..write('sex: $sex, ')
          ..write('onlineStatus: $onlineStatus, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedUsersTable cachedUsers = $CachedUsersTable(this);
  late final $ConversationsTable conversations = $ConversationsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $SyncStatesTable syncStates = $SyncStatesTable(this);
  late final $SyncLogsTable syncLogs = $SyncLogsTable(this);
  late final $CachedContactsTable cachedContacts = $CachedContactsTable(this);
  late final UserDao userDao = UserDao(this as AppDatabase);
  late final ConversationDao conversationDao = ConversationDao(
    this as AppDatabase,
  );
  late final MessageDao messageDao = MessageDao(this as AppDatabase);
  late final SyncStateDao syncStateDao = SyncStateDao(this as AppDatabase);
  late final SyncLogDao syncLogDao = SyncLogDao(this as AppDatabase);
  late final ContactDao contactDao = ContactDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedUsers,
    conversations,
    messages,
    syncStates,
    syncLogs,
    cachedContacts,
  ];
}

typedef $$CachedUsersTableCreateCompanionBuilder =
    CachedUsersCompanion Function({
      Value<int> userId,
      Value<String> userName,
      Value<String> nickName,
      Value<String> email,
      Value<String> phoneNumber,
      Value<String> sex,
      Value<String> avatar,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      required DateTime cachedAt,
    });
typedef $$CachedUsersTableUpdateCompanionBuilder =
    CachedUsersCompanion Function({
      Value<int> userId,
      Value<String> userName,
      Value<String> nickName,
      Value<String> email,
      Value<String> phoneNumber,
      Value<String> sex,
      Value<String> avatar,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<DateTime> cachedAt,
    });

final class $$CachedUsersTableReferences
    extends BaseReferences<_$AppDatabase, $CachedUsersTable, CachedUser> {
  $$CachedUsersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ConversationsTable, List<CachedConversation>>
  _conversationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.conversations,
    aliasName: 'cached_users__user_id__conversations__peer_id',
  );

  $$ConversationsTableProcessedTableManager get conversationsRefs {
    final manager = $$ConversationsTableTableManager(
      $_db,
      $_db.conversations,
    ).filter((f) => f.peerId.userId.sqlEquals($_itemColumn<int>('user_id')!));

    final cache = $_typedResult.readTableOrNull(_conversationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MessagesTable, List<CachedMessage>>
  _messagesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.messages,
    aliasName: 'cached_users__user_id__messages__sender_id',
  );

  $$MessagesTableProcessedTableManager get messagesRefs {
    final manager = $$MessagesTableTableManager(
      $_db,
      $_db.messages,
    ).filter((f) => f.senderId.userId.sqlEquals($_itemColumn<int>('user_id')!));

    final cache = $_typedResult.readTableOrNull(_messagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CachedUsersTableFilterComposer
    extends Composer<_$AppDatabase, $CachedUsersTable> {
  $$CachedUsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userName => $composableBuilder(
    column: $table.userName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nickName => $composableBuilder(
    column: $table.nickName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> conversationsRefs(
    Expression<bool> Function($$ConversationsTableFilterComposer f) f,
  ) {
    final $$ConversationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.peerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableFilterComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> messagesRefs(
    Expression<bool> Function($$MessagesTableFilterComposer f) f,
  ) {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.senderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableFilterComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CachedUsersTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedUsersTable> {
  $$CachedUsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userName => $composableBuilder(
    column: $table.userName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nickName => $composableBuilder(
    column: $table.nickName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedUsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedUsersTable> {
  $$CachedUsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get userName =>
      $composableBuilder(column: $table.userName, builder: (column) => column);

  GeneratedColumn<String> get nickName =>
      $composableBuilder(column: $table.nickName, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => column);

  GeneratedColumn<String> get avatar =>
      $composableBuilder(column: $table.avatar, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  Expression<T> conversationsRefs<T extends Object>(
    Expression<T> Function($$ConversationsTableAnnotationComposer a) f,
  ) {
    final $$ConversationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.peerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableAnnotationComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> messagesRefs<T extends Object>(
    Expression<T> Function($$MessagesTableAnnotationComposer a) f,
  ) {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.senderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CachedUsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedUsersTable,
          CachedUser,
          $$CachedUsersTableFilterComposer,
          $$CachedUsersTableOrderingComposer,
          $$CachedUsersTableAnnotationComposer,
          $$CachedUsersTableCreateCompanionBuilder,
          $$CachedUsersTableUpdateCompanionBuilder,
          (CachedUser, $$CachedUsersTableReferences),
          CachedUser,
          PrefetchHooks Function({bool conversationsRefs, bool messagesRefs})
        > {
  $$CachedUsersTableTableManager(_$AppDatabase db, $CachedUsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedUsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedUsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedUsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> userId = const Value.absent(),
                Value<String> userName = const Value.absent(),
                Value<String> nickName = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> phoneNumber = const Value.absent(),
                Value<String> sex = const Value.absent(),
                Value<String> avatar = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => CachedUsersCompanion(
                userId: userId,
                userName: userName,
                nickName: nickName,
                email: email,
                phoneNumber: phoneNumber,
                sex: sex,
                avatar: avatar,
                createdAt: createdAt,
                updatedAt: updatedAt,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> userId = const Value.absent(),
                Value<String> userName = const Value.absent(),
                Value<String> nickName = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> phoneNumber = const Value.absent(),
                Value<String> sex = const Value.absent(),
                Value<String> avatar = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                required DateTime cachedAt,
              }) => CachedUsersCompanion.insert(
                userId: userId,
                userName: userName,
                nickName: nickName,
                email: email,
                phoneNumber: phoneNumber,
                sex: sex,
                avatar: avatar,
                createdAt: createdAt,
                updatedAt: updatedAt,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CachedUsersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({conversationsRefs = false, messagesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (conversationsRefs) db.conversations,
                    if (messagesRefs) db.messages,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (conversationsRefs)
                        await $_getPrefetchedData<
                          CachedUser,
                          $CachedUsersTable,
                          CachedConversation
                        >(
                          currentTable: table,
                          referencedTable: $$CachedUsersTableReferences
                              ._conversationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CachedUsersTableReferences(
                                db,
                                table,
                                p0,
                              ).conversationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.peerId == item.userId,
                              ),
                          typedResults: items,
                        ),
                      if (messagesRefs)
                        await $_getPrefetchedData<
                          CachedUser,
                          $CachedUsersTable,
                          CachedMessage
                        >(
                          currentTable: table,
                          referencedTable: $$CachedUsersTableReferences
                              ._messagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CachedUsersTableReferences(
                                db,
                                table,
                                p0,
                              ).messagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.senderId == item.userId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CachedUsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedUsersTable,
      CachedUser,
      $$CachedUsersTableFilterComposer,
      $$CachedUsersTableOrderingComposer,
      $$CachedUsersTableAnnotationComposer,
      $$CachedUsersTableCreateCompanionBuilder,
      $$CachedUsersTableUpdateCompanionBuilder,
      (CachedUser, $$CachedUsersTableReferences),
      CachedUser,
      PrefetchHooks Function({bool conversationsRefs, bool messagesRefs})
    >;
typedef $$ConversationsTableCreateCompanionBuilder =
    ConversationsCompanion Function({
      required String id,
      Value<String?> name,
      Value<String?> avatar,
      Value<String?> description,
      Value<int> type,
      Value<int> status,
      Value<int?> peerId,
      Value<int> unreadCount,
      Value<int> lastReadSeq,
      Value<String?> lastMessageId,
      Value<String?> lastMessagePreview,
      Value<int?> lastMessageType,
      Value<int?> lastMessageSeq,
      Value<DateTime?> lastMessageAt,
      Value<DateTime?> createdAt,
      required DateTime updatedAt,
      required DateTime cachedAt,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$ConversationsTableUpdateCompanionBuilder =
    ConversationsCompanion Function({
      Value<String> id,
      Value<String?> name,
      Value<String?> avatar,
      Value<String?> description,
      Value<int> type,
      Value<int> status,
      Value<int?> peerId,
      Value<int> unreadCount,
      Value<int> lastReadSeq,
      Value<String?> lastMessageId,
      Value<String?> lastMessagePreview,
      Value<int?> lastMessageType,
      Value<int?> lastMessageSeq,
      Value<DateTime?> lastMessageAt,
      Value<DateTime?> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime> cachedAt,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

final class $$ConversationsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ConversationsTable, CachedConversation> {
  $$ConversationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CachedUsersTable _peerIdTable(_$AppDatabase db) => db.cachedUsers
      .createAlias('conversations__peer_id__cached_users__user_id');

  $$CachedUsersTableProcessedTableManager? get peerId {
    final $_column = $_itemColumn<int>('peer_id');
    if ($_column == null) return null;
    final manager = $$CachedUsersTableTableManager(
      $_db,
      $_db.cachedUsers,
    ).filter((f) => f.userId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_peerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$MessagesTable, List<CachedMessage>>
  _messagesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.messages,
    aliasName: 'conversations__id__messages__conversation_id',
  );

  $$MessagesTableProcessedTableManager get messagesRefs {
    final manager = $$MessagesTableTableManager(
      $_db,
      $_db.messages,
    ).filter((f) => f.conversationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_messagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ConversationsTableFilterComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastReadSeq => $composableBuilder(
    column: $table.lastReadSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessageId => $composableBuilder(
    column: $table.lastMessageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessagePreview => $composableBuilder(
    column: $table.lastMessagePreview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastMessageType => $composableBuilder(
    column: $table.lastMessageType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastMessageSeq => $composableBuilder(
    column: $table.lastMessageSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  $$CachedUsersTableFilterComposer get peerId {
    final $$CachedUsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.peerId,
      referencedTable: $db.cachedUsers,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedUsersTableFilterComposer(
            $db: $db,
            $table: $db.cachedUsers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> messagesRefs(
    Expression<bool> Function($$MessagesTableFilterComposer f) f,
  ) {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.conversationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableFilterComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ConversationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastReadSeq => $composableBuilder(
    column: $table.lastReadSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessageId => $composableBuilder(
    column: $table.lastMessageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessagePreview => $composableBuilder(
    column: $table.lastMessagePreview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastMessageType => $composableBuilder(
    column: $table.lastMessageType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastMessageSeq => $composableBuilder(
    column: $table.lastMessageSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$CachedUsersTableOrderingComposer get peerId {
    final $$CachedUsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.peerId,
      referencedTable: $db.cachedUsers,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedUsersTableOrderingComposer(
            $db: $db,
            $table: $db.cachedUsers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConversationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get avatar =>
      $composableBuilder(column: $table.avatar, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastReadSeq => $composableBuilder(
    column: $table.lastReadSeq,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMessageId => $composableBuilder(
    column: $table.lastMessageId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMessagePreview => $composableBuilder(
    column: $table.lastMessagePreview,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastMessageType => $composableBuilder(
    column: $table.lastMessageType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastMessageSeq => $composableBuilder(
    column: $table.lastMessageSeq,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  $$CachedUsersTableAnnotationComposer get peerId {
    final $$CachedUsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.peerId,
      referencedTable: $db.cachedUsers,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedUsersTableAnnotationComposer(
            $db: $db,
            $table: $db.cachedUsers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> messagesRefs<T extends Object>(
    Expression<T> Function($$MessagesTableAnnotationComposer a) f,
  ) {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.conversationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ConversationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConversationsTable,
          CachedConversation,
          $$ConversationsTableFilterComposer,
          $$ConversationsTableOrderingComposer,
          $$ConversationsTableAnnotationComposer,
          $$ConversationsTableCreateCompanionBuilder,
          $$ConversationsTableUpdateCompanionBuilder,
          (CachedConversation, $$ConversationsTableReferences),
          CachedConversation,
          PrefetchHooks Function({bool peerId, bool messagesRefs})
        > {
  $$ConversationsTableTableManager(_$AppDatabase db, $ConversationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConversationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConversationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> avatar = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int?> peerId = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<int> lastReadSeq = const Value.absent(),
                Value<String?> lastMessageId = const Value.absent(),
                Value<String?> lastMessagePreview = const Value.absent(),
                Value<int?> lastMessageType = const Value.absent(),
                Value<int?> lastMessageSeq = const Value.absent(),
                Value<DateTime?> lastMessageAt = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationsCompanion(
                id: id,
                name: name,
                avatar: avatar,
                description: description,
                type: type,
                status: status,
                peerId: peerId,
                unreadCount: unreadCount,
                lastReadSeq: lastReadSeq,
                lastMessageId: lastMessageId,
                lastMessagePreview: lastMessagePreview,
                lastMessageType: lastMessageType,
                lastMessageSeq: lastMessageSeq,
                lastMessageAt: lastMessageAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                cachedAt: cachedAt,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> name = const Value.absent(),
                Value<String?> avatar = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int?> peerId = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<int> lastReadSeq = const Value.absent(),
                Value<String?> lastMessageId = const Value.absent(),
                Value<String?> lastMessagePreview = const Value.absent(),
                Value<int?> lastMessageType = const Value.absent(),
                Value<int?> lastMessageSeq = const Value.absent(),
                Value<DateTime?> lastMessageAt = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                required DateTime updatedAt,
                required DateTime cachedAt,
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationsCompanion.insert(
                id: id,
                name: name,
                avatar: avatar,
                description: description,
                type: type,
                status: status,
                peerId: peerId,
                unreadCount: unreadCount,
                lastReadSeq: lastReadSeq,
                lastMessageId: lastMessageId,
                lastMessagePreview: lastMessagePreview,
                lastMessageType: lastMessageType,
                lastMessageSeq: lastMessageSeq,
                lastMessageAt: lastMessageAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                cachedAt: cachedAt,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ConversationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({peerId = false, messagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (messagesRefs) db.messages],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (peerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.peerId,
                                referencedTable: $$ConversationsTableReferences
                                    ._peerIdTable(db),
                                referencedColumn: $$ConversationsTableReferences
                                    ._peerIdTable(db)
                                    .userId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (messagesRefs)
                    await $_getPrefetchedData<
                      CachedConversation,
                      $ConversationsTable,
                      CachedMessage
                    >(
                      currentTable: table,
                      referencedTable: $$ConversationsTableReferences
                          ._messagesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ConversationsTableReferences(
                            db,
                            table,
                            p0,
                          ).messagesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.conversationId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ConversationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConversationsTable,
      CachedConversation,
      $$ConversationsTableFilterComposer,
      $$ConversationsTableOrderingComposer,
      $$ConversationsTableAnnotationComposer,
      $$ConversationsTableCreateCompanionBuilder,
      $$ConversationsTableUpdateCompanionBuilder,
      (CachedConversation, $$ConversationsTableReferences),
      CachedConversation,
      PrefetchHooks Function({bool peerId, bool messagesRefs})
    >;
typedef $$MessagesTableCreateCompanionBuilder =
    MessagesCompanion Function({
      required String id,
      Value<String?> clientMsgId,
      required String conversationId,
      Value<int?> senderId,
      Value<int> messageType,
      Value<String> content,
      Value<String?> payloadJson,
      Value<String?> propertiesJson,
      Value<String> deliveryStatus,
      Value<int> seq,
      Value<DateTime?> sentAt,
      required DateTime localCreatedAt,
      required DateTime updatedAt,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$MessagesTableUpdateCompanionBuilder =
    MessagesCompanion Function({
      Value<String> id,
      Value<String?> clientMsgId,
      Value<String> conversationId,
      Value<int?> senderId,
      Value<int> messageType,
      Value<String> content,
      Value<String?> payloadJson,
      Value<String?> propertiesJson,
      Value<String> deliveryStatus,
      Value<int> seq,
      Value<DateTime?> sentAt,
      Value<DateTime> localCreatedAt,
      Value<DateTime> updatedAt,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

final class $$MessagesTableReferences
    extends BaseReferences<_$AppDatabase, $MessagesTable, CachedMessage> {
  $$MessagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ConversationsTable _conversationIdTable(_$AppDatabase db) => db
      .conversations
      .createAlias('messages__conversation_id__conversations__id');

  $$ConversationsTableProcessedTableManager get conversationId {
    final $_column = $_itemColumn<String>('conversation_id')!;

    final manager = $$ConversationsTableTableManager(
      $_db,
      $_db.conversations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_conversationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CachedUsersTable _senderIdTable(_$AppDatabase db) =>
      db.cachedUsers.createAlias('messages__sender_id__cached_users__user_id');

  $$CachedUsersTableProcessedTableManager? get senderId {
    final $_column = $_itemColumn<int>('sender_id');
    if ($_column == null) return null;
    final manager = $$CachedUsersTableTableManager(
      $_db,
      $_db.cachedUsers,
    ).filter((f) => f.userId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_senderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientMsgId => $composableBuilder(
    column: $table.clientMsgId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get messageType => $composableBuilder(
    column: $table.messageType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get propertiesJson => $composableBuilder(
    column: $table.propertiesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deliveryStatus => $composableBuilder(
    column: $table.deliveryStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localCreatedAt => $composableBuilder(
    column: $table.localCreatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  $$ConversationsTableFilterComposer get conversationId {
    final $$ConversationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableFilterComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CachedUsersTableFilterComposer get senderId {
    final $$CachedUsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.senderId,
      referencedTable: $db.cachedUsers,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedUsersTableFilterComposer(
            $db: $db,
            $table: $db.cachedUsers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientMsgId => $composableBuilder(
    column: $table.clientMsgId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get messageType => $composableBuilder(
    column: $table.messageType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get propertiesJson => $composableBuilder(
    column: $table.propertiesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deliveryStatus => $composableBuilder(
    column: $table.deliveryStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localCreatedAt => $composableBuilder(
    column: $table.localCreatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$ConversationsTableOrderingComposer get conversationId {
    final $$ConversationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableOrderingComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CachedUsersTableOrderingComposer get senderId {
    final $$CachedUsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.senderId,
      referencedTable: $db.cachedUsers,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedUsersTableOrderingComposer(
            $db: $db,
            $table: $db.cachedUsers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientMsgId => $composableBuilder(
    column: $table.clientMsgId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get messageType => $composableBuilder(
    column: $table.messageType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get propertiesJson => $composableBuilder(
    column: $table.propertiesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deliveryStatus => $composableBuilder(
    column: $table.deliveryStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<DateTime> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);

  GeneratedColumn<DateTime> get localCreatedAt => $composableBuilder(
    column: $table.localCreatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  $$ConversationsTableAnnotationComposer get conversationId {
    final $$ConversationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableAnnotationComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CachedUsersTableAnnotationComposer get senderId {
    final $$CachedUsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.senderId,
      referencedTable: $db.cachedUsers,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedUsersTableAnnotationComposer(
            $db: $db,
            $table: $db.cachedUsers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessagesTable,
          CachedMessage,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (CachedMessage, $$MessagesTableReferences),
          CachedMessage,
          PrefetchHooks Function({bool conversationId, bool senderId})
        > {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> clientMsgId = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<int?> senderId = const Value.absent(),
                Value<int> messageType = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> payloadJson = const Value.absent(),
                Value<String?> propertiesJson = const Value.absent(),
                Value<String> deliveryStatus = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<DateTime?> sentAt = const Value.absent(),
                Value<DateTime> localCreatedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion(
                id: id,
                clientMsgId: clientMsgId,
                conversationId: conversationId,
                senderId: senderId,
                messageType: messageType,
                content: content,
                payloadJson: payloadJson,
                propertiesJson: propertiesJson,
                deliveryStatus: deliveryStatus,
                seq: seq,
                sentAt: sentAt,
                localCreatedAt: localCreatedAt,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> clientMsgId = const Value.absent(),
                required String conversationId,
                Value<int?> senderId = const Value.absent(),
                Value<int> messageType = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> payloadJson = const Value.absent(),
                Value<String?> propertiesJson = const Value.absent(),
                Value<String> deliveryStatus = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<DateTime?> sentAt = const Value.absent(),
                required DateTime localCreatedAt,
                required DateTime updatedAt,
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion.insert(
                id: id,
                clientMsgId: clientMsgId,
                conversationId: conversationId,
                senderId: senderId,
                messageType: messageType,
                content: content,
                payloadJson: payloadJson,
                propertiesJson: propertiesJson,
                deliveryStatus: deliveryStatus,
                seq: seq,
                sentAt: sentAt,
                localCreatedAt: localCreatedAt,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MessagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({conversationId = false, senderId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (conversationId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.conversationId,
                                referencedTable: $$MessagesTableReferences
                                    ._conversationIdTable(db),
                                referencedColumn: $$MessagesTableReferences
                                    ._conversationIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (senderId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.senderId,
                                referencedTable: $$MessagesTableReferences
                                    ._senderIdTable(db),
                                referencedColumn: $$MessagesTableReferences
                                    ._senderIdTable(db)
                                    .userId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessagesTable,
      CachedMessage,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (CachedMessage, $$MessagesTableReferences),
      CachedMessage,
      PrefetchHooks Function({bool conversationId, bool senderId})
    >;
typedef $$SyncStatesTableCreateCompanionBuilder =
    SyncStatesCompanion Function({
      required String scope,
      Value<String> scopeId,
      Value<DateTime?> lastSyncedAt,
      Value<int> lastSeq,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SyncStatesTableUpdateCompanionBuilder =
    SyncStatesCompanion Function({
      Value<String> scope,
      Value<String> scopeId,
      Value<DateTime?> lastSyncedAt,
      Value<int> lastSeq,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SyncStatesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStatesTable> {
  $$SyncStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeId => $composableBuilder(
    column: $table.scopeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSeq => $composableBuilder(
    column: $table.lastSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStatesTable> {
  $$SyncStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeId => $composableBuilder(
    column: $table.scopeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSeq => $composableBuilder(
    column: $table.lastSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStatesTable> {
  $$SyncStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<String> get scopeId =>
      $composableBuilder(column: $table.scopeId, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSeq =>
      $composableBuilder(column: $table.lastSeq, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStatesTable,
          SyncState,
          $$SyncStatesTableFilterComposer,
          $$SyncStatesTableOrderingComposer,
          $$SyncStatesTableAnnotationComposer,
          $$SyncStatesTableCreateCompanionBuilder,
          $$SyncStatesTableUpdateCompanionBuilder,
          (
            SyncState,
            BaseReferences<_$AppDatabase, $SyncStatesTable, SyncState>,
          ),
          SyncState,
          PrefetchHooks Function()
        > {
  $$SyncStatesTableTableManager(_$AppDatabase db, $SyncStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> scope = const Value.absent(),
                Value<String> scopeId = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> lastSeq = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStatesCompanion(
                scope: scope,
                scopeId: scopeId,
                lastSyncedAt: lastSyncedAt,
                lastSeq: lastSeq,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String scope,
                Value<String> scopeId = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> lastSeq = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncStatesCompanion.insert(
                scope: scope,
                scopeId: scopeId,
                lastSyncedAt: lastSyncedAt,
                lastSeq: lastSeq,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStatesTable,
      SyncState,
      $$SyncStatesTableFilterComposer,
      $$SyncStatesTableOrderingComposer,
      $$SyncStatesTableAnnotationComposer,
      $$SyncStatesTableCreateCompanionBuilder,
      $$SyncStatesTableUpdateCompanionBuilder,
      (SyncState, BaseReferences<_$AppDatabase, $SyncStatesTable, SyncState>),
      SyncState,
      PrefetchHooks Function()
    >;
typedef $$SyncLogsTableCreateCompanionBuilder =
    SyncLogsCompanion Function({
      Value<int> id,
      required String scope,
      Value<String?> scopeId,
      required String action,
      required String status,
      Value<String?> message,
      required DateTime createdAt,
      Value<DateTime?> nextRetryAt,
      Value<int> retryCount,
    });
typedef $$SyncLogsTableUpdateCompanionBuilder =
    SyncLogsCompanion Function({
      Value<int> id,
      Value<String> scope,
      Value<String?> scopeId,
      Value<String> action,
      Value<String> status,
      Value<String?> message,
      Value<DateTime> createdAt,
      Value<DateTime?> nextRetryAt,
      Value<int> retryCount,
    });

class $$SyncLogsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncLogsTable> {
  $$SyncLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeId => $composableBuilder(
    column: $table.scopeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncLogsTable> {
  $$SyncLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeId => $composableBuilder(
    column: $table.scopeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncLogsTable> {
  $$SyncLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<String> get scopeId =>
      $composableBuilder(column: $table.scopeId, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );
}

class $$SyncLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncLogsTable,
          SyncLogEntry,
          $$SyncLogsTableFilterComposer,
          $$SyncLogsTableOrderingComposer,
          $$SyncLogsTableAnnotationComposer,
          $$SyncLogsTableCreateCompanionBuilder,
          $$SyncLogsTableUpdateCompanionBuilder,
          (
            SyncLogEntry,
            BaseReferences<_$AppDatabase, $SyncLogsTable, SyncLogEntry>,
          ),
          SyncLogEntry,
          PrefetchHooks Function()
        > {
  $$SyncLogsTableTableManager(_$AppDatabase db, $SyncLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> scope = const Value.absent(),
                Value<String?> scopeId = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> message = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
              }) => SyncLogsCompanion(
                id: id,
                scope: scope,
                scopeId: scopeId,
                action: action,
                status: status,
                message: message,
                createdAt: createdAt,
                nextRetryAt: nextRetryAt,
                retryCount: retryCount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String scope,
                Value<String?> scopeId = const Value.absent(),
                required String action,
                required String status,
                Value<String?> message = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> nextRetryAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
              }) => SyncLogsCompanion.insert(
                id: id,
                scope: scope,
                scopeId: scopeId,
                action: action,
                status: status,
                message: message,
                createdAt: createdAt,
                nextRetryAt: nextRetryAt,
                retryCount: retryCount,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncLogsTable,
      SyncLogEntry,
      $$SyncLogsTableFilterComposer,
      $$SyncLogsTableOrderingComposer,
      $$SyncLogsTableAnnotationComposer,
      $$SyncLogsTableCreateCompanionBuilder,
      $$SyncLogsTableUpdateCompanionBuilder,
      (
        SyncLogEntry,
        BaseReferences<_$AppDatabase, $SyncLogsTable, SyncLogEntry>,
      ),
      SyncLogEntry,
      PrefetchHooks Function()
    >;
typedef $$CachedContactsTableCreateCompanionBuilder =
    CachedContactsCompanion Function({
      Value<int> contactId,
      Value<String?> remark,
      Value<String?> nickName,
      Value<String?> avatar,
      Value<String?> sex,
      Value<bool> onlineStatus,
      Value<DateTime?> updatedAt,
      required DateTime cachedAt,
    });
typedef $$CachedContactsTableUpdateCompanionBuilder =
    CachedContactsCompanion Function({
      Value<int> contactId,
      Value<String?> remark,
      Value<String?> nickName,
      Value<String?> avatar,
      Value<String?> sex,
      Value<bool> onlineStatus,
      Value<DateTime?> updatedAt,
      Value<DateTime> cachedAt,
    });

class $$CachedContactsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedContactsTable> {
  $$CachedContactsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get contactId => $composableBuilder(
    column: $table.contactId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remark => $composableBuilder(
    column: $table.remark,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nickName => $composableBuilder(
    column: $table.nickName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onlineStatus => $composableBuilder(
    column: $table.onlineStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedContactsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedContactsTable> {
  $$CachedContactsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get contactId => $composableBuilder(
    column: $table.contactId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remark => $composableBuilder(
    column: $table.remark,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nickName => $composableBuilder(
    column: $table.nickName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onlineStatus => $composableBuilder(
    column: $table.onlineStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedContactsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedContactsTable> {
  $$CachedContactsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get contactId =>
      $composableBuilder(column: $table.contactId, builder: (column) => column);

  GeneratedColumn<String> get remark =>
      $composableBuilder(column: $table.remark, builder: (column) => column);

  GeneratedColumn<String> get nickName =>
      $composableBuilder(column: $table.nickName, builder: (column) => column);

  GeneratedColumn<String> get avatar =>
      $composableBuilder(column: $table.avatar, builder: (column) => column);

  GeneratedColumn<String> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => column);

  GeneratedColumn<bool> get onlineStatus => $composableBuilder(
    column: $table.onlineStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedContactsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedContactsTable,
          CachedContact,
          $$CachedContactsTableFilterComposer,
          $$CachedContactsTableOrderingComposer,
          $$CachedContactsTableAnnotationComposer,
          $$CachedContactsTableCreateCompanionBuilder,
          $$CachedContactsTableUpdateCompanionBuilder,
          (
            CachedContact,
            BaseReferences<_$AppDatabase, $CachedContactsTable, CachedContact>,
          ),
          CachedContact,
          PrefetchHooks Function()
        > {
  $$CachedContactsTableTableManager(
    _$AppDatabase db,
    $CachedContactsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedContactsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedContactsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedContactsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> contactId = const Value.absent(),
                Value<String?> remark = const Value.absent(),
                Value<String?> nickName = const Value.absent(),
                Value<String?> avatar = const Value.absent(),
                Value<String?> sex = const Value.absent(),
                Value<bool> onlineStatus = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => CachedContactsCompanion(
                contactId: contactId,
                remark: remark,
                nickName: nickName,
                avatar: avatar,
                sex: sex,
                onlineStatus: onlineStatus,
                updatedAt: updatedAt,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> contactId = const Value.absent(),
                Value<String?> remark = const Value.absent(),
                Value<String?> nickName = const Value.absent(),
                Value<String?> avatar = const Value.absent(),
                Value<String?> sex = const Value.absent(),
                Value<bool> onlineStatus = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                required DateTime cachedAt,
              }) => CachedContactsCompanion.insert(
                contactId: contactId,
                remark: remark,
                nickName: nickName,
                avatar: avatar,
                sex: sex,
                onlineStatus: onlineStatus,
                updatedAt: updatedAt,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedContactsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedContactsTable,
      CachedContact,
      $$CachedContactsTableFilterComposer,
      $$CachedContactsTableOrderingComposer,
      $$CachedContactsTableAnnotationComposer,
      $$CachedContactsTableCreateCompanionBuilder,
      $$CachedContactsTableUpdateCompanionBuilder,
      (
        CachedContact,
        BaseReferences<_$AppDatabase, $CachedContactsTable, CachedContact>,
      ),
      CachedContact,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedUsersTableTableManager get cachedUsers =>
      $$CachedUsersTableTableManager(_db, _db.cachedUsers);
  $$ConversationsTableTableManager get conversations =>
      $$ConversationsTableTableManager(_db, _db.conversations);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$SyncStatesTableTableManager get syncStates =>
      $$SyncStatesTableTableManager(_db, _db.syncStates);
  $$SyncLogsTableTableManager get syncLogs =>
      $$SyncLogsTableTableManager(_db, _db.syncLogs);
  $$CachedContactsTableTableManager get cachedContacts =>
      $$CachedContactsTableTableManager(_db, _db.cachedContacts);
}

mixin _$UserDaoMixin on DatabaseAccessor<AppDatabase> {
  $CachedUsersTable get cachedUsers => attachedDatabase.cachedUsers;
  UserDaoManager get managers => UserDaoManager(this);
}

class UserDaoManager {
  final _$UserDaoMixin _db;
  UserDaoManager(this._db);
  $$CachedUsersTableTableManager get cachedUsers =>
      $$CachedUsersTableTableManager(_db.attachedDatabase, _db.cachedUsers);
}

mixin _$ConversationDaoMixin on DatabaseAccessor<AppDatabase> {
  $CachedUsersTable get cachedUsers => attachedDatabase.cachedUsers;
  $ConversationsTable get conversations => attachedDatabase.conversations;
  ConversationDaoManager get managers => ConversationDaoManager(this);
}

class ConversationDaoManager {
  final _$ConversationDaoMixin _db;
  ConversationDaoManager(this._db);
  $$CachedUsersTableTableManager get cachedUsers =>
      $$CachedUsersTableTableManager(_db.attachedDatabase, _db.cachedUsers);
  $$ConversationsTableTableManager get conversations =>
      $$ConversationsTableTableManager(_db.attachedDatabase, _db.conversations);
}

mixin _$MessageDaoMixin on DatabaseAccessor<AppDatabase> {
  $CachedUsersTable get cachedUsers => attachedDatabase.cachedUsers;
  $ConversationsTable get conversations => attachedDatabase.conversations;
  $MessagesTable get messages => attachedDatabase.messages;
  $SyncStatesTable get syncStates => attachedDatabase.syncStates;
  MessageDaoManager get managers => MessageDaoManager(this);
}

class MessageDaoManager {
  final _$MessageDaoMixin _db;
  MessageDaoManager(this._db);
  $$CachedUsersTableTableManager get cachedUsers =>
      $$CachedUsersTableTableManager(_db.attachedDatabase, _db.cachedUsers);
  $$ConversationsTableTableManager get conversations =>
      $$ConversationsTableTableManager(_db.attachedDatabase, _db.conversations);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db.attachedDatabase, _db.messages);
  $$SyncStatesTableTableManager get syncStates =>
      $$SyncStatesTableTableManager(_db.attachedDatabase, _db.syncStates);
}

mixin _$SyncStateDaoMixin on DatabaseAccessor<AppDatabase> {
  $SyncStatesTable get syncStates => attachedDatabase.syncStates;
  SyncStateDaoManager get managers => SyncStateDaoManager(this);
}

class SyncStateDaoManager {
  final _$SyncStateDaoMixin _db;
  SyncStateDaoManager(this._db);
  $$SyncStatesTableTableManager get syncStates =>
      $$SyncStatesTableTableManager(_db.attachedDatabase, _db.syncStates);
}

mixin _$SyncLogDaoMixin on DatabaseAccessor<AppDatabase> {
  $SyncLogsTable get syncLogs => attachedDatabase.syncLogs;
  SyncLogDaoManager get managers => SyncLogDaoManager(this);
}

class SyncLogDaoManager {
  final _$SyncLogDaoMixin _db;
  SyncLogDaoManager(this._db);
  $$SyncLogsTableTableManager get syncLogs =>
      $$SyncLogsTableTableManager(_db.attachedDatabase, _db.syncLogs);
}

mixin _$ContactDaoMixin on DatabaseAccessor<AppDatabase> {
  $CachedContactsTable get cachedContacts => attachedDatabase.cachedContacts;
  ContactDaoManager get managers => ContactDaoManager(this);
}

class ContactDaoManager {
  final _$ContactDaoMixin _db;
  ContactDaoManager(this._db);
  $$CachedContactsTableTableManager get cachedContacts =>
      $$CachedContactsTableTableManager(
        _db.attachedDatabase,
        _db.cachedContacts,
      );
}
