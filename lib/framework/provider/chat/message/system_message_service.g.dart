// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_message_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 系统信令消息监听服务
///
/// 专门拦截 [RoomMessage] 中的 system 类型消息，处理以下衍生旁路业务：
/// - 通话状态变更（开始/结束）
/// - 房间状态变更（禁言/解禁/解散）
/// - 桌面通知推送
///
/// 该服务使用 keepAlive 保持常驻，确保持续监听系统消息

@ProviderFor(SystemMessageService)
final systemMessageServiceProvider = SystemMessageServiceProvider._();

/// 系统信令消息监听服务
///
/// 专门拦截 [RoomMessage] 中的 system 类型消息，处理以下衍生旁路业务：
/// - 通话状态变更（开始/结束）
/// - 房间状态变更（禁言/解禁/解散）
/// - 桌面通知推送
///
/// 该服务使用 keepAlive 保持常驻，确保持续监听系统消息
final class SystemMessageServiceProvider
    extends $NotifierProvider<SystemMessageService, void> {
  /// 系统信令消息监听服务
  ///
  /// 专门拦截 [RoomMessage] 中的 system 类型消息，处理以下衍生旁路业务：
  /// - 通话状态变更（开始/结束）
  /// - 房间状态变更（禁言/解禁/解散）
  /// - 桌面通知推送
  ///
  /// 该服务使用 keepAlive 保持常驻，确保持续监听系统消息
  SystemMessageServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'systemMessageServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$systemMessageServiceHash();

  @$internal
  @override
  SystemMessageService create() => SystemMessageService();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$systemMessageServiceHash() =>
    r'6bcbe5f80ba95cdde2c78eeae35a08875b4a5294';

/// 系统信令消息监听服务
///
/// 专门拦截 [RoomMessage] 中的 system 类型消息，处理以下衍生旁路业务：
/// - 通话状态变更（开始/结束）
/// - 房间状态变更（禁言/解禁/解散）
/// - 桌面通知推送
///
/// 该服务使用 keepAlive 保持常驻，确保持续监听系统消息

abstract class _$SystemMessageService extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
