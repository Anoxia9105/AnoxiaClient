// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pinned_rooms_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 聊天置顶房间的 Riverpod Provider

@ProviderFor(PinnedRooms)
final pinnedRoomsProvider = PinnedRoomsProvider._();

/// 聊天置顶房间的 Riverpod Provider
final class PinnedRoomsProvider
    extends $NotifierProvider<PinnedRooms, Set<String>> {
  /// 聊天置顶房间的 Riverpod Provider
  PinnedRoomsProvider._()
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

/// 聊天置顶房间的 Riverpod Provider

abstract class _$PinnedRooms extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
