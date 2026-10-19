// AI 消息工具（P0-3）：翻译 + 未读一键总结。
//
// 数据链：
// - SSE 复用 `aiRepositoryProvider.askStream`（`/chat/ai/stream`），协议与
//   `ai_chat_controller` 同款；prompt 由客户端组（`ai_prompt_builder.dart`）。
// - 翻译：按消息 family（key = `messageId|targetLang`，内存即缓存，同一
//   消息反复打开面板不重复请求）；autoDispose，会话切换不驻留。
// - 总结：按房间 family；本地 drift `seq > lastReadSeq` 的文本消息拼
//   prompt（媒体只进统计），并记录最早未读消息 ID 供「跳到最早未读」。
// - 状态推进抽成 [foldAiToolEvent] 纯函数便于单测；查询/流失败都降级为
//   错误态或空结果，不抛错；notifier 被 autoDispose 销毁后迟到的流事件
//   静默丢弃（onDispose 禁止 ref.read，销毁检测靠 catch 兜底）。
// - 终态（done/error）上报上游健康（reportSuccess/reportFailure），
//   与聊天 AI 入口的熔断共用同一阀。
import 'dart:async';

import 'package:anoxia/domain/ai_stream_event.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/local_cache/cache_providers.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:anoxia/framework/provider/ai/ai_feature_flags_provider.dart';
import 'package:anoxia/framework/provider/chat/message/ai_prompt_builder.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/core/ai_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ai_message_tools_provider.g.dart';

/// 翻译 / 总结共用的展示状态
class AiToolState {
  const AiToolState({
    this.text,
    this.streaming = false,
    this.error,
    this.firstUnreadMessageId,
    this.isEmptyResult = false,
  });

  /// AI 全文（null = 尚未产生内容）
  final String? text;

  /// SSE 流式输出中
  final bool streaming;

  /// 失败文案（AiException 的 message 或通用兜底 key）
  final String? error;

  /// 未读总结场景：待跳转的最早未读消息 ID
  final String? firstUnreadMessageId;

  /// 任务正常完成但没有可输出的内容（空结果不算失败）
  final bool isEmptyResult;

  bool get hasContent => text != null && text!.isNotEmpty;
}

/// SSE 事件 → 状态推进（纯函数，top-level 供测试）
AiToolState foldAiToolEvent(AiToolState state, AiStreamEvent event) {
  switch (event) {
    case AiThinking():
      // 翻译/总结不展示思考过程；哨兵仅代表思考结束，不影响流态
      break;
    case AiDelta(:final text):
      if (!state.streaming) break; // done 已收，忽略迟到增量
      state = AiToolState(
        text: (state.text ?? '') + text,
        streaming: true,
        firstUnreadMessageId: state.firstUnreadMessageId,
      );
    case AiDone(:final text):
      // 服务端权威全文兜底：增量为空用 done.text
      final resolved = (state.text == null || state.text!.isEmpty)
          ? text
          : state.text!;
      state = AiToolState(
        text: resolved.isEmpty ? null : resolved,
        streaming: false,
        isEmptyResult: resolved.isEmpty,
        firstUnreadMessageId: state.firstUnreadMessageId,
      );
  }
  return state;
}

/// 翻译控制器：key = `messageId|targetLang`（按消息 family，内存即缓存）
@riverpod
class AiTranslateController extends _$AiTranslateController {
  @override
  AiToolState build(String key) => const AiToolState();

  /// 发起翻译（失败可重试：会覆盖旧错误态重新跑一遍流）
  Future<void> translate(String text, {required String language}) async {
    if (state.streaming) return;
    final prompt = buildTranslatePrompt(text, language: language);
    await runAiToolPrompt(
      ref: ref,
      onState: (next) => state = next,
      prompt: prompt,
      failureFallbackKey: 'chat_ai.translate_failed',
    );
  }
}

/// 未读总结控制器：按房间 family（一次生成缓存，重开弹层不重拉）
@riverpod
class AiUnreadSummaryController extends _$AiUnreadSummaryController {
  @override
  AiToolState build(String roomId) => const AiToolState();

