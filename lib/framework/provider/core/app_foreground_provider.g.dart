// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_foreground_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 桌面窗口可见、聚焦、未最小化且生命周期处于前台时才允许自动已读。

@ProviderFor(AppForeground)
final appForegroundProvider = AppForegroundProvider._();

/// 桌面窗口可见、聚焦、未最小化且生命周期处于前台时才允许自动已读。
final class AppForegroundProvider
    extends $NotifierProvider<AppForeground, bool> {
  /// 桌面窗口可见、聚焦、未最小化且生命周期处于前台时才允许自动已读。
  AppForegroundProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appForegroundProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appForegroundHash();

  @$internal
  @override
  AppForeground create() => AppForeground();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$appForegroundHash() => r'ff11df1036f8239060d89b4fa65e86e86ae508a9';

/// 桌面窗口可见、聚焦、未最小化且生命周期处于前台时才允许自动已读。

abstract class _$AppForeground extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
