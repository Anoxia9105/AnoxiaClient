// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pinned_rooms_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PinnedRooms)
const pinnedRoomsProvider = PinnedRoomsProvider._();

final class PinnedRoomsProvider
    extends $NotifierProvider<PinnedRooms, Set<String>> {
  const PinnedRoomsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pinnedRoomsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pinnedRoomsHash();

  @$internal
  @override
  PinnedRooms create() => PinnedRooms();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$pinnedRoomsHash() => r'318943ab586a3e7c670f652f6b2170310dd25c20';

abstract class _$PinnedRooms extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
