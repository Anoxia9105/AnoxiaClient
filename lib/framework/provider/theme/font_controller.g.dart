// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'font_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FontController)
const fontControllerProvider = FontControllerProvider._();

final class FontControllerProvider
    extends $NotifierProvider<FontController, String> {
  const FontControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fontControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fontControllerHash();

  @$internal
  @override
  FontController create() => FontController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$fontControllerHash() => r'174590343a92a0dbd3fd7cccbdc1c6b60f04464e';

abstract class _$FontController extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
