// 「翻译」面板（P0-3）。
//
// 由消息长按/右键菜单进入，presentAdaptivePage 承载（桌面模态 + 移动端
// 全屏路由）；面板打开即按当前 UI locale 发起流式翻译：
// - provider 按 `messageId|目标语言` family 缓存，同一消息重开面板
//   直接取现成译文，不再请求；
// - 仅 text/richText/codeSnippet 且提取文本非空时入口才会展示（菜单侧
//   `isTranslatableMessage` 判定，与 provider 口径一致）；
// - 失败 AiException 文案直接展示（服务端已本地化），其它兜底 i18n key。
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/provider/chat/message/ai_message_tools_provider.dart';
import 'package:anoxia/framework/provider/chat/message/ai_prompt_builder.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AiTranslateSheet extends ConsumerStatefulWidget {
  final ChatMessage message;

  const AiTranslateSheet({super.key, required this.message});

  @override
  ConsumerState<AiTranslateSheet> createState() => _AiTranslateSheetState();
}

class _AiTranslateSheetState extends ConsumerState<AiTranslateSheet> {
  late final String _key;
  late final String _language;
  late final String _sourceText;

  @override
  void initState() {
    super.initState();
    _language = aiLanguageName(context.locale.languageCode);
    _sourceText = messagePlainText(widget.message);
    final messageId = widget.message.messageId ?? 'local-${_sourceText.hashCode}';
    _key = '$messageId|$_language';
    // build 期不能触发（riverpod 修改期禁止），进下一帧再启动
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(aiTranslateControllerProvider(_key).notifier)
          .translate(_sourceText, language: _language);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiTranslateControllerProvider(_key));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('chat_ai.translate'.tr()),
        actions: [
          if (state.hasContent)
            IconButton(
              tooltip: 'chat_copy'.tr(),
              icon: const Icon(Icons.copy_outlined),
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: state.text ?? ''),
                );
                if (context.mounted) {
                  Toast.showToast('chat_ai.translation_copied'.tr());
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 原文
            Text(
              'chat_ai.original_text'.tr(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _sourceText,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 20),
            // 译文（streaming / error / 空内容 / 正文）
            Text(
              'chat_ai.translation'.tr(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            _TranslationBody(
              state: state,
              language: _language,
              source: _sourceText,
              providerKey: _key,
            ),
          ],
        ),
      ),
    );
  }
}

class _TranslationBody extends ConsumerWidget {
  final AiToolState state;
  final String language;
  final String source;
  final String providerKey;

  const _TranslationBody({
    required this.state,
    required this.language,
    required this.source,
    required this.providerKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    if (state.error != null) {
      final message = state.error!.startsWith('chat_ai.')
          ? state.error!.tr()
          : state.error!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colorScheme.error),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => ref
                .read(aiTranslateControllerProvider(providerKey).notifier)
                .translate(source, language: language),
            icon: const Icon(Icons.refresh_outlined),
            label: Text('chat_media_timeline_retry'.tr()),
          ),
        ],
      );
    }

    if (state.isEmptyResult) {
      return Text(
        'chat_ai.translate_empty'.tr(),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    if (state.hasContent) {
      return SelectableText(
        state.text!,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    // streaming / 初始态占位
    return Row(
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          state.text == null ? 'chat_ai.translating'.tr() : state.text!,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
