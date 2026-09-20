// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_chat_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// AI 对话控制器（SSE 流式）
///
/// 对接 `POST /chat/ai/stream`，与 `framework/network/sse_client.dart` 协议一致：
/// - thinking 命名事件（`[done]` 哨兵 = 思考结束）
/// - 匿名 data 为正文增量
/// - done / error 终态
/// - 多轮会话通过 `conversationId` 持久化（SharedPreferences per-user）

@ProviderFor(AiChatController)
final aiChatControllerProvider = AiChatControllerProvider._();

/// AI 对话控制器（SSE 流式）
///
/// 对接 `POST /chat/ai/stream`，与 `framework/network/sse_client.dart` 协议一致：
/// - thinking 命名事件（`[done]` 哨兵 = 思考结束）
/// - 匿名 data 为正文增量
/// - done / error 终态
/// - 多轮会话通过 `conversationId` 持久化（SharedPreferences per-user）
final class AiChatControllerProvider
    extends $NotifierProvider<AiChatController, List<AiChatMessage>> {
  /// AI 对话控制器（SSE 流式）
  ///
  /// 对接 `POST /chat/ai/stream`，与 `framework/network/sse_client.dart` 协议一致：
  /// - thinking 命名事件（`[done]` 哨兵 = 思考结束）
  /// - 匿名 data 为正文增量
  /// - done / error 终态
  /// - 多轮会话通过 `conversationId` 持久化（SharedPreferences per-user）
  AiChatControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiChatControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiChatControllerHash();

  @$internal
  @override
  AiChatController create() => AiChatController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<AiChatMessage> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<AiChatMessage>>(value),
    );
  }
}

String _$aiChatControllerHash() => r'901e3c43d90c32e52b34a97400fcc621b4416df8';

/// AI 对话控制器（SSE 流式）
///
/// 对接 `POST /chat/ai/stream`，与 `framework/network/sse_client.dart` 协议一致：
/// - thinking 命名事件（`[done]` 哨兵 = 思考结束）
/// - 匿名 data 为正文增量
/// - done / error 终态
/// - 多轮会话通过 `conversationId` 持久化（SharedPreferences per-user）

abstract class _$AiChatController extends $Notifier<List<AiChatMessage>> {
  List<AiChatMessage> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<AiChatMessage>, List<AiChatMessage>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<AiChatMessage>, List<AiChatMessage>>,
              List<AiChatMessage>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
