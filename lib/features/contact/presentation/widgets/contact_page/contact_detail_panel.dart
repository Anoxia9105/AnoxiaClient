import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/framework/provider/layout/desktop_layout_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 桌面端联系人详情右侧内容面板
///
/// 为详情页提供统一的卡片式容器和圆角裁剪；
/// 平铺模式下与记事本/聊天详情一致，不套卡片，保证自定义（视频）
/// 背景下各页面右侧区域透明度一致。
class ContactDetailPanel extends ConsumerWidget {
  final Widget child;

  const ContactDetailPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (DeviceUtil.isMobile(context)) {
      return child;
    }

    final supportsDesktopLayout = DeviceUtil.supportsDesktopLayoutPreference(
      context,
    );
    final layoutStyle = supportsDesktopLayout
        ? resolveDesktopLayoutStyle(
            ref.watch(desktopLayoutProvider),
            availableWidth: MediaQuery.sizeOf(context).width,
          )
        : DesktopLayoutStyle.card;
    if (layoutStyle == DesktopLayoutStyle.flat) {
      return Padding(
        padding: const EdgeInsets.only(left: 12),
        child: child,
      );
    }

    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 12, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(RadiusToken.xl),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.18)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(RadiusToken.xl),
          child: child,
        ),
      ),
    );
  }
}