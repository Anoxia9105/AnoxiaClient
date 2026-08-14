import 'package:anoxia/framework/theme/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

/// 页面不存在（404）页面
///
/// 由 GoRouter 的 errorBuilder 兜底渲染：访问不存在的路由（如错误的链接、
/// 失效的深层链接）时展示品牌化提示页，而非框架默认的空白错误页。
///
/// 国际化：正常场景走 easy_localization；当本地化上下文异常（如路由错误
/// 发生在初始化阶段）时自动回退到内置默认文案，避免二次渲染错误。
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  /// 安全的国际化取值：本地化未就绪或取不到值时回退默认文案
  String _t(BuildContext context, String key, String fallback) {
    try {
      final value = context.tr(key);
      if (value.isNotEmpty && value != key) return value;
    } catch (_) {}
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    // 错误场景下 Theme 可能不可用，兜底使用亮色默认配色，避免二次异常
    ColorScheme scheme;
    Gradient? gradient;
    try {
      final theme = Theme.of(context);
      scheme = theme.colorScheme;
      gradient = theme.extension<AppColors>()?.scaffoldGradient;
    } catch (_) {
      scheme = const ColorScheme.light();
      gradient = null;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '404',
                    style: TextStyle(
                      fontSize: 96,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedSearch01,
                      size: 40,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _t(context, 'not_found_title', '页面不存在'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _t(
                      context,
                      'not_found_desc',
                      '您访问的页面不存在或已被移除，请检查链接是否正确。',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedHome01,
                      size: 18,
                    ),
                    label: Text(
                      _t(context, 'not_found_back_home', '返回首页'),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
