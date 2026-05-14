// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_message_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 聊天消息存储器
///
/// 维护所有房间的消息列表（按 roomId 分组），支持消息同步、加载历史、撤回等操作。
/// 采用 keepAlive 模式，确保消息缓存在全局共享。

@ProviderFor(ChatMessages)
const chatMessagesProvider = ChatMessagesProvider._();

/// 聊天消息存储器
///
/// 维护所有房间的消息列表（按 roomId 分组），支持消息同步、加载历史、撤回等操作。
/// 采用 keepAlive 模式，确保消息缓存在全局共享。
final class ChatMessagesProvider
    extends $NotifierProvider<ChatMessages, Map<String, List<ChatMessage>>> {
  /// 聊天消息存储器
  ///
  /// 维护所有房间的消息列表（按 roomId 分组），支持消息同步、加载历史、撤回等操作。
  /// 采用 keepAlive 模式，确保消息缓存在全局共享。
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

String _$chatMessagesHash() => r'a62569ff89633c8c79fa524bb8368900b3e582f2';

/// 聊天消息存储器
///
/// 维护所有房间的消息列表（按 roomId 分组），支持消息同步、加载历史、撤回等操作。
/// 采用 keepAlive 模式，确保消息缓存在全局共享。

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

/// 房间是否还有更多历史消息的状态

@ProviderFor(ChatHasMore)
const chatHasMoreProvider = ChatHasMoreProvider._();

/// 房间是否还有更多历史消息的状态
final class ChatHasMoreProvider
    extends $NotifierProvider<ChatHasMore, Map<String, bool>> {
  /// 房间是否还有更多历史消息的状态
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

String _$chatHasMoreHash() => r'7e088105f09d24fbc40ad81a1b224c7ea48b416f';

/// 房间是否还有更多历史消息的状态

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
