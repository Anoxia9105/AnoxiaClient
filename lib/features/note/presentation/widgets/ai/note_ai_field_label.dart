/// 记事本 AI 面板区块小标题（手机端弹框 / 桌面端侧栏共用）
library;

import 'package:flutter/material.dart';

/// 区块小标题。
///
/// 统一为「小号大写 + 加宽字距 + 右侧引导线」，让弹框与侧栏的
/// 「作用范围 / AI 能力 / 预览」几段分组节奏保持一致。
class NoteAiFieldLabel extends StatelessWidget {
  const NoteAiFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: cs.outline,
                ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Container(
              height: 1,
              color: cs.outlineVariant.withValues(alpha: .45),
            ),
          ),
        ],
      ),
    );
  }
}
