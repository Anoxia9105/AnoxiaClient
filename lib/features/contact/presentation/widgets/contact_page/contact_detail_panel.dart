import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/framework/provider/layout/desktop_layout_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 桌面端联系人详情右侧内容面板
///
/// 卡片模式由主框架统一包裹，内部左右分栏不再单独套卡片。
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
      return Padding(padding: const EdgeInsets.only(left: 12), child: child);
    }

    return child;
  }
}
