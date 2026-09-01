import 'package:anoxia/common/widgets/toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 全局错误页面
///
/// 用于展示应用运行时发生的错误（含 [ErrorWidget.builder] 渲染失败场景），
/// 支持自定义错误消息与错误详情。
///
/// 国际化：文案默认走 easy_localization（en/zh/ja）；当错误发生在
/// EasyLocalization 尚未初始化（如启动失败兜底页）或上下文异常时，
/// 自动回退到内置默认文案，避免二次渲染错误。
class ErrorPage extends StatelessWidget {
  /// 自定义错误消息；为 null 时显示通用错误文案
  final String? message;

  /// 错误详情（原始异常文本），非空时展示可复制的详情卡片
  final String? details;

  /// 重试回调；为 null 时隐藏重试按钮
  final VoidCallback? onRetry;

  /// 关闭回调（如桌面端关闭窗口）；为 null 时隐藏关闭按钮
  final VoidCallback? onClose;

  const ErrorPage({
    super.key,
    this.message,
    this.details,
    this.onRetry,
    this.onClose,
  });

  /// 安全的国际化取值：国际化未就绪或取不到值时回退默认文案，
  /// 保证错误页本身永不因缺失 localization 而二次报错。
  String _t(BuildContext context, String key, String fallback) {
    try {
      final value = context.tr(key);
      if (value.isNotEmpty && value != key) return value;
    } catch (_) {}
    return fallback;
  }

  void _copy(BuildContext context) {
    final text = details?.isNotEmpty == true
        ? details!
        : message ?? _t(context, 'error_page_generic', '页面遇到了一些问题');
    try {
      Clipboard.setData(ClipboardData(text: text));
      Toast.showToast(
        _t(context, 'error_page_copied', '错误信息已复制'),
        type: ToastType.success,
        duration: const Duration(seconds: 2),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // 错误场景下 Theme 可能不可用，兜底使用亮色默认配色，避免二次异常
    ColorScheme scheme;
    try {
      scheme = Theme.of(context).colorScheme;
    } catch (_) {
      scheme = const ColorScheme.light();
    }

    final messageText =
        message ?? _t(context, 'error_page_generic', '页面遇到了一些问题，请重试');
    final detailsText = details?.isNotEmpty == true ? details : null;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedAlertCircle,
                    size: 48,
                    color: scheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _t(context, 'error_page_title', '页面渲染出错'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  messageText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (detailsText != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(RadiusToken.md),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: SelectableText(
                      detailsText,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 8,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    if (onRetry != null)
                      FilledButton.icon(
                        onPressed: onRetry,
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedRefresh,
                        ),
                        label: Text(_t(context, 'error_page_retry', '重试')),
                      ),
                    OutlinedButton.icon(
                      onPressed: () => _copy(context),
                      icon: const HugeIcon(icon: HugeIcons.strokeRoundedCopy01),
                      label: Text(_t(context, 'error_page_copy', '复制错误信息')),
                    ),
                    if (onClose != null)
                      TextButton(
                        onPressed: onClose,
                        child: Text(_t(context, 'error_page_close', '关闭窗口')),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
