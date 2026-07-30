import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/bubble_dialog.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/common/widgets/adaptive_page_presenter.dart';
import 'package:anoxia/features/chat/presentation/pages/scan_qr_page.dart';
import 'package:anoxia/features/chat/presentation/widgets/create_chat_dialog_widget.dart';
import 'package:anoxia/features/contact/presentation/pages/add_friend_page.dart';
import 'package:anoxia/framework/core/app_globals.dart';
import 'package:anoxia/framework/provider/router/router.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// 房间列表对话框菜单工具类
///
/// 提供房间列表页面右上角菜单的静态方法，包括：
/// - 创建群聊
/// - 添加好友
class RoomListDialogMenus {
  /// 显示右上角菜单对话框
  ///
  /// 根据设备类型（移动端/桌面端）调整菜单的位置和样式，
  /// 提供创建群聊和添加好友的入口
  ///
  /// [context] 构建上下文
  /// [ref] 可选的回调函数，用于处理添加好友对话框
  static void showTopRightDialog(BuildContext context, {Function? ref}) {
    Function? close;
    bool isMobile = DeviceUtil.isRealMobile();

    close = Toast.showWidget(
      context,
      direction: isMobile
          ? PreferDirection.bottomRight
          : PreferDirection.bottomLeft,
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: BubbleWidget(
            arrowDirection: AxisDirection.up,
            arrowOffset: isMobile ? 130 : 25,
            backgroundColor: Theme.of(context).colorScheme.surface,
            // 1. 增加精致圆角与柔和阴影
            borderRadius: BorderRadius.circular(10),
            shadows: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: 0.5,
            ),
            contentBuilder: (context) => Container(
              // 2. 紧凑的宽度与高度控制
              constraints: BoxConstraints(maxWidth: isMobile ? 120 : 140),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 创建群聊
                  _buildMenuItem(
                    context: context,
                    icon: HugeIcons.strokeRoundedChatting01,
                    title: 'chat_create_group'.tr(),
                    onTap: () {
                      close?.call();
                      if (DeviceUtil.isRealMobile()) {
                        const CreateGroupRoute().push(
                          appNavigatorKey.currentContext!,
                        );
                        return;
                      }
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const CreateChatDialogWidget(),
                      );
                    },
                  ),
                  // 添加好友
                  _buildMenuItem(
                    context: context,
                    icon: HugeIcons.strokeRoundedUserAdd01,
                    title: 'chat_add_friend'.tr(),
                    onTap: () {
                      close?.call();
                      presentAdaptivePage(
                        appNavigatorKey.currentContext!,
                        builder: (_) => const AddFriendPage(),
                      );
                    },
                  ),
                  // 扫一扫
                  if (isMobile)
                    _buildMenuItem(
                      context: context,
                      icon: HugeIcons.strokeRoundedScan,
                      title: 'chat_scan_qr_code'.tr(),
                      onTap: () {
                        close?.call();
                        Navigator.of(appNavigatorKey.currentContext!).push(
                          MaterialPageRoute(builder: (_) => const ScanQrPage()),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildMenuItem({
    required BuildContext context,
    required dynamic icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final color = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Row(
          // 核心：设置水平居中
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: icon,
              size: 16,
              color: color.withValues(alpha: 0.85),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: color,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

/// 显示添加好友对话框
///
/// [context] 构建上下文
/// [ref] Riverpod 的 WidgetRef
// void _showAddFriendDialog(BuildContext context, WidgetRef ref) {
//     final isDesktop = DeviceUtil.isRealDesktop();
//     final dialogWidth = isDesktop ? 900.0 : 400.0;
//     final dialogHeight = isDesktop ? 700.0 : 600.0;

//     showDialog(
//       context: context,
//       builder: (context) {
//         final colorScheme = Theme.of(context).colorScheme;
//         return Dialog(
//           insetPadding: const EdgeInsets.all(16),
//           elevation: 0,
//           clipBehavior: Clip.antiAlias,
//           backgroundColor: colorScheme.surface,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//             side: BorderSide(
//               color: colorScheme.outlineVariant.withValues(alpha: 0.7),
//               width: 1,
//             ),
//           ),
//           child: SizedBox(
//             width: dialogWidth,
//             height: dialogHeight,
//             child: const AddFriendPage(),
//           ),
//         );
//       },
//     );
//   }
