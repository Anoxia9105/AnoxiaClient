// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_message_ui_item_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 专门为某个房间计算 [时间条 + 消息] 混合平铺列表的 ViewProvider

@ProviderFor(chatUiList)
const chatUiListProvider = ChatUiListFamily._();

/// 专门为某个房间计算 [时间条 + 消息] 混合平铺列表的 ViewProvider

final class ChatUiListProvider
    extends
        $FunctionalProvider<
          List<ChatListItem>,
          List<ChatListItem>,
          List<ChatListItem>
        >
    with $Provider<List<ChatListItem>> {
  /// 专门为某个房间计算 [时间条 + 消息] 混合平铺列表的 ViewProvider
  const ChatUiListProvider._({
    required ChatUiListFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'chatUiListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatUiListHash();

  @override
  String toString() {
    return r'chatUiListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<ChatListItem>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<ChatListItem> create(Ref ref) {
    final argument = this.argument as String;
    return chatUiList(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ChatListItem> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ChatListItem>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChatUiListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatUiListHash() => r'cd86641591f9df72e1486b09c4a9ffc923c5b2b5';

/// 专门为某个房间计算 [时间条 + 消息] 混合平铺列表的 ViewProvider

final class ChatUiListFamily extends $Family
    with $FunctionalFamilyOverride<List<ChatListItem>, String> {
  const ChatUiListFamily._()
    : super(
        retry: null,
        name: r'chatUiListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 专门为某个房间计算 [时间条 + 消息] 混合平铺列表的 ViewProvider

  ChatUiListProvider call(String roomId) =>
      ChatUiListProvider._(argument: roomId, from: this);

  @override
  String toString() => r'chatUiListProvider';
}
