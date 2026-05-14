// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_chat_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// AI 对话控制器
///
/// 管理 AI 聊天的消息列表和请求状态。
/// 支持发送用户消息并获取 AI 回复。

@ProviderFor(AiChatController)
const aiChatControllerProvider = AiChatControllerProvider._();

/// AI 对话控制器
///
/// 管理 AI 聊天的消息列表和请求状态。
/// 支持发送用户消息并获取 AI 回复。
final class AiChatControllerProvider
    extends $NotifierProvider<AiChatController, List<AiChatMessage>> {
  /// AI 对话控制器
  ///
  /// 管理 AI 聊天的消息列表和请求状态。
  /// 支持发送用户消息并获取 AI 回复。
  const AiChatControllerProvider._()
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

String _$aiChatControllerHash() => r'790b013da2382234e5d86d6cdf7626e70195f2ea';

/// AI 对话控制器
///
/// 管理 AI 聊天的消息列表和请求状态。
/// 支持发送用户消息并获取 AI 回复。

abstract class _$AiChatController extends $Notifier<List<AiChatMessage>> {
  List<AiChatMessage> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<List<AiChatMessage>, List<AiChatMessage>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<AiChatMessage>, List<AiChatMessage>>,
              List<AiChatMessage>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
