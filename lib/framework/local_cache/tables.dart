import 'package:drift/drift.dart';

@DataClassName('CachedUser')
class CachedUsers extends Table {
  IntColumn get userId => integer()();
  TextColumn get userName => text().withDefault(const Constant(''))();
  TextColumn get nickName => text().withDefault(const Constant(''))();
  TextColumn get email => text().withDefault(const Constant(''))();
  TextColumn get phoneNumber => text().withDefault(const Constant(''))();
  TextColumn get sex => text().withDefault(const Constant('2'))();
  TextColumn get avatar => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId};
}

@DataClassName('CachedConversation')
class Conversations extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().nullable()();
  TextColumn get avatar => text().nullable()();
  TextColumn get description => text().nullable()();
  IntColumn get type => integer().withDefault(const Constant(0))();
  IntColumn get status => integer().withDefault(const Constant(0))();
  IntColumn get peerId =>
      integer().nullable().references(CachedUsers, #userId)();
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();
  IntColumn get lastReadSeq => integer().withDefault(const Constant(0))();
  TextColumn get lastMessageId => text().nullable()();
  TextColumn get lastMessagePreview => text().nullable()();
  IntColumn get lastMessageSeq => integer().nullable()();
  DateTimeColumn get lastMessageAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get cachedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CachedMessage')
class Messages extends Table {
  TextColumn get id => text()();
  TextColumn get clientMsgId => text().nullable().unique()();
  TextColumn get conversationId => text().references(Conversations, #id)();
  IntColumn get senderId =>
      integer().nullable().references(CachedUsers, #userId)();
  IntColumn get messageType => integer().withDefault(const Constant(1))();
  TextColumn get content => text().withDefault(const Constant(''))();
  TextColumn get payloadJson => text().nullable()();
  TextColumn get propertiesJson => text().nullable()();
  TextColumn get deliveryStatus => text().withDefault(const Constant('SENT'))();
  IntColumn get seq => integer().withDefault(const Constant(0))();
  DateTimeColumn get sentAt => dateTime().nullable()();
  DateTimeColumn get localCreatedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SyncState')
class SyncStates extends Table {
  TextColumn get scope => text()();
  TextColumn get scopeId => text().withDefault(const Constant('global'))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  IntColumn get lastSeq => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {scope, scopeId};
}

@DataClassName('SyncLogEntry')
class SyncLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get scope => text()();
  TextColumn get scopeId => text().nullable()();
  TextColumn get action => text()();
  TextColumn get status => text()();
  TextColumn get message => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
}
