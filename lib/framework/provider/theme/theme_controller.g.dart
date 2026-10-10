// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 监听系统外观变化，避免只在启动时读取一次亮度。

@ProviderFor(SystemBrightness)
final systemBrightnessProvider = SystemBrightnessProvider._();

/// 监听系统外观变化，避免只在启动时读取一次亮度。
final class SystemBrightnessProvider
    extends $NotifierProvider<SystemBrightness, Brightness> {
  /// 监听系统外观变化，避免只在启动时读取一次亮度。
  SystemBrightnessProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'systemBrightnessProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$systemBrightnessHash();

  @$internal
  @override
  SystemBrightness create() => SystemBrightness();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Brightness value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Brightness>(value),
    );
  }
}

String _$systemBrightnessHash() => r'708805857f48dc137fe8354b247f308c63754f56';

/// 监听系统外观变化，避免只在启动时读取一次亮度。

abstract class _$SystemBrightness extends $Notifier<Brightness> {
  Brightness build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Brightness, Brightness>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Brightness, Brightness>,
              Brightness,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 实际渲染亮度；用户选择与系统解析结果分开保存。

@ProviderFor(effectiveBrightness)
final effectiveBrightnessProvider = EffectiveBrightnessProvider._();

/// 实际渲染亮度；用户选择与系统解析结果分开保存。

final class EffectiveBrightnessProvider
    extends $FunctionalProvider<Brightness, Brightness, Brightness>
    with $Provider<Brightness> {
  /// 实际渲染亮度；用户选择与系统解析结果分开保存。
  EffectiveBrightnessProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'effectiveBrightnessProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$effectiveBrightnessHash();

  @$internal
  @override
  $ProviderElement<Brightness> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Brightness create(Ref ref) {
    return effectiveBrightness(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Brightness value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Brightness>(value),
    );
  }
}

String _$effectiveBrightnessHash() =>
    r'65621ab804126d6b6bada0f0fcbebe7a969ef596';

/// 主题索引 Provider
///
/// 持久化存储用户选择的主题索引（0=浅色，1=深色等）。

@ProviderFor(ThemeIndex)
final themeIndexProvider = ThemeIndexProvider._();

/// 主题索引 Provider
///
/// 持久化存储用户选择的主题索引（0=浅色，1=深色等）。
final class ThemeIndexProvider extends $NotifierProvider<ThemeIndex, int> {
  /// 主题索引 Provider
  ///
  /// 持久化存储用户选择的主题索引（0=浅色，1=深色等）。
  ThemeIndexProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeIndexProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeIndexHash();

  @$internal
  @override
  ThemeIndex create() => ThemeIndex();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$themeIndexHash() => r'91d573d8dda1ecdf9caeefa57fa88c28b94f8dbc';

/// 主题索引 Provider
///
/// 持久化存储用户选择的主题索引（0=浅色，1=深色等）。

abstract class _$ThemeIndex extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 应用主题 Provider
///
/// 固定字体：JetBrainsMono（拉丁/等宽）+ NotoSansSC（CJK 回退），全平台（含 Web）强制使用
/// 若存在自定义强调色则优先使用。

@ProviderFor(appTheme)
final appThemeProvider = AppThemeProvider._();

/// 应用主题 Provider
///
/// 固定字体：JetBrainsMono（拉丁/等宽）+ NotoSansSC（CJK 回退），全平台（含 Web）强制使用
/// 若存在自定义强调色则优先使用。

final class AppThemeProvider
    extends $FunctionalProvider<ThemeData, ThemeData, ThemeData>
    with $Provider<ThemeData> {
  /// 应用主题 Provider
  ///
  /// 固定字体：JetBrainsMono（拉丁/等宽）+ NotoSansSC（CJK 回退），全平台（含 Web）强制使用
  /// 若存在自定义强调色则优先使用。
  AppThemeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appThemeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appThemeHash();

  @$internal
  @override
  $ProviderElement<ThemeData> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ThemeData create(Ref ref) {
    return appTheme(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeData>(value),
    );
  }
}

String _$appThemeHash() => r'6934ea1d58f71d9ea365c58f8f1bd1510c27e7f1';
