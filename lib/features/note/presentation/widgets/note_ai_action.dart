/// 记事本 AI 动作枚举
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:hugeicons/hugeicons.dart';

enum NoteAiAction { summarize, polish, expand, title, translate, continueWrite, custom }

extension NoteAiActionX on NoteAiAction {
  String get api => switch (this) {
        NoteAiAction.summarize => 'SUMMARIZE',
        NoteAiAction.polish => 'POLISH',
        NoteAiAction.expand => 'EXPAND',
        NoteAiAction.title => 'TITLE',
        NoteAiAction.translate => 'TRANSLATE',
        NoteAiAction.continueWrite => 'CONTINUE',
        NoteAiAction.custom => 'CUSTOM',
      };

  String get label => switch (this) {
        NoteAiAction.summarize => 'note_ai.action_summarize'.tr(),
        NoteAiAction.polish => 'note_ai.action_polish'.tr(),
        NoteAiAction.expand => 'note_ai.action_expand'.tr(),
        NoteAiAction.title => 'note_ai.action_title'.tr(),
        NoteAiAction.translate => 'note_ai.action_translate'.tr(),
        NoteAiAction.continueWrite => 'note_ai.action_continue'.tr(),
        NoteAiAction.custom => 'note_ai.action_custom'.tr(),
      };

  /// hugeicons 图标为路径数据，需配合 HugeIcon 组件使用
  List<List<dynamic>> get icon => switch (this) {
        NoteAiAction.summarize => HugeIcons.strokeRoundedFileSearch,
        NoteAiAction.polish => HugeIcons.strokeRoundedBrush,
        NoteAiAction.expand => HugeIcons.strokeRoundedExpand,
        NoteAiAction.title => HugeIcons.strokeRoundedText,
        NoteAiAction.translate => HugeIcons.strokeRoundedTranslate,
        NoteAiAction.continueWrite => HugeIcons.strokeRoundedPen01,
        NoteAiAction.custom => HugeIcons.strokeRoundedMagicWand01,
      };
}
