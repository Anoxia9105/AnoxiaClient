import 'dart:async';

import 'package:anoxia/framework/domain/chat_contact_vo.dart';
import 'package:anoxia/framework/local_cache/cache_providers.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/framework/provider/core/sync_contacts_usecase_provider.dart';
import 'package:anoxia/framework/provider/auth/token_provider.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'contact_list_controller.g.dart';

/// 联系人列表服务
///
/// 维护联系人数据的 Map 结构（contactId -> ChatContactVO），
/// 支持在线状态更新和拼音排序分组。
///
/// 采用 keepAlive 模式，确保联系人缓存在全局共享。
@Riverpod(keepAlive: true)
class ContactListService extends _$ContactListService {
  /// 正在进行的远端同步 Future，避免并发重复请求
  Future<List<ChatContactVO>?>? _syncInflight;

  @override
  FutureOr<Map<int, ChatContactVO>> build() async {
    final local = ref.read(localDataSourceProvider);

    // 订阅本地 DB 流，DB 写入后自动推送更新到 UI
    final subscription = local.watchContacts().listen((contacts) {
      state = AsyncData({for (final c in contacts) c.contactId!: c});
    });
    ref.onDispose(subscription.cancel);

    // ─── Step 1: 优先读本地缓存，立即渲染 ────────────────────────────────
    final localContacts = await local.getContacts();
    if (localContacts.isNotEmpty) {
      log.debug('[Cache] ContactListService: local hit count=${localContacts.length}');
      // 后台增量同步，不阻塞 UI
      unawaited(_syncFromRemote());
      return {for (final c in localContacts) c.contactId!: c};
    }

    // ─── Step 2: 本地无数据（首次），从远端全量拉取 ───────────────────────
    // 检查是否已登录，防止登出过程中因 DB 已清空而再次发起请求导致 401 死循环
    final token = ref.read(tokenCacheProvider);
    if (token == null || token.isEmpty) {
      log.debug('[Cache] ContactListService: no token, skip remote fetch');
      return {};
    }
    log.debug('[Cache] ContactListService: local empty, fetch from remote');
    final result = await _syncFromRemote();
    return {for (final c in (result ?? [])) c.contactId!: c};
  }

  /// 从远端拉取联系人并写入本地缓存（自动去重）
  Future<List<ChatContactVO>?> _syncFromRemote() {
    return _syncInflight ??=
        _doSyncFromRemote().whenComplete(() => _syncInflight = null);
  }

  Future<List<ChatContactVO>?> _doSyncFromRemote() async {
    try {
      final contacts = await ref.read(syncContactsUseCaseProvider)();
      await ref.read(localDataSourceProvider).upsertContacts(contacts);
      log.debug('[Cache] ContactListService: synced ${contacts.length} contacts');
      return contacts;
    } catch (e) {
      log.error('[Cache] ContactListService: sync failed: $e');
      return null;
    }
  }

  /// 局部更新联系人的在线状态
  ///
  /// 由 WebSocket 在线状态推送触发，同时更新内存和本地 DB
  void updateOnlineStatus(int userId, bool isOnline) {
    final currentAsync = state;
    if (currentAsync is AsyncData<Map<int, ChatContactVO>>) {
      final contactMap = currentAsync.value;
      if (contactMap.containsKey(userId)) {
        final updatedContact = contactMap[userId]!.copyWith(
          onlineStatus: isOnline,
        );
        state = AsyncData({...contactMap, userId: updatedContact});
        log.info("👤 联系人 $userId 状态同步: ${isOnline ? '在线' : '离线'}");
      }
    }
    // 同步写入本地 DB（不 await，非关键路径）
    unawaited(
      ref.read(localDataSourceProvider).updateContactOnlineStatus(userId, isOnline),
    );
  }

  /// 刷新联系人列表（强制从远端拉取）
  Future<void> refresh({bool quiet = false}) async {
    if (!quiet) state = const AsyncValue.loading();
    final result = await _syncFromRemote();
    if (result != null) {
      state = AsyncData({for (final c in result) c.contactId!: c});
    }
  }

  /// 删除联系人（解除好友后调用，同步更新内存和本地 DB）
  Future<void> removeContact(int contactId) async {
    await ref.read(localDataSourceProvider).deleteContact(contactId);
    state.whenData((map) {
      final updated = Map<int, ChatContactVO>.from(map)..remove(contactId);
      state = AsyncData(updated);
    });
  }
}

/// 联系人拼音排序分组
///
/// 按联系人昵称/备注的首字母进行 A-Z 分组，
/// 中文姓名自动转换为拼音后取首字母。
@Riverpod(keepAlive: true)
Future<Map<String, List<ChatContactVO>>> sortedContactGroups(Ref ref) async {
  final contactsAsync = ref.watch(contactListServiceProvider);
  final contactMap = contactsAsync.value ?? {};
  if (contactMap.isEmpty) return {};

  final List<ChatContactVO> contacts = contactMap.values.toList();

  // 按拼音首字母排序
  final sortedList = List<ChatContactVO>.from(contacts)
    ..sort((a, b) {
      String nameA = PinyinHelper.getPinyin(a.remark ?? a.nickName ?? '#');
      String nameB = PinyinHelper.getPinyin(b.remark ?? b.nickName ?? '#');
      return nameA.compareTo(nameB);
    });

  // 按首字母分组
  final Map<String, List<ChatContactVO>> groupMap = {};

  for (var contact in sortedList) {
    String displayName = contact.remark ?? contact.nickName ?? '#';
    String tag = PinyinHelper.getFirstWordPinyin(
      displayName,
    ).substring(0, 1).toUpperCase();
    if (!RegExp(r'[A-Z]').hasMatch(tag)) tag = '#';
    groupMap.putIfAbsent(tag, () => []).add(contact);
  }

  // 排序分组键（# 组排在最后）
  final sortedKeys = groupMap.keys.toList()
    ..sort((a, b) {
      if (a == '#') return 1;
      if (b == '#') return -1;
      return a.compareTo(b);
    });

  return {for (var k in sortedKeys) k: groupMap[k]!};
}
