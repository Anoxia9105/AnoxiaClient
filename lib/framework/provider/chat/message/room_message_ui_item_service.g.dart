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
///
/// 缓存策略：基于消息列表的引用相等性（identity）做缓存。
/// 当 window 扩大或新消息到达时，消息列表引用会变化，此时全量重算；
/// 当引用未变时，直接返回缓存结果，避免不必要的 O(n) 计算。

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
///
/// 缓存策略：基于消息列表的引用相等性（identity）做缓存。
/// 当 window 扩大或新消息到达时，消息列表引用会变化，此时全量重算；
/// 当引用未变时，直接返回缓存结果，避免不必要的 O(n) 计算。

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
  ///
  /// 缓存策略：基于消息列表的引用相等性（identity）做缓存。
  /// 当 window 扩大或新消息到达时，消息列表引用会变化，此时全量重算；
  /// 当引用未变时，直接返回缓存结果，避免不必要的 O(n) 计算。
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

String _$chatUiListHash() => r'f7aacfef5eb431f64c1c484e802d1d738aff2e9b';

/// 聊天 UI 列表计算服务
///
/// 专门为某个房间计算「时间条 + 消息」混合平铺列表的 ViewProvider。
/// 针对反转列表设计：返回的 List 中 index 0 代表最底部最新的消息。
///
/// 该服务会自动在消息之间插入时间分隔条，规则如下：
/// - 第一条消息前显示时间分隔条
/// - 两条消息时间间隔超过 30 分钟时显示时间分隔条
///
/// 缓存策略：基于消息列表的引用相等性（identity）做缓存。
/// 当 window 扩大或新消息到达时，消息列表引用会变化，此时全量重算；
/// 当引用未变时，直接返回缓存结果，避免不必要的 O(n) 计算。

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
  ///
  /// 缓存策略：基于消息列表的引用相等性（identity）做缓存。
  /// 当 window 扩大或新消息到达时，消息列表引用会变化，此时全量重算；
  /// 当引用未变时，直接返回缓存结果，避免不必要的 O(n) 计算。

  ChatUiListProvider call(String roomId) =>
      ChatUiListProvider._(argument: roomId, from: this);

  @override
  String toString() => r'chatUiListProvider';
}
