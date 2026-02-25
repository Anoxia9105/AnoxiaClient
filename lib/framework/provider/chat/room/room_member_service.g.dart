// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_member_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RoomMemberService)
const roomMemberServiceProvider = RoomMemberServiceProvider._();

final class RoomMemberServiceProvider
    extends
        $NotifierProvider<
          RoomMemberService,
          Map<String, List<ChatRoomMemberVO>>
        > {
  const RoomMemberServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roomMemberServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roomMemberServiceHash();

  @$internal
  @override
  RoomMemberService create() => RoomMemberService();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, List<ChatRoomMemberVO>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, List<ChatRoomMemberVO>>>(
        value,
      ),
    );
  }
}

String _$roomMemberServiceHash() => r'5ddda393a4667cbeef94a3b9b0bcc188f91710e5';

abstract class _$RoomMemberService
    extends $Notifier<Map<String, List<ChatRoomMemberVO>>> {
  Map<String, List<ChatRoomMemberVO>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<
              Map<String, List<ChatRoomMemberVO>>,
              Map<String, List<ChatRoomMemberVO>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, List<ChatRoomMemberVO>>,
                Map<String, List<ChatRoomMemberVO>>
              >,
              Map<String, List<ChatRoomMemberVO>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
