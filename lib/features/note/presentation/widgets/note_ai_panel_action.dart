/// 记事本 AI 面板动作枚举（面板专用）
///
/// 从 `note_ai_panel.dart` 抽取，原为私有 `_AiPanelAction`，现公开为
/// [AiPanelAction] 并提供 [AiPanelActionX] 扩展，适配 `super.key` 规范。
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:hugeicons/hugeicons.dart';

enum AiPanelAction { summarize, polish, expand, title, translate, continueWrite, custom }

extension AiPanelActionX on AiPanelAction {
  String get api => switch (this) {
        AiPanelAction.summarize => 'SUMMARIZE',
        AiPanelAction.polish => 'POLISH',
        AiPanelAction.expand => 'EXPAND',
        AiPanelAction.title => 'TITLE',
        AiPanelAction.translate => 'TRANSLATE',
        AiPanelAction.continueWrite => 'CONTINUE',
        AiPanelAction.custom => 'CUSTOM',
      };

  String get label => switch (this) {
        AiPanelAction.summarize => 'note_ai.action_summarize'.tr(),
        AiPanelAction.polish => 'note_ai.action_polish'.tr(),
        AiPanelAction.expand => 'note_ai.action_expand'.tr(),
        AiPanelAction.title => 'note_ai.action_title'.tr(),
        AiPanelAction.translate => 'note_ai.action_translate'.tr(),
        AiPanelAction.continueWrite => 'note_ai.action_continue'.tr(),
        AiPanelAction.custom => 'note_ai.action_custom'.tr(),
      };

  /// hugeicons 图标为路径数据，需配合 HugeIcon 组件使用
  List<List<dynamic>> get icon => switch (this) {
        AiPanelAction.summarize => HugeIcons.strokeRoundedFileSearch,
        AiPanelAction.polish => HugeIcons.strokeRoundedBrush,
        AiPanelAction.expand => HugeIcons.strokeRoundedExpand,
        AiPanelAction.title => HugeIcons.strokeRoundedText,
        AiPanelAction.translate => HugeIcons.strokeRoundedTranslate,
        AiPanelAction.continueWrite => HugeIcons.strokeRoundedPen01,
        AiPanelAction.custom => HugeIcons.strokeRoundedMagicWand01,
      };
}
