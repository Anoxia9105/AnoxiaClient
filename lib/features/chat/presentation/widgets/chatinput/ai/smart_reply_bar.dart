/// 智能回复建议条（双端通用，手动触发）
///
/// 输入区上方的一行轻量入口：
/// - 收起态：单个「✨ 智能回复」胶囊按钮
/// - 点击后基于最近多轮对话生成 3 条有具体内容的回复建议
/// - 点击 chip 填入输入框可编辑后发送（不直发，符合安全惯例）
/// - 按 (roomId, lastMessageId) 缓存结果；换消息自动失效
///
/// 配额友好：仅手动触发，不自动请求。
library;

import 'dart:async';
import 'dart:convert';
import 'package:anoxia/domain/ai_reply_result.dart';
import 'package:anoxia/framework/provider/chat/message/ai_context_loader.dart';
import 'package:anoxia/framework/local_cache/cache_providers.dart';

import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/provider/ai/ai_feature_flags_provider.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/chat/message/ai_prompt_builder.dart';
import 'package:anoxia/framework/provider/chat/input/reply_target_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'chat_ai_assist_core.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

class SmartReplyBar extends ConsumerStatefulWidget {
  const SmartReplyBar({
    super.key,
    required this.roomId,
    required this.onPick,
    required this.draftListenable,
    required this.readDraft,
    this.core,
    this.historyReader,
  });

  final String roomId;

  /// 选中建议后的回填回调（由各端注入各自的输入写入实现）
  final ValueChanged<String> onPick;
  final Listenable draftListenable;
  final String Function() readDraft;
  final ChatAiAssistCore? core;
  final ChatAiHistoryReader? historyReader;

  @override
  ConsumerState<SmartReplyBar> createState() => _SmartReplyBarState();
}

class _SmartReplyBarState extends ConsumerState<SmartReplyBar> {
  /// 会话级缓存：房间、语言及完整上下文 → 建议列表。
  final Map<String, List<String>> _cache = {};

  ChatAiAssistCore? _core;
  bool _expanded = false;
  bool _loading = false;
  List<String>? _suggestions;
  String? _generatedForMessageId;
  List<ChatMessage> _history = const [];
  int _requestEpoch = 0;

