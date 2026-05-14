// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 主题索引 Provider
///
/// 持久化存储用户选择的主题索引（0=浅色，1=深色等）。

@ProviderFor(ThemeIndex)
const themeIndexProvider = ThemeIndexProvider._();

/// 主题索引 Provider
///
/// 持久化存储用户选择的主题索引（0=浅色，1=深色等）。
final class ThemeIndexProvider extends $NotifierProvider<ThemeIndex, int> {
  /// 主题索引 Provider
  ///
  /// 持久化存储用户选择的主题索引（0=浅色，1=深色等）。
  const ThemeIndexProvider._()
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
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// 应用主题 Provider
///
/// 根据 [ThemeIndex] 动态生成对应的 ThemeData

@ProviderFor(appTheme)
const appThemeProvider = AppThemeProvider._();

/// 应用主题 Provider
///
/// 根据 [ThemeIndex] 动态生成对应的 ThemeData

final class AppThemeProvider
    extends $FunctionalProvider<ThemeData, ThemeData, ThemeData>
    with $Provider<ThemeData> {
  /// 应用主题 Provider
  ///
  /// 根据 [ThemeIndex] 动态生成对应的 ThemeData
  const AppThemeProvider._()
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

String _$appThemeHash() => r'7d0e8abc7c6b12ddb24d943eea80b94b8bb2aeae';
