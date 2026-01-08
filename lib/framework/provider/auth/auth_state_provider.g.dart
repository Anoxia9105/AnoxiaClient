// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod 状态管理

@ProviderFor(AuthState)
const authStateProvider = AuthStateProvider._();

/// Riverpod 状态管理
final class AuthStateProvider
    extends $NotifierProvider<AuthState, AuthStateData> {
  /// Riverpod 状态管理
  const AuthStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateHash();

  @$internal
  @override
  AuthState create() => AuthState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthStateData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthStateData>(value),
    );
  }
}

String _$authStateHash() => r'374260f12614dc9d27d5c5c828e201112fda97b4';

/// Riverpod 状态管理

abstract class _$AuthState extends $Notifier<AuthStateData> {
  AuthStateData build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AuthStateData, AuthStateData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AuthStateData, AuthStateData>,
              AuthStateData,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
