// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_event_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 系统事件服务
///
/// 负责全局监听并分发处理 WebSocket 推送的系统事件。
/// 涵盖用户状态变更、房间变动、成员管理、通话状态等。

@ProviderFor(SystemEventService)
const systemEventServiceProvider = SystemEventServiceProvider._();

/// 系统事件服务
///
/// 负责全局监听并分发处理 WebSocket 推送的系统事件。
/// 涵盖用户状态变更、房间变动、成员管理、通话状态等。
final class SystemEventServiceProvider
    extends $NotifierProvider<SystemEventService, void> {
  /// 系统事件服务
  ///
  /// 负责全局监听并分发处理 WebSocket 推送的系统事件。
  /// 涵盖用户状态变更、房间变动、成员管理、通话状态等。
  const SystemEventServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'systemEventServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$systemEventServiceHash();

  @$internal
  @override
  SystemEventService create() => SystemEventService();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$systemEventServiceHash() =>
    r'940098a5df11591cf6fa670a42ec9ef021968546';

/// 系统事件服务
///
/// 负责全局监听并分发处理 WebSocket 推送的系统事件。
/// 涵盖用户状态变更、房间变动、成员管理、通话状态等。

abstract class _$SystemEventService extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
