// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'input_panel_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 输入面板状态控制器
///
/// 管理聊天输入区域的面板显示状态，协调面板切换与焦点管理

@ProviderFor(InputPanelNotifier)
final inputPanelProvider = InputPanelNotifierProvider._();

/// 输入面板状态控制器
///
/// 管理聊天输入区域的面板显示状态，协调面板切换与焦点管理
final class InputPanelNotifierProvider
    extends $NotifierProvider<InputPanelNotifier, InputPanel> {
  /// 输入面板状态控制器
  ///
  /// 管理聊天输入区域的面板显示状态，协调面板切换与焦点管理
  InputPanelNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inputPanelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inputPanelNotifierHash();

  @$internal
  @override
  InputPanelNotifier create() => InputPanelNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InputPanel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InputPanel>(value),
    );
  }
}

String _$inputPanelNotifierHash() =>
    r'cdb12fb36390728535d7dec89995a68dabbdf6ae';

/// 输入面板状态控制器
///
/// 管理聊天输入区域的面板显示状态，协调面板切换与焦点管理

abstract class _$InputPanelNotifier extends $Notifier<InputPanel> {
  InputPanel build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<InputPanel, InputPanel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<InputPanel, InputPanel>,
              InputPanel,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
