import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 移动端底部面板类型
enum MobileBottomPanelType { emoji, more, ai }

/// 图片选择操作
enum ImageSelectionAction { sendOriginal, crop }

/// 紧凑按钮（语音/键盘、表情、AI 等图标按钮共用）
///
/// 透明材质 + 8 圆角，保持与原 _buildCompactButton 一致的视觉
class MobileCompactButton extends StatelessWidget {
  /// 提示文本
  final String tooltipMessage;

  /// 点击回调
  final VoidCallback onTap;

  /// 图标
  final dynamic icon;

  /// 图标颜色，默认跟随主题
  final Color? color;

  const MobileCompactButton({
    super.key,
    required this.tooltipMessage,
    required this.onTap,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(RadiusToken.md);
    return Tooltip(
      message: tooltipMessage,
      child: Material(
        type: MaterialType.transparency,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: HugeIcon(
              icon: icon,
              size: 24,
              color: color ?? colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// 发送按钮（实心主题色圆角方块）
///
/// 与更多按钮同为 40×40 触控区，切换时无尺寸差导致的位移；圆角 12 与输入胶囊一致。
class MobileSendButton extends StatelessWidget {
  /// 点击回调
  final VoidCallback onTap;

  const MobileSendButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(RadiusToken.lg);
    return Tooltip(
      message: 'toolbar_send'.tr(),
      child: Material(
        color: colorScheme.primary,
        borderRadius: borderRadius,
        elevation: 2,
        shadowColor: colorScheme.primary.withValues(alpha: 0.4),
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: SizedBox.square(
            dimension: 40,
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedSent,
                size: 20,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 胶囊输入容器（文本 / 语音共用）
///
/// 圆角胶囊视觉：常态浅色悬浮，聚焦 / 录音时主题色高亮描边，阴影随状态增强，自动适配亮暗主题。
class MobileInputCapsule extends StatelessWidget {
  /// 内容
  final Widget child;

  /// 是否处于激活态（聚焦/按压/录音）
  final bool isActive;

  /// 是否正在录音
  final bool isRecording;

  /// 是否有焦点
  final bool hasFocus;

  const MobileInputCapsule({
    super.key,
    required this.child,
    required this.isActive,
    this.isRecording = false,
    this.hasFocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      constraints: const BoxConstraints(minHeight: 42),
      decoration: BoxDecoration(
        color: isRecording
            ? colorScheme.primary
            : isActive
                ? colorScheme.surfaceContainerHigh
                : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        border: Border.all(
          color: isRecording
              ? Colors.transparent
              : hasFocus
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(
                      alpha: isDark ? 0.25 : 0.45,
                    ),
          width: hasFocus ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark
                  ? (isActive ? 0.32 : 0.18)
                  : (isActive ? 0.10 : 0.05),
            ),
            blurRadius: isActive ? 14 : 8,
            offset: Offset(0, isActive ? 4 : 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// 语音胶囊内容（按住说话文本，带缩放与颜色动画）
class MobileVoiceCapsuleContent extends StatelessWidget {
  /// 是否按压中
  final bool isPressing;

  /// 是否录音中
  final bool isRecording;

  const MobileVoiceCapsuleContent({
    super.key,
    required this.isPressing,
    required this.isRecording,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      alignment: Alignment.center,
      constraints: const BoxConstraints(minHeight: 42),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: AnimatedScale(
        scale: isPressing ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isRecording ? FontWeight.w600 : FontWeight.normal,
            color: isRecording
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
          ),
          child: Text('hold_to_talk'.tr()),
        ),
      ),
    );
  }
}
