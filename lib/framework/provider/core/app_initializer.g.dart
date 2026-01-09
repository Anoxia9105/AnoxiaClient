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
    extends $AsyncNotifierProvider<AppInitializer, void> {
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

String _$appInitializerHash() => r'8f7a5a2629f7273f68c410eea76e786b93115977';

abstract class _$AppInitializer extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
