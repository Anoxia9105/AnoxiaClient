import 'package:anoxia/framework/theme/app_colors.dart';
import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import 'error_page_strings.dart';

/// 通用错误页：继承当前主题；启动期由 StartupErrorApp 提供独立主题和语言。
class ErrorPage extends StatelessWidget {
  const ErrorPage({
    super.key,
    this.message,
    this.details,
    this.onRetry,
    this.onClose,
    this.startup = false,
  });

  final String? message;
  final String? details;
  final VoidCallback? onRetry;
  final VoidCallback? onClose;
  final bool startup;

  Future<void> _copy(BuildContext context) async {
    final text = details?.isNotEmpty == true
        ? details!
        : message ?? ErrorPageStrings.text(context, 'error_page_generic');
    var resultKey = 'error_page_copied';
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (_) {
      resultKey = 'error_page_copy_failed';
    }
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(ErrorPageStrings.text(context, resultKey)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    String label(String key) => ErrorPageStrings.text(context, key);
    final copyLabel = label('error_page_copy');
    final detailsText = details?.isNotEmpty == true ? details : null;
    Widget copyIcon(Color color) =>
        HugeIcon(icon: HugeIcons.strokeRoundedCopy01, size: 18, color: color);

    return Scaffold(
      backgroundColor: scheme.surface,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: theme.extension<AppColors>()?.scaffoldGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(RadiusToken.xl),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: .6),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(RadiusToken.lg),
                        ),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedAlertCircle,
                          size: 26,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Semantics(
                        header: true,
                        child: Text(
                          label(
                            startup
                                ? 'error_page_startup_title'
                                : 'error_page_title',
                          ),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        message ??
                            label(
                              startup
                                  ? 'error_page_startup_message'
                                  : 'error_page_generic',
                            ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          if (onRetry != null)
                            FilledButton.icon(
                              onPressed: onRetry,
                              icon: HugeIcon(
                                icon: HugeIcons.strokeRoundedRefresh,
                                size: 18,
                                color: scheme.onPrimary,
                              ),
                              label: Text(label('error_page_retry')),
                            ),
                          if (onRetry == null)
                            FilledButton.icon(
                              onPressed: () => _copy(context),
                              icon: copyIcon(scheme.onPrimary),
                              label: Text(copyLabel),
                            )
                          else
                            OutlinedButton.icon(
                              onPressed: () => _copy(context),
                              icon: copyIcon(scheme.primary),
                              label: Text(copyLabel),
                            ),
                          if (onClose != null)
                            OutlinedButton(
                              onPressed: onClose,
                              child: Text(label('error_page_close')),
                            ),
                        ],
                      ),
                      if (detailsText != null) ...[
                        const SizedBox(height: 20),
                        Divider(
                          height: 1,
                          color: scheme.outlineVariant.withValues(alpha: .6),
                        ),
                        Theme(
                          data: theme.copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: Material(
                            type: MaterialType.transparency,
                            child: ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              childrenPadding: EdgeInsets.zero,
                              title: Text(
                                label('error_page_details'),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: scheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(
                                      RadiusToken.md,
                                    ),
                                  ),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxHeight: 180,
                                    ),
                                    child: SingleChildScrollView(
                                      child: SelectableText(
                                        detailsText,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              height: 1.5,
                                              color: scheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
