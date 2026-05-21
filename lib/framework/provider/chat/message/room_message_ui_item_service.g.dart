// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_message_ui_item_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 专门为某个房间计算 [时间条 + 消息] 混合平铺列表的 ViewProvider
/// 针对反转列表设计：返回的 List 中 index 0 代表最底部最新的消息

@ProviderFor(chatUiList)
const chatUiListProvider = ChatUiListFamily._();

/// 专门为某个房间计算 [时间条 + 消息] 混合平铺列表的 ViewProvider
/// 针对反转列表设计：返回的 List 中 index 0 代表最底部最新的消息

final class ChatUiListProvider
    extends
        $FunctionalProvider<
          List<ChatListItem>,
          List<ChatListItem>,
          List<ChatListItem>
        >
    with $Provider<List<ChatListItem>> {
  /// 专门为某个房间计算 [时间条 + 消息] 混合平铺列表的 ViewProvider
  /// 针对反转列表设计：返回的 List 中 index 0 代表最底部最新的消息
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

String _$chatUiListHash() => r'8da3772c757aec55d0e95ec64bd1d1090543819c';

/// 专门为某个房间计算 [时间条 + 消息] 混合平铺列表的 ViewProvider
/// 针对反转列表设计：返回的 List 中 index 0 代表最底部最新的消息

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
  /// 针对反转列表设计：返回的 List 中 index 0 代表最底部最新的消息

  ChatUiListProvider call(String roomId) =>
      ChatUiListProvider._(argument: roomId, from: this);

  @override
  String toString() => r'chatUiListProvider';
}
