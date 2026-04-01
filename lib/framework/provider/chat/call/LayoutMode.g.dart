// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'LayoutMode.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(layoutMode)
const layoutModeProvider = LayoutModeFamily._();

final class LayoutModeProvider
    extends $FunctionalProvider<LayoutMode, LayoutMode, LayoutMode>
    with $Provider<LayoutMode> {
  const LayoutModeProvider._({
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

String _$layoutModeHash() => r'50f4baa4e1f6e14d38982aa4a7bdc667d600f3c7';

final class LayoutModeFamily extends $Family
    with $FunctionalFamilyOverride<LayoutMode, RoomState> {
  const LayoutModeFamily._()
    : super(
        retry: null,
        name: r'layoutModeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LayoutModeProvider call(RoomState roomState) =>
      LayoutModeProvider._(argument: roomState, from: this);

  @override
  String toString() => r'layoutModeProvider';
}
