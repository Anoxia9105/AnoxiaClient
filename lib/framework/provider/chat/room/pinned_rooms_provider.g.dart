// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pinned_rooms_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 聊天置顶房间的 Riverpod Provider
///
/// 数据策略：服务端为真源（会话列表携带 isPinned 时由 [reconcileFromServer]
/// 覆盖本地），本地 SP 存储作为旧部署兜底与乐观回显；切换时先本地生效再异步
/// 推送，推送失败回滚本地并提示。

@ProviderFor(PinnedRooms)
final pinnedRoomsProvider = PinnedRoomsProvider._();

/// 聊天置顶房间的 Riverpod Provider
///
/// 数据策略：服务端为真源（会话列表携带 isPinned 时由 [reconcileFromServer]
/// 覆盖本地），本地 SP 存储作为旧部署兜底与乐观回显；切换时先本地生效再异步
/// 推送，推送失败回滚本地并提示。
final class PinnedRoomsProvider
    extends $NotifierProvider<PinnedRooms, Set<String>> {
  /// 聊天置顶房间的 Riverpod Provider
  ///
  /// 数据策略：服务端为真源（会话列表携带 isPinned 时由 [reconcileFromServer]
  /// 覆盖本地），本地 SP 存储作为旧部署兜底与乐观回显；切换时先本地生效再异步
  /// 推送，推送失败回滚本地并提示。
  PinnedRoomsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pinnedRoomsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pinnedRoomsHash();

  @$internal
  @override
  PinnedRooms create() => PinnedRooms();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$pinnedRoomsHash() => r'a5439970dd41dd9fdf6742689d6f9988a83deb5d';

/// 聊天置顶房间的 Riverpod Provider
///
/// 数据策略：服务端为真源（会话列表携带 isPinned 时由 [reconcileFromServer]
/// 覆盖本地），本地 SP 存储作为旧部署兜底与乐观回显；切换时先本地生效再异步
/// 推送，推送失败回滚本地并提示。

abstract class _$PinnedRooms extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
