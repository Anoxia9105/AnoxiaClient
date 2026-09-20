// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'layout_mode.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 通话布局模式 Provider
///
/// 根据 [RoomState] 中的参与者数量和屏幕共享状态自动计算布局模式。
/// 规则：有屏幕共享 → 焦点模式；其余（含 1v1） → 网格模式。

@ProviderFor(layoutMode)
final layoutModeProvider = LayoutModeFamily._();

/// 通话布局模式 Provider
///
/// 根据 [RoomState] 中的参与者数量和屏幕共享状态自动计算布局模式。
/// 规则：有屏幕共享 → 焦点模式；其余（含 1v1） → 网格模式。

final class LayoutModeProvider
    extends $FunctionalProvider<LayoutMode, LayoutMode, LayoutMode>
    with $Provider<LayoutMode> {
  /// 通话布局模式 Provider
  ///
  /// 根据 [RoomState] 中的参与者数量和屏幕共享状态自动计算布局模式。
  /// 规则：有屏幕共享 → 焦点模式；其余（含 1v1） → 网格模式。
  LayoutModeProvider._({
    required LayoutModeFamily super.from,
    required RoomState super.argument,
  }) : super(
         retry: null,
         name: r'layoutModeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$layoutModeHash();

  @override
  String toString() {
    return r'layoutModeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<LayoutMode> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LayoutMode create(Ref ref) {
    final argument = this.argument as RoomState;
    return layoutMode(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LayoutMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LayoutMode>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LayoutModeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$layoutModeHash() => r'c16aa8be358995e527bc3aba290a4cc85263015f';

/// 通话布局模式 Provider
///
/// 根据 [RoomState] 中的参与者数量和屏幕共享状态自动计算布局模式。
/// 规则：有屏幕共享 → 焦点模式；其余（含 1v1） → 网格模式。

final class LayoutModeFamily extends $Family
    with $FunctionalFamilyOverride<LayoutMode, RoomState> {
  LayoutModeFamily._()
    : super(
        retry: null,
        name: r'layoutModeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 通话布局模式 Provider
  ///
  /// 根据 [RoomState] 中的参与者数量和屏幕共享状态自动计算布局模式。
  /// 规则：有屏幕共享 → 焦点模式；其余（含 1v1） → 网格模式。

  LayoutModeProvider call(RoomState roomState) =>
      LayoutModeProvider._(argument: roomState, from: this);

  @override
  String toString() => r'layoutModeProvider';
}
