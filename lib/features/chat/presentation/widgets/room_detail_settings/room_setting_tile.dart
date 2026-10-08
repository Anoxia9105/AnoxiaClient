import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 会话详情图标底块配色
///
/// 固定柔和底色 + 深色图标（浅/深主题各一套），与强调色解耦，
/// 16 套主题下观感一致。色值对齐设计稿 v3。
class SettingIconTint {
  final Color lightBackground;
  final Color lightForeground;
  final Color darkBackground;
  final Color darkForeground;

  const SettingIconTint({
    required this.lightBackground,
    required this.lightForeground,
    required this.darkBackground,
    required this.darkForeground,
  });

  /// 按当前亮度解析出（底，字）配色
  (Color, Color) resolve(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark
        ? (darkBackground, darkForeground)
        : (lightBackground, lightForeground);
  }

  static const blue = SettingIconTint(
    lightBackground: Color(0xFFE7EDFF),
    lightForeground: Color(0xFF3D5BD6),
    darkBackground: Color(0xFF2A3358),
    darkForeground: Color(0xFFA9BCFF),
  );
  static const green = SettingIconTint(
    lightBackground: Color(0xFFE2F4EB),
    lightForeground: Color(0xFF1B8A5F),
    darkBackground: Color(0xFF1E3A30),
    darkForeground: Color(0xFF6FD8A6),
  );
  static const amber = SettingIconTint(
    lightBackground: Color(0xFFFBF0DC),
    lightForeground: Color(0xFFA96F14),
    darkBackground: Color(0xFF3E3220),
    darkForeground: Color(0xFFE8B45A),
  );
  static const violet = SettingIconTint(
    lightBackground: Color(0xFFEFE7FB),
    lightForeground: Color(0xFF7A4FD0),
    darkBackground: Color(0xFF32264A),
    darkForeground: Color(0xFFC2A6F5),
  );
  static const rose = SettingIconTint(
    lightBackground: Color(0xFFFBE7EC),
    lightForeground: Color(0xFFC2436B),
    darkBackground: Color(0xFF3E2430),
    darkForeground: Color(0xFFF093B0),
  );
  static const teal = SettingIconTint(
    lightBackground: Color(0xFFDFF3F1),
    lightForeground: Color(0xFF12857E),
    darkBackground: Color(0xFF1D3533),
    darkForeground: Color(0xFF6FD3CB),
  );
  static const grey = SettingIconTint(
    lightBackground: Color(0xFFEFEEF3),
    lightForeground: Color(0xFF5F5F6B),
    darkBackground: Color(0xFF2A2B33),
    darkForeground: Color(0xFFB9B9C6),
  );

  /// 危险操作：跟随 colorScheme.error，保证与主题报错色一致
  static SettingIconTint dangerOf(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SettingIconTint(
      lightBackground: scheme.error.withValues(alpha: 0.1),
      lightForeground: scheme.error,
      darkBackground: scheme.error.withValues(alpha: 0.16),
      darkForeground: scheme.error,
    );
  }
}

/// 会话详情设置行：彩色图标底块 + 标题/副标题 + 尾部
///
/// 统一行高与视觉层级，替换原来裸 `HugeIcon` 直排的 `_buildMaterialListTile`。
/// 无副标题、无尾部时均可省略；默认尾部为右箭头（14px faint）。
class RoomSettingTile extends StatelessWidget {
  final List<List<dynamic>> icon;
  final SettingIconTint tint;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;

  const RoomSettingTile({
    super.key,
    required this.icon,
    required this.tint,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showChevron = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = tint.resolve(context);
    final faint = Theme.of(context).colorScheme.outline;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      minVerticalPadding: 8,
      dense: true,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(RadiusToken.lg),
        ),
        alignment: Alignment.center,
        child: HugeIcon(icon: icon, size: 19, color: foreground),
      ),
      title: DefaultTextStyle.merge(
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        child: title,
      ),
      subtitle: subtitle == null
          ? null
          : DefaultTextStyle.merge(
              style: const TextStyle(fontSize: 11.5),
              child: subtitle!,
            ),
      trailing: trailing ??
          (showChevron
              ? HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  size: 14,
                  color: faint,
                )
              : null),
      onTap: onTap,
    );
  }
}

/// 分组小标题（群成员 / 群管理 / 消息与提醒 …）
///
/// 左侧文字 + 右侧 hairline，弱化存在感但建立分组节奏。
class RoomSectionCaption extends StatelessWidget {
  final String text;

  const RoomSectionCaption(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
      child: Row(
        children: [
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.4,
                ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Divider(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
