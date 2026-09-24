// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_accounts_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 已登录账号列表服务（「切换账号」数据源）
///
/// 账号摘要与各自 token 以 JSON 数组存入 SSUtil（加密存储），
/// 登录成功 / 自动恢复成功时 upsert，切换回该账号时刷新时间戳。
/// 上限 [maxAccounts] 个，超出淘汰最久未用的（LRU）。

@ProviderFor(SavedAccountsService)
final savedAccountsServiceProvider = SavedAccountsServiceProvider._();

/// 已登录账号列表服务（「切换账号」数据源）
///
/// 账号摘要与各自 token 以 JSON 数组存入 SSUtil（加密存储），
/// 登录成功 / 自动恢复成功时 upsert，切换回该账号时刷新时间戳。
/// 上限 [maxAccounts] 个，超出淘汰最久未用的（LRU）。
final class SavedAccountsServiceProvider
    extends $AsyncNotifierProvider<SavedAccountsService, List<SavedAccount>> {
  /// 已登录账号列表服务（「切换账号」数据源）
  ///
  /// 账号摘要与各自 token 以 JSON 数组存入 SSUtil（加密存储），
  /// 登录成功 / 自动恢复成功时 upsert，切换回该账号时刷新时间戳。
  /// 上限 [maxAccounts] 个，超出淘汰最久未用的（LRU）。
  SavedAccountsServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedAccountsServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedAccountsServiceHash();

  @$internal
  @override
  SavedAccountsService create() => SavedAccountsService();
}

String _$savedAccountsServiceHash() =>
    r'755835876cd297a3516027457d52973362c7fab9';

/// 已登录账号列表服务（「切换账号」数据源）
///
/// 账号摘要与各自 token 以 JSON 数组存入 SSUtil（加密存储），
/// 登录成功 / 自动恢复成功时 upsert，切换回该账号时刷新时间戳。
/// 上限 [maxAccounts] 个，超出淘汰最久未用的（LRU）。

abstract class _$SavedAccountsService
    extends $AsyncNotifier<List<SavedAccount>> {
  FutureOr<List<SavedAccount>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<SavedAccount>>, List<SavedAccount>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<SavedAccount>>, List<SavedAccount>>,
              AsyncValue<List<SavedAccount>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 登录页预填账号名
///
/// 切换账号发现 token 过期降级到登录页时写入目标账号名，
/// 登录页消费（预填输入框）后应立即清空，避免影响下次手动登录。
/// keepAlive：写入与消费之间没有监听者，autoDispose 会丢失值。

@ProviderFor(LoginPrefillAccount)
final loginPrefillAccountProvider = LoginPrefillAccountProvider._();

/// 登录页预填账号名
///
/// 切换账号发现 token 过期降级到登录页时写入目标账号名，
/// 登录页消费（预填输入框）后应立即清空，避免影响下次手动登录。
/// keepAlive：写入与消费之间没有监听者，autoDispose 会丢失值。
final class LoginPrefillAccountProvider
    extends $NotifierProvider<LoginPrefillAccount, String?> {
  /// 登录页预填账号名
  ///
  /// 切换账号发现 token 过期降级到登录页时写入目标账号名，
  /// 登录页消费（预填输入框）后应立即清空，避免影响下次手动登录。
  /// keepAlive：写入与消费之间没有监听者，autoDispose 会丢失值。
  LoginPrefillAccountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loginPrefillAccountProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loginPrefillAccountHash();

  @$internal
  @override
  LoginPrefillAccount create() => LoginPrefillAccount();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$loginPrefillAccountHash() =>
    r'5c40844cb9c08d239a4fdf026abd441f205b8c3f';

/// 登录页预填账号名
///
/// 切换账号发现 token 过期降级到登录页时写入目标账号名，
/// 登录页消费（预填输入框）后应立即清空，避免影响下次手动登录。
/// keepAlive：写入与消费之间没有监听者，autoDispose 会丢失值。

abstract class _$LoginPrefillAccount extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
