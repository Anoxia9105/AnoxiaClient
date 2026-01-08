// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_message_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ChatMessages)
const chatMessagesProvider = ChatMessagesProvider._();

final class ChatMessagesProvider
    extends $NotifierProvider<ChatMessages, Map<String, List<RoomMessage>>> {
  const ChatMessagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatMessagesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatMessagesHash();

  @$internal
  @override
  ChatMessages create() => ChatMessages();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, List<RoomMessage>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, List<RoomMessage>>>(
        value,
      ),
    );
  }
}

String _$chatMessagesHash() => r'f67c3fe7de0cb064a065e77d7f35db634815da4c';

abstract class _$ChatMessages
    extends $Notifier<Map<String, List<RoomMessage>>> {
  Map<String, List<RoomMessage>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<
              Map<String, List<RoomMessage>>,
              Map<String, List<RoomMessage>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, List<RoomMessage>>,
                Map<String, List<RoomMessage>>
              >,
              Map<String, List<RoomMessage>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
