import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/app/app_scaffold.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// 屏幕过小提示页
///
/// 当设备尺寸低于 [DeviceUtil.minSupportedWidth]/[minSupportedHeight] 时，
/// 主界面布局会溢出甚至无法操作。此页面替代原先的纯文本提示：
/// - 展示品牌化视觉（图标 + 标题 + 说明）
/// - 给出可操作的解决建议（旋转设备 / 放大窗口）
/// - Web/桌面等可自由缩放窗口的场景提供「仍要进入」放行入口
///   （由 [onContinue] 回调上抛给调用方做会话级状态记录）
class UnsupportedDevicePage extends StatelessWidget {
  /// 放行回调；为 null 时不展示「仍要进入」按钮（真机无法放大屏幕）
  final VoidCallback? onContinue;

  const UnsupportedDevicePage({super.key, this.onContinue});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AppScaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 品牌化图标：圆形底 + 禁用手机图标
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedSmartPhone01,
                      size: 38,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'layout_too_small_device'.tr(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'layout_too_small_device_desc'.tr(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 解决建议卡片
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 20,
                          color: cs.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'layout_too_small_device_tip'.tr(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onContinue != null) ...[
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: FilledButton.tonal(
                        onPressed: onContinue,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: Text(
                          'layout_too_small_device_continue'.tr(),
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
    );
  }
}
