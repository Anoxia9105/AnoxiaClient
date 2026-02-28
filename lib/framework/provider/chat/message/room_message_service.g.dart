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
        isAutoDispose: false,
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

String _$chatMessagesHash() => r'2306932c054d24dbec2cfd4fdb4148fc61e7c1e2';

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

@ProviderFor(ChatHasMore)
const chatHasMoreProvider = ChatHasMoreProvider._();

final class ChatHasMoreProvider
    extends $NotifierProvider<ChatHasMore, Map<String, bool>> {
  const ChatHasMoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatHasMoreProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatHasMoreHash();

  @$internal
  @override
  ChatHasMore create() => ChatHasMore();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, bool> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, bool>>(value),
    );
  }
}

String _$chatHasMoreHash() => r'9aa732270e60538a0dd1d925aee1ad1e26b78097';

abstract class _$ChatHasMore extends $Notifier<Map<String, bool>> {
  Map<String, bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<Map<String, bool>, Map<String, bool>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, bool>, Map<String, bool>>,
              Map<String, bool>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
