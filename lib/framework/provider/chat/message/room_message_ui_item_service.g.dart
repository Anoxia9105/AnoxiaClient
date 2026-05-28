// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_message_ui_item_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 聊天 UI 列表计算服务
///
/// 专门为某个房间计算「时间条 + 消息」混合平铺列表的 ViewProvider。
/// 针对反转列表设计：返回的 List 中 index 0 代表最底部最新的消息。
///
/// 该服务会自动在消息之间插入时间分隔条，规则如下：
/// - 第一条消息前显示时间分隔条
/// - 两条消息时间间隔超过 30 分钟时显示时间分隔条

@ProviderFor(chatUiList)
final chatUiListProvider = ChatUiListFamily._();

/// 聊天 UI 列表计算服务
///
/// 专门为某个房间计算「时间条 + 消息」混合平铺列表的 ViewProvider。
/// 针对反转列表设计：返回的 List 中 index 0 代表最底部最新的消息。
///
/// 该服务会自动在消息之间插入时间分隔条，规则如下：
/// - 第一条消息前显示时间分隔条
/// - 两条消息时间间隔超过 30 分钟时显示时间分隔条

final class ChatUiListProvider
    extends
        $FunctionalProvider<
          ChatUiListResult,
          ChatUiListResult,
          ChatUiListResult
        >
    with $Provider<ChatUiListResult> {
  /// 聊天 UI 列表计算服务
  ///
  /// 专门为某个房间计算「时间条 + 消息」混合平铺列表的 ViewProvider。
  /// 针对反转列表设计：返回的 List 中 index 0 代表最底部最新的消息。
  ///
  /// 该服务会自动在消息之间插入时间分隔条，规则如下：
  /// - 第一条消息前显示时间分隔条
  /// - 两条消息时间间隔超过 30 分钟时显示时间分隔条
  ChatUiListProvider._({
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
  $ProviderElement<ChatUiListResult> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatUiListResult create(Ref ref) {
    final argument = this.argument as String;
    return chatUiList(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatUiListResult value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatUiListResult>(value),
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

String _$chatUiListHash() => r'558243b65b3973247bdae94521e7ef5573d067d6';

/// 聊天 UI 列表计算服务
///
/// 专门为某个房间计算「时间条 + 消息」混合平铺列表的 ViewProvider。
/// 针对反转列表设计：返回的 List 中 index 0 代表最底部最新的消息。
///
/// 该服务会自动在消息之间插入时间分隔条，规则如下：
/// - 第一条消息前显示时间分隔条
/// - 两条消息时间间隔超过 30 分钟时显示时间分隔条

final class ChatUiListFamily extends $Family
    with $FunctionalFamilyOverride<ChatUiListResult, String> {
  ChatUiListFamily._()
    : super(
        retry: null,
        name: r'chatUiListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 聊天 UI 列表计算服务
  ///
  /// 专门为某个房间计算「时间条 + 消息」混合平铺列表的 ViewProvider。
  /// 针对反转列表设计：返回的 List 中 index 0 代表最底部最新的消息。
  ///
  /// 该服务会自动在消息之间插入时间分隔条，规则如下：
  /// - 第一条消息前显示时间分隔条
  /// - 两条消息时间间隔超过 30 分钟时显示时间分隔条

  ChatUiListProvider call(String roomId) =>
      ChatUiListProvider._(argument: roomId, from: this);

  @override
  String toString() => r'chatUiListProvider';
}
