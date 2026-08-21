import 'dart:convert';

import 'package:anoxia/common/constants/storage_keys.dart';
import 'package:anoxia/common/utils/ss_util.dart';
import 'package:anoxia/framework/domain/saved_account.dart';
import 'package:anoxia/framework/domain/user_info.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'saved_accounts_provider.g.dart';

/// 已登录账号列表服务（「切换账号」数据源）
///
/// 账号摘要与各自 token 以 JSON 数组存入 SSUtil（加密存储），
/// 登录成功 / 自动恢复成功时 upsert，切换回该账号时刷新时间戳。
/// 上限 [maxAccounts] 个，超出淘汰最久未用的（LRU）。
@Riverpod(keepAlive: true)
class SavedAccountsService extends _$SavedAccountsService {
  /// 列表容量上限，超出淘汰 lastUsedAt 最旧的条目
  static const int maxAccounts = 5;

  @override
  Future<List<SavedAccount>> build() async => _load();

  /// 从本地存储读取账号列表；损坏数据静默回退为空列表
  Future<List<SavedAccount>> _load() async {
    final raw = await SSUtil.instance.read(key: StorageKeys.savedAccounts);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (item is Map<String, dynamic>)
            SavedAccount.fromJson(item)
          else if (item is Map)
            SavedAccount.fromJson(Map<String, dynamic>.from(item)),
      ]..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    } catch (_) {
      return const [];
    }
  }

  Future<void> _persist(List<SavedAccount> accounts) async {
    await SSUtil.instance.write(
      key: StorageKeys.savedAccounts,
      value: jsonEncode([for (final a in accounts) a.toJson()]),
    );
    state = AsyncData(accounts);
  }

  /// 登录成功 / 自动恢复成功时调用：新增或更新账号条目并置顶
  ///
  /// 同一 userId 已存在时刷新资料与 token；超出上限时淘汰最久未用的。
  Future<void> upsert({required UserInfo user, required String token}) async {
    final accounts = List<SavedAccount>.of(await _load());
    final now = DateTime.now();
    accounts.removeWhere((a) => a.userId == user.userId);
    accounts.insert(
      0,
      SavedAccount(
        userId: user.userId,
        userName: user.userName,
        nickName: user.nickName,
        avatar: user.avatar,
        token: token,
        lastUsedAt: now,
      ),
    );
    while (accounts.length > maxAccounts) {
      accounts.removeLast();
    }
    await _persist(accounts);
  }

  /// 移除指定账号（用户手动移除或 token 失效降级时调用）
  Future<void> remove(int userId) async {
    final accounts = List<SavedAccount>.of(await _load());
    final before = accounts.length;
    accounts.removeWhere((a) => a.userId == userId);
    if (before == accounts.length) return;
    await _persist(accounts);
  }
}

/// 登录页预填账号名
///
/// 切换账号发现 token 过期降级到登录页时写入目标账号名，
/// 登录页消费（预填输入框）后应立即清空，避免影响下次手动登录。
/// keepAlive：写入与消费之间没有监听者，autoDispose 会丢失值。
@Riverpod(keepAlive: true)
class LoginPrefillAccount extends _$LoginPrefillAccount {
  @override
  String? build() => null;

  void set(String? value) {
    state = value;
  }
}
