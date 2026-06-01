import 'package:anoxia/common/constants/StorageKeys.dart';
import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/BubbleDialog.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/features/chat/presentation/widgets/create_chat_dialog_widget.dart';
import 'package:anoxia/features/contact/presentation/pages/add_friend_page.dart';
import 'package:anoxia/framework/core/app_globals.dart';
import 'package:anoxia/framework/provider/router/router.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
            arrowOffset: isMobile ? 140 : 25,
            backgroundColor: Theme.of(context).colorScheme.surface,
            border: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 0.5,
            ),
            contentBuilder: (context) => Container(
              constraints: BoxConstraints(
                maxWidth: isMobile ? 160 : 220,
                maxHeight: 600,
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 创建群聊按钮
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
                        /// 移动端跳转页面，桌面端显示对话框
                        // if (DeviceUtil.isRealMobile()) {
                        //   return;
                        // }

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return const CreateChatDialogWidget();
                          },
                        );
                        close?.call();
                      },
                      label: Text('chat_create_group'.tr()),
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedChatting01,
                        size: 18,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  // 添加好友按钮
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
                        /// 移动端跳转页面，桌面端显示对话框
                        if (DeviceUtil.isRealMobile()) {
                          const AddFriendRoute().push(
                            appNavigatorKey.currentContext!,
                          );
                          return;
                        }
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return const AddFriendPage();
                          },
                        );
                        close?.call();
                      },
                      label: Text('chat_add_friend'.tr()),
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedUserAdd01,
                        size: 18,
                      ),
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
