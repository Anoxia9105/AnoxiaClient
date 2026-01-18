// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_event_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 系统事件服务 - 负责全局监听并分发处理逻辑

@ProviderFor(SystemEventService)
const systemEventServiceProvider = SystemEventServiceProvider._();

/// 系统事件服务 - 负责全局监听并分发处理逻辑
final class SystemEventServiceProvider
    extends $NotifierProvider<SystemEventService, void> {
  /// 系统事件服务 - 负责全局监听并分发处理逻辑
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
    r'0068beccb9c1fd26105be65bebb8e6a783e0665a';

/// 系统事件服务 - 负责全局监听并分发处理逻辑

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