  ColorScheme get _cs => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    widget.draftListenable.addListener(_onDraftChanged);
  }

  @override
  void didUpdateWidget(covariant SmartReplyBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draftListenable != widget.draftListenable) {
      oldWidget.draftListenable.removeListener(_onDraftChanged);
      widget.draftListenable.addListener(_onDraftChanged);
    }
    if (oldWidget.roomId != widget.roomId) _invalidateSuggestions();
  }

  Map<String, String> _captureInput() => buildSmartReplyInput(
    mergeChatAiContextMessages(widget.roomId, [
      ..._history,
      ...?ref.read(roomMessagesProvider(widget.roomId)).value,
    ]),
    roomId: widget.roomId,
    myUserId: ref.read(authControllerProvider).value?.userId.toString(),
    draft: widget.readDraft(),
    quotedMessage: ref.read(replyTargetProvider(widget.roomId)),
    language: context.locale.languageCode,
  );

  String _inputKey() => jsonEncode([
    widget.roomId,
    ref.read(authControllerProvider).value?.userId,
    _captureInput(),
    widget.readDraft(),
  ]);

  void _onDraftChanged() {
    if (_expanded && _inputKey() != _generatedForMessageId) {
      _invalidateSuggestions();
    }
  }

  void _invalidateSuggestions() {
    _requestEpoch++;
    _core?.cancel();
    _cache.clear();
    _history = const [];
    setState(() {
      _expanded = false;
      _loading = false;
      _suggestions = null;
      _generatedForMessageId = null;
    });
  }

  void _pick(String text) {
    if (_inputKey() != _generatedForMessageId) {
      _invalidateSuggestions();
      Toast.showToast('chat_ai.draft_changed'.tr(), type: ToastType.warning);
      return;
    }
    widget.onPick(text);
    _collapse();
  }

  @override
  void dispose() {
    widget.draftListenable.removeListener(_onDraftChanged);
    _core?.dispose();
    super.dispose();
  }

  /// 最后一条非自己发送的文本类消息
  ChatMessage? _lastIncoming(List<ChatMessage> messages, String? myUserId) {
    for (final m in messages.reversed) {
      if (myUserId != null && m.senderId?.toString() == myUserId) continue;
      if (m.messageType != MessageType.text &&
          m.messageType != MessageType.richText) {
        continue;
      }
      final text = messagePlainText(m);
      if (text.isEmpty) continue;
      return m;
    }
    return null;
  }

  Future<void> _generate() async {
    if (_loading) return;
    final requestEpoch = ++_requestEpoch;
    final myUserId = ref.read(authControllerProvider).value?.userId.toString();
    final messages =
        ref.read(roomMessagesProvider(widget.roomId)).value ?? const [];
    // 缓存命中直接展开
    var cacheKey = _inputKey();
    final cached = _cache[cacheKey];
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        _expanded = true;
        _suggestions = cached;
        _generatedForMessageId = cacheKey;
      });
      return;
    }

    setState(() {
      _expanded = true;
      _loading = true;
      _suggestions = null;
      _generatedForMessageId = cacheKey;
    });

    final initialKey = cacheKey;
    final roomId = widget.roomId;
    final quote = ref.read(replyTargetProvider(widget.roomId));
    final source =
        widget.historyReader ??
        ({required int limit, int? beforeSeq}) => ref
            .read(localDataSourceProvider)
            .getMessagesForConversation(
              roomId,
              limit: limit,
              beforeSeq: beforeSeq,
            );
    final history = await loadChatAiContextMessages(
      roomId: roomId,
      loaded: messages,
      quotedMessage: quote,
      readHistory: source,
    );
    if (!mounted ||
        requestEpoch != _requestEpoch ||
        _generatedForMessageId != initialKey) {
      return;
    }
    if (_inputKey() != initialKey) {
      _invalidateSuggestions();
      return;
    }
    if (_lastIncoming(history, myUserId) == null &&
        quote == null &&
        widget.readDraft().trim().isEmpty) {
      _invalidateSuggestions();
      Toast.showToast('chat_ai.no_incoming'.tr(), type: ToastType.info);
      return;
    }
    _history = history;
    final input = _captureInput();
    cacheKey = _inputKey();
    _generatedForMessageId = cacheKey;

    final core = _core ??= widget.core ?? ChatAiAssistCore();
    core.suggestReplies(
      input: input,
      handlers: ChatAiStreamHandlers(
        onDelta: (_) {},
        onSettled: (ok) => reportAiHealth(ref, ok),
        onDone: (_, fullText) {
          if (!mounted ||
              requestEpoch != _requestEpoch ||
              _generatedForMessageId != cacheKey) {
            return;
          }
          final list = parseAiReplySuggestions(fullText);
          if (list.isEmpty) {
            setState(() {
              _loading = false;
              _expanded = false;
            });
            Toast.showToast(
              'chat_ai.invalid_suggestions'.tr(),
              type: ToastType.warning,
            );
            return;
          }
          final mid = cacheKey;
          _cache.clear();
          _cache[mid] = list;
          setState(() {
            _loading = false;
            _suggestions = list;
            _generatedForMessageId = mid;
          });
        },
        onError: (msg) {
          if (!mounted ||
              requestEpoch != _requestEpoch ||
              _generatedForMessageId != cacheKey) {
            return;
          }
          setState(() {
            _loading = false;
            _expanded = false;
          });
          Toast.showToast(msg, type: ToastType.error);
        },
      ),
    );
  }

  void _collapse() {
    setState(() => _expanded = false);
  }

  void _refresh() {
    final mid = _generatedForMessageId;
    if (mid != null) _cache.remove(mid);
    _generatedForMessageId = null;
    _suggestions = null;
    _generate();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(roomMessagesProvider(widget.roomId), (previous, next) {
      final nextIds = {
        for (final message in next.value ?? const <ChatMessage>[])
          message.messageId,
      };
      final removed =
          previous?.value?.any(
            (message) =>
                message.messageId != null &&
                !nextIds.contains(message.messageId),
          ) ??
          false;
      if (removed) {
        _invalidateSuggestions();
        return;
      }
      _onDraftChanged();
    });
    ref.listen(
      replyTargetProvider(widget.roomId),
      (_, next) => _onDraftChanged(),
    );
    ref.listen(authControllerProvider, (previous, next) {
      // 收起状态也要清除本地历史快照，避免切号后带入上个账号的数据。
      if (previous?.value?.userId != next.value?.userId) {
        _invalidateSuggestions();
      }
    });
    final chatEnabled =
        ref.watch(aiFeatureFlagsProvider).value?.chatAvailable ?? true;
    if (!chatEnabled) return const SizedBox.shrink();
    if (!_expanded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: _pill(
            onTap: _generate,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedSparkles,
                  size: 12,
                  color: _cs.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'chat_ai.smart_reply'.tr(),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall!.copyWith(color: _cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: _loading
                ? _pill(
                    onTap: () {},
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox.square(
                          dimension: 10,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'note_ai.generating'.tr(),
                          style: Theme.of(context).textTheme.labelSmall!
                              .copyWith(color: _cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final s in _suggestions ?? const <String>[])
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _chip(s),
                          ),
                      ],
                    ),
                  ),
          ),
          if (!_loading) ...[
            const SizedBox(width: 4),
            _iconBtn(
              HugeIcons.strokeRoundedRefresh01,
              'chat_ai.retry'.tr(),
              _refresh,
            ),
            _iconBtn(HugeIcons.strokeRoundedCancel01, 'close'.tr(), _collapse),
          ],
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return InkWell(
      onTap: () => _pick(text),
      borderRadius: BorderRadius.circular(RadiusToken.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(RadiusToken.pill),
          border: Border.all(color: _cs.outlineVariant.withValues(alpha: .7)),
          color: _cs.surfaceContainerHighest.withValues(alpha: .35),
        ),
        constraints: const BoxConstraints(maxWidth: 300),
        child: Text(
          text,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodySmall!.copyWith(color: _cs.onSurface),
        ),
      ),
    );
  }

  Widget _pill({required VoidCallback onTap, required Widget child}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RadiusToken.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(RadiusToken.pill),
          border: Border.all(color: _cs.outlineVariant.withValues(alpha: .5)),
        ),
        child: child,
      ),
    );
  }

  Widget _iconBtn(
    List<List<dynamic>> icon,
    String tooltip,
    VoidCallback onTap,
  ) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadiusToken.sm),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: HugeIcon(icon: icon, size: 13, color: _cs.onSurfaceVariant),
        ),
      ),
    );
  }
}
