// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_message_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 存储每个房间的消息列表
/// key = roomId, value = List<ChatMessage>

@ProviderFor(ChatMessages)
const chatMessagesProvider = ChatMessagesProvider._();

/// 存储每个房间的消息列表
/// key = roomId, value = List<ChatMessage>
final class ChatMessagesProvider
    extends $NotifierProvider<ChatMessages, Map<String, List<ChatMessage>>> {
  /// 存储每个房间的消息列表
  /// key = roomId, value = List<ChatMessage>
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
  Override overrideWithValue(Map<String, List<ChatMessage>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, List<ChatMessage>>>(
        value,
      ),
    );
  }
}

String _$chatMessagesHash() => r'4952736769b3a235e48ec6825cccebfb63a03218';

/// 存储每个房间的消息列表
/// key = roomId, value = List<ChatMessage>

abstract class _$ChatMessages
    extends $Notifier<Map<String, List<ChatMessage>>> {
  Map<String, List<ChatMessage>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<
              Map<String, List<ChatMessage>>,
              Map<String, List<ChatMessage>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, List<ChatMessage>>,
                Map<String, List<ChatMessage>>
              >,
              Map<String, List<ChatMessage>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
