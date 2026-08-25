/// 智能回复建议条（双端通用，手动触发）
///
/// 输入区上方的一行轻量入口：
/// - 收起态：单个「✨ 智能回复」胶囊按钮
/// - 点击后基于最后一条收到的消息生成 3 条短回复 chips（≤20 字）
/// - 点击 chip 填入输入框可编辑后发送（不直发，符合安全惯例）
/// - 按 (roomId, lastMessageId) 缓存结果；换消息自动失效
///
/// 配额友好：仅手动触发，不自动请求。
library;

import 'dart:async';
import 'dart:convert';

import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/provider/ai/ai_feature_flags_provider.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'chat_ai_assist_core.dart';

class SmartReplyBar extends ConsumerStatefulWidget {
  const SmartReplyBar({
    super.key,
    required this.roomId,
    required this.onPick,
  });

  final String roomId;

  /// 选中建议后的回填回调（由各端注入各自的输入写入实现）
  final ValueChanged<String> onPick;

  @override
  ConsumerState<SmartReplyBar> createState() => _SmartReplyBarState();
}

class _SmartReplyBarState extends ConsumerState<SmartReplyBar> {
  static const _maxSuggestions = 3;

  /// 会话级缓存：lastMessageId → 建议列表（切房间实例重建自然失效）
  static final Map<String, List<String>> _cache = {};

  ChatAiAssistCore? _core;
  bool _expanded = false;
  bool _loading = false;
  List<String>? _suggestions;
  String? _generatedForMessageId;

  ColorScheme get _cs => Theme.of(context).colorScheme;

  @override
  void dispose() {
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
      final text = m.payload?.content?.trim();
      if (text == null || text.isEmpty) continue;
      return m;
    }
    return null;
  }

  Future<void> _generate() async {
    if (_loading) return;
    final myUserId =
        ref.read(authControllerProvider).value?.userId.toString();
    final messages =
        ref.read(roomMessagesProvider(widget.roomId)).value ?? const [];
    final last = _lastIncoming(messages, myUserId);
    if (last == null) {
      Toast.showToast('chat_ai.no_incoming'.tr(), type: ToastType.info);
      return;
    }

    // 缓存命中直接展开
    final cached = _cache[last.messageId ?? ''];
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        _expanded = true;
        _suggestions = cached;
        _generatedForMessageId = last.messageId;
      });
      return;
    }

    setState(() {
      _expanded = true;
      _loading = true;
      _suggestions = null;
    });

    final core = _core ??= ChatAiAssistCore();
    final quoted = (last.payload?.content ?? '').trim();
    core.chat(
      message: '以下是一条收到的聊天消息：\n"""\n$quoted\n"""\n\n'
          '请为这条消息生成 $_maxSuggestions 条简短的中文回复建议，'
          '每条不超过20个字符，语气自然口语化。'
          '只输出一个 JSON 字符串数组，例如 ["好的","收到","没问题"]，不要输出其他内容。',
      handlers: ChatAiStreamHandlers(
        onDelta: (_) {},
        onDone: (_, fullText) {
          if (!mounted) return;
          final list = _parseSuggestions(fullText);
          if (list.isEmpty) {
            setState(() {
              _loading = false;
              _expanded = false;
            });
            Toast.showToast('chat_ai.failed'.tr(), type: ToastType.error);
            return;
          }
          final mid = last.messageId ?? '';
          _cache[mid] = list;
          setState(() {
            _loading = false;
            _suggestions = list;
            _generatedForMessageId = mid;
          });
        },
        onError: (msg) {
          if (!mounted) return;
          setState(() {
            _loading = false;
            _expanded = false;
          });
          Toast.showToast(msg, type: ToastType.error);
        },
      ),
    );
  }

  /// 解析模型输出：优先 JSON 数组，失败则按行拆分并清洗序号/引号
  List<String> _parseSuggestions(String raw) {
    var text = raw.trim();
    // 剥离 ```json 包装
    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```(json)?\s*'), '')
          .replaceFirst(RegExp(r'```\s*$'), '');
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is List) {
        return decoded
            .whereType<String>()
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .take(_maxSuggestions)
            .toList();
      }
    } catch (_) {}
    // 行级降级
    final lines = text
        .split('\n')
        .map((l) => l
            .trim()
            .replaceFirst(RegExp(r'^[-*\d.、\)\s]+'), '')
            .replaceAll(RegExp('^["\'"「『]|["\'"」』]\$'), '')
            .trim())
        .where((l) => l.isNotEmpty && l.length <= 40)
        .take(_maxSuggestions)
        .toList();
    return lines;
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
    final chatEnabled = ref.watch(aiFeatureFlagsProvider).value?.chatEnabled ?? true;
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
                HugeIcon(icon: HugeIcons.strokeRoundedSparkles,
                    size: 12, color: _cs.primary),
                const SizedBox(width: 4),
                Text('chat_ai.smart_reply'.tr(),
                    style: TextStyle(fontSize: 11, color: _cs.onSurfaceVariant)),
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
                            child: CircularProgressIndicator(strokeWidth: 1.5)),
                        const SizedBox(width: 6),
                        Text('note_ai.generating'.tr(),
                            style: TextStyle(
                                fontSize: 11, color: _cs.onSurfaceVariant)),
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
            _iconBtn(HugeIcons.strokeRoundedRefresh01, 'chat_ai.retry'.tr(), _refresh),
            _iconBtn(HugeIcons.strokeRoundedCancel01, 'close'.tr(), _collapse),
          ],
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return InkWell(
      onTap: () => widget.onPick(text),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _cs.outlineVariant.withValues(alpha: .7)),
          color: _cs.surfaceContainerHighest.withValues(alpha: .35),
        ),
        child: Text(text,
            style: TextStyle(fontSize: 11.5, color: _cs.onSurface)),
      ),
    );
  }

  Widget _pill({required VoidCallback onTap, required Widget child}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _cs.outlineVariant.withValues(alpha: .5)),
        ),
        child: child,
      ),
    );
  }

  Widget _iconBtn(List<List<dynamic>> icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: HugeIcon(icon: icon, size: 13, color: _cs.onSurfaceVariant),
        ),
      ),
    );
  }
}
