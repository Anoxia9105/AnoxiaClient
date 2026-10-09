import 'dart:async';

import 'package:anoxia/framework/domain/chat_contact_vo.dart';
import 'package:anoxia/framework/local_cache/cache_providers.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
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
      // 后台增量同步，不阻塞 UI
      unawaited(_syncFromRemote());
      return {for (final c in localContacts) c.contactId!: c};
    }

    // ─── Step 2: 本地无数据（首次），从远端全量拉取 ───────────────────────
    // 检查是否已登录，防止登出过程中因 DB 已清空而再次发起请求导致 401 死循环
    final token = ref.read(tokenCacheProvider);
    if (token == null || token.isEmpty) {
      return {};
    }
    final result = await _syncFromRemote();
    return {for (final c in (result ?? [])) c.contactId!: c};
  }

  /// 从远端拉取联系人并写入本地缓存（自动去重）
  Future<List<ChatContactVO>?> _syncFromRemote() {
    return _syncInflight ??= _doSyncFromRemote().whenComplete(
      () => _syncInflight = null,
    );
  }

  Future<List<ChatContactVO>?> _doSyncFromRemote() async {
    try {
      final contacts = await ref.read(syncContactsUseCaseProvider)();
      return contacts;
    } catch (e) {
      debugLog('[Cache] ContactListService: sync failed: $e');
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
      }
    }
    // 同步写入本地 DB（不 await，非关键路径）
    unawaited(
      ref
          .read(localDataSourceProvider)
          .updateContactOnlineStatus(userId, isOnline),
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
/// 过滤掉当前登录用户自己（不应出现在联系人列表中）。
@Riverpod(keepAlive: true)
Future<Map<String, List<ChatContactVO>>> sortedContactGroups(Ref ref) async {
  final contactsAsync = ref.watch(contactListServiceProvider);
  final contactMap = contactsAsync.value ?? {};
  if (contactMap.isEmpty) return {};

  final currentUser = ref.watch(authControllerProvider).value;
  final currentUserId = currentUser?.userId;

  final List<ChatContactVO> contacts = contactMap.values
      .where((c) => currentUserId == null || c.contactId != currentUserId)
      .toList();

  // 按拼音首字母排序（空备注/空昵称统一回退到 '#'，避免首字母截取越界）
  final sortedList = List<ChatContactVO>.from(contacts)
    ..sort((a, b) {
      String nameA = PinyinHelper.getPinyin(_displayNameOf(a));
      String nameB = PinyinHelper.getPinyin(_displayNameOf(b));
      return nameA.compareTo(nameB);
    });

  // 按首字母分组
  final Map<String, List<ChatContactVO>> groupMap = {};

  for (var contact in sortedList) {
    String displayName = _displayNameOf(contact);
    final firstPinyin = PinyinHelper.getFirstWordPinyin(displayName);
    String tag = firstPinyin.isNotEmpty
        ? firstPinyin.substring(0, 1).toUpperCase()
        : '#';
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

/// 联系人展示名：备注优先，空串与 null 同等对待，一律回退到昵称，兜底 '#'。
///
/// 后端管理员代建的关系备注可能为空串（历史数据），直接 `??` 会拿到空串，
/// 后续拼音首字母 `substring(0, 1)` 越界抛 RangeError，导致整个列表页报错。
String _displayNameOf(ChatContactVO c) {
  if (c.remark?.isNotEmpty == true) return c.remark!;
  if (c.nickName?.isNotEmpty == true) return c.nickName!;
  return '#';
}
