// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_search_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 用户搜索服务
///
/// 支持按用户名/昵称搜索用户，并发送好友申请。

@ProviderFor(UserSearchService)
const userSearchServiceProvider = UserSearchServiceProvider._();

/// 用户搜索服务
///
/// 支持按用户名/昵称搜索用户，并发送好友申请。
final class UserSearchServiceProvider
    extends $NotifierProvider<UserSearchService, UserSearchResponse> {
  /// 用户搜索服务
  ///
  /// 支持按用户名/昵称搜索用户，并发送好友申请。
  const UserSearchServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userSearchServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userSearchServiceHash();

  @$internal
  @override
  UserSearchService create() => UserSearchService();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserSearchResponse value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserSearchResponse>(value),
    );
  }
}

String _$userSearchServiceHash() => r'44dc4d5cd335d4353cd71be28b71a25ff5c4d397';

/// 用户搜索服务
///
/// 支持按用户名/昵称搜索用户，并发送好友申请。

abstract class _$UserSearchService extends $Notifier<UserSearchResponse> {
  UserSearchResponse build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<UserSearchResponse, UserSearchResponse>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UserSearchResponse, UserSearchResponse>,
              UserSearchResponse,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
