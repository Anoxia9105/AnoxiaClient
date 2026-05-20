// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_message_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 系统信令消息监听服务
///
/// 专门拦截 RoomMessage 中的 system 类型，处理通话挂断、禁言、解散、通知等衍生旁路业务

@ProviderFor(SystemMessageService)
const systemMessageServiceProvider = SystemMessageServiceProvider._();

/// 系统信令消息监听服务
///
/// 专门拦截 RoomMessage 中的 system 类型，处理通话挂断、禁言、解散、通知等衍生旁路业务
final class SystemMessageServiceProvider
    extends $NotifierProvider<SystemMessageService, void> {
  /// 系统信令消息监听服务
  ///
  /// 专门拦截 RoomMessage 中的 system 类型，处理通话挂断、禁言、解散、通知等衍生旁路业务
  const SystemMessageServiceProvider._()
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
/// 专门拦截 RoomMessage 中的 system 类型，处理通话挂断、禁言、解散、通知等衍生旁路业务

abstract class _$SystemMessageService extends $Notifier<void> {
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