  /// 生成未读总结。[language] 由 UI 按当前 locale 传（provider 不依赖
  /// easy_localization）。
  Future<void> summarize({required String language}) async {
    if (state.streaming || state.hasContent) return;

    // 未读水位取当前房间快照（进入会话时 room 列表已刷新）
    final room = ref.read(currentRoomProvider(roomId));
    final afterSeq = room?.lastReadSeq ?? 0;

    // 防御性契约：本地查询失败降级空结果，不抛错
    List<ChatMessage> messages = const [];
    try {
      messages = await ref
          .read(localDataSourceProvider)
          .getUnreadTextMessages(roomId, afterSeq: afterSeq);
    } catch (e, st) {
      debugLog('[AiTools] 未读文本查询失败: $e', e, st);
    }

    final firstUnreadId = messages.isNotEmpty
        ? messages.first.messageId
        : null;
    final draft = collectUnreadSummaryDraft(messages);
    if (draft.isEmpty) {
      state = AiToolState(
        isEmptyResult: true,
        firstUnreadMessageId: firstUnreadId,
      );
      return;
    }

    final prompt = buildUnreadSummaryPrompt(draft, language: language);
    await runAiToolPrompt(
      ref: ref,
      onState: (next) => state = next,
      prompt: prompt,
      failureFallbackKey: 'chat_ai.summary_failed',
      initialState: AiToolState(
        streaming: true,
        firstUnreadMessageId: firstUnreadId,
      ),
    );
  }

  /// 显式复位（弹层关闭后允许重新拉取）
  void reset() => state = const AiToolState();
}

/// 翻译与总结共用的流式执行体。
///
/// 语义：
/// - 收到 `AiDone` → `fold` 已落终态（有内容 / 空结果都算上游健康）；
/// - 流自然结束但没有 done（断流）→ 兜底错误态 + reportFailure；
/// - `AiException` / 其它异常 → 错误态 + reportFailure；
/// - notifier 已销毁（autoDispose 竞态）时 state 写不进去，静默终止。
Future<void> runAiToolPrompt({
  required Ref ref,
  required void Function(AiToolState state) onState,
  required String prompt,
  required String failureFallbackKey,
  AiToolState initialState = const AiToolState(streaming: true),
}) async {
  AiToolState current = initialState;
  void safeSet(AiToolState next) {
    current = next;
    try {
      onState(next);
    } catch (_) {
      // notifier 已销毁：不再写 state，流继续消费完（避免悬挂请求）
    }
  }

  // 单次任务只上报一次上游健康
  var healthReported = false;
  void reportHealth(bool success) {
    if (healthReported) return;
    healthReported = true;
    try {
      final notifier = ref.read(aiFeatureFlagsProvider.notifier);
      success ? notifier.reportSuccess() : notifier.reportFailure();
    } catch (_) {}
  }

  safeSet(current);
  try {
    final stream = ref.read(aiRepositoryProvider).askStream(prompt);
    await for (final event in stream) {
      safeSet(foldAiToolEvent(current, event));
      if (!current.streaming) {
        // done 终态：有内容 / 空结果都算上游正常响应
        reportHealth(current.hasContent || current.isEmptyResult);
        return;
      }
    }
    // 断流兜底：流结束但从未收到 done —— 无论是否有内容都要清除
    // streaming，否则面板会停在转圈态（无 done 时无后续事件了）。
    if (current.streaming) {
      if (current.hasContent) {
        // 有增量但没等来 done：内容可用，正常收口
        safeSet(
          AiToolState(
            text: current.text,
            firstUnreadMessageId: current.firstUnreadMessageId,
          ),
        );
        reportHealth(true);
        return;
      }
      safeSet(
        AiToolState(
          error: failureFallbackKey,
          firstUnreadMessageId: current.firstUnreadMessageId,
        ),
      );
      reportHealth(false);
      return;
    }
  } on AiException catch (e, st) {
    debugLog('[AiTools] 流式失败: $e', e, st);
    final message = e.message.isEmpty ? failureFallbackKey : e.message;
    safeSet(
      AiToolState(
        error: message,
        firstUnreadMessageId: current.firstUnreadMessageId,
      ),
    );
    reportHealth(false);
  } catch (e, st) {
    debugLog('[AiTools] 流式异常: $e', e, st);
    safeSet(
      AiToolState(
        error: failureFallbackKey,
        firstUnreadMessageId: current.firstUnreadMessageId,
      ),
    );
    reportHealth(false);
  }
}
