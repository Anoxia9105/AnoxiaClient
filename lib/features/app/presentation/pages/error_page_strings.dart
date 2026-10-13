import 'package:anoxia/common/utils/sp_util.dart';
import 'package:anoxia/platform/shims/system_locale_shim.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// 启动失败时语言包可能尚未就绪，保留三语最小兜底。
/// 正常页面优先使用 assets/i18n 翻译；回归测试确保兜底与语言包一致。
abstract final class ErrorPageStrings {
  static Locale startupLocale() {
    String? language;
    try {
      language = SPUtil.instance.get('locale');
    } catch (_) {}
    try {
      language ??= SystemLocale.languageCode();
    } catch (_) {}
    final code = language?.toLowerCase() ?? 'zh';
    return Locale(
      code.startsWith('ja')
          ? 'ja'
          : code.startsWith('zh')
          ? 'zh'
          : 'en',
    );
  }

  static String text(BuildContext context, String key) {
    Locale? locale;
    try {
      final localization = EasyLocalization.of(context);
      locale = localization?.locale;
      if (localization != null) {
        final translated = context.tr(key);
        if (translated.isNotEmpty && translated != key) return translated;
      }
    } catch (_) {}
    locale ??= Localizations.maybeLocaleOf(context) ?? startupLocale();
    final labels = fallback[locale.languageCode] ?? fallback['en']!;
    return labels[key] ?? labels['error_page_generic']!;
  }

  static const fallback = {
    'zh': {
      'error_page_title': '页面暂时无法显示',
      'error_page_generic': '请重试。如果问题持续，可以复制错误信息反馈给我们。',
      'error_page_startup_title': '暂时无法启动应用',
      'error_page_startup_message': '请关闭后重新打开。如果问题持续，可以复制错误信息反馈给我们。',
      'error_page_details': '技术详情',
      'error_page_copy': '复制错误信息',
      'error_page_copied': '错误信息已复制',
      'error_page_copy_failed': '复制失败，请重试',
      'error_page_retry': '重试',
      'error_page_close': '关闭窗口',
    },
    'en': {
      'error_page_title': 'Unable to display this page',
      'error_page_generic':
          'Please try again. If the problem continues, copy the error details and share them with us.',
      'error_page_startup_title': 'Unable to start Anoxia',
      'error_page_startup_message':
          'Close and reopen the app. If the problem continues, copy the error details and share them with us.',
      'error_page_details': 'Technical details',
      'error_page_copy': 'Copy error details',
      'error_page_copied': 'Error details copied',
      'error_page_copy_failed': 'Could not copy. Please try again.',
      'error_page_retry': 'Retry',
      'error_page_close': 'Close window',
    },
    'ja': {
      'error_page_title': 'ページを表示できません',
      'error_page_generic': 'もう一度お試しください。問題が続く場合は、エラー情報をコピーしてお知らせください。',
      'error_page_startup_title': 'アプリを起動できません',
      'error_page_startup_message':
          'アプリを閉じて、もう一度開いてください。問題が続く場合は、エラー情報をコピーしてお知らせください。',
      'error_page_details': '技術的な詳細',
      'error_page_copy': 'エラー情報をコピー',
      'error_page_copied': 'エラー情報をコピーしました',
      'error_page_copy_failed': 'コピーできませんでした。もう一度お試しください。',
      'error_page_retry': '再試行',
      'error_page_close': 'ウィンドウを閉じる',
    },
  };
}
