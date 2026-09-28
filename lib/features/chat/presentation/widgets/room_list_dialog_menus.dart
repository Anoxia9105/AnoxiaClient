import 'package:anoxia/common/utils/device_util.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/common/widgets/adaptive_page_presenter.dart';
import 'package:anoxia/common/widgets/bubble_dialog.dart';
import 'package:anoxia/common/widgets/bubble_menu.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/features/chat/presentation/pages/scan_qr_page.dart';
import 'package:anoxia/features/chat/presentation/widgets/create_chat_dialog_widget.dart';
import 'package:anoxia/features/contact/presentation/pages/add_friend_page.dart';
import 'package:anoxia/framework/core/app_globals.dart';
import 'package:anoxia/framework/provider/router/router.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

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
    // UI 布局按单栏/双栏判定（Web 窄屏、平板竖屏等同移动端），而非 isMobile()，
    // 否则平板竖屏（单栏占满、按钮贴右缘）仍走桌面端 bottomLeft + 固定箭头，
    // 气泡角指向列表中间而非右上角按钮；Web 缩小窗口同理。
    // 单栏（含手机/平板竖屏）按钮贴屏幕右缘，用 bottomRight + 右侧箭头指向按钮。
    final bool isSingleColumn = DeviceUtil.useSingleColumnPush(context);
    // Web 无摄像头扫码能力，隐藏"扫一扫"入口
    // 扫码入口仅手机真机开放，平板/桌面沿用原逻辑不展示
    final showScan =
        DeviceUtil.isMobile(context) && !DeviceUtil.isRealWeb();

    // 气泡宽度自适应最长文案（中文短、日/英文长），避免文字溢出报错；
    // 超出上限时由文案省略号兜底
    final menuWidth = BubbleMenu.measureWidth(
      context,
      titles: [
        'chat_create_group'.tr(),
        'chat_add_friend'.tr(),
        if (showScan) 'chat_scan_qr_code'.tr(),
      ],
      maxWidth: isSingleColumn ? 200 : 220,
    );

    close = Toast.showWidget(
      context,
      direction: isSingleColumn
          ? PreferDirection.bottomRight
          : PreferDirection.bottomLeft,
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: BubbleWidget(
            arrowDirection: AxisDirection.up,
            // 气泡宽度随文案自适应，单栏箭头偏移跟随宽度，保持指向右上角按钮
            arrowOffset: isSingleColumn ? menuWidth - 20 : 25,
            backgroundColor: Theme.of(context).colorScheme.surface,
            // 1. 增加精致圆角与柔和阴影
            borderRadius: BorderRadius.circular(RadiusToken.lg),
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
              // 2. 宽度自适应最长文案，所有菜单项等宽、内容统一居中
              width: menuWidth,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 创建群聊
                  BubbleMenu.buildMenuItem(
                    context: context,
                    icon: HugeIcons.strokeRoundedChatting01,
                    title: 'chat_create_group'.tr(),
                    textMaxWidth: menuWidth - BubbleMenu.fixedContentWidth,
                    onTap: () {
                      close?.call();
                      // 单栏（手机/平板竖屏）全屏推入建群页，双栏才弹桌面对话框
                      if (isSingleColumn) {
                        const CreateGroupRoute().push(
                          appNavigatorKey.currentContext!,
                        );
                        return;
                      }
                      showEscClosableDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const CreateChatDialogWidget(),
                      );
                    },
                  ),
                  // 添加好友
                  BubbleMenu.buildMenuItem(
                    context: context,
                    icon: HugeIcons.strokeRoundedUserAdd01,
                    title: 'chat_add_friend'.tr(),
                    textMaxWidth: menuWidth - BubbleMenu.fixedContentWidth,
                    onTap: () {
                      close?.call();
                      presentAdaptivePage(
                        appNavigatorKey.currentContext!,
                        builder: (_) => const AddFriendPage(),
                      );
                    },
                  ),
                  // 扫一扫
                  if (showScan)
                    BubbleMenu.buildMenuItem(
                      context: context,
                      icon: HugeIcons.strokeRoundedScan,
                      title: 'chat_scan_qr_code'.tr(),
                      textMaxWidth: menuWidth - BubbleMenu.fixedContentWidth,
                      onTap: () {
                        close?.call();
                        Navigator.of(appNavigatorKey.currentContext!).push(
                          MaterialPageRoute(
                            builder: (_) => const ScanQrPage(),
                          ),
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
//             borderRadius: BorderRadius.circular(RadiusToken.md),
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
