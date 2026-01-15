// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_initializer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AppInitializer)
const appInitializerProvider = AppInitializerProvider._();

final class AppInitializerProvider
    extends $AsyncNotifierProvider<AppInitializer, bool> {
  const AppInitializerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appInitializerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appInitializerHash();

  @$internal
  @override
  AppInitializer create() => AppInitializer();
}

String _$appInitializerHash() => r'26b53cc9501d51e0cc910bd9f52bc06d685ba739';

abstract class _$AppInitializer extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
