import 'dart:math';

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
  /// 菜单项图标宽度
  static const double _iconWidth = 16;

  /// 图标与文案之间的间距
  static const double _iconGap = 8;

  /// 菜单项水平内边距
  static const double _itemHPadding = 8;

  /// 气泡内容容器水平内边距
  static const double _containerHPadding = 3;

  /// 除文案外菜单项占用的固定宽度（图标 + 间距 + 各项水平内边距）
  static const double _fixedContentWidth =
      _iconWidth + _iconGap + _itemHPadding * 2 + _containerHPadding * 2;

  /// 显示右上角菜单对话框
  ///
  /// 根据设备类型（移动端/桌面端）调整菜单的位置和样式，
  /// 提供创建群聊和添加好友的入口
  ///
  /// [context] 构建上下文
  /// [ref] 可选的回调函数，用于处理添加好友对话框
  static void showTopRightDialog(BuildContext context, {Function? ref}) {
    Function? close;
    // UI 布局按宽度断点判定（Web 窄屏等同移动端），而非 isRealMobile()，
    // 否则 Web 上缩小窗口后气泡角与菜单形态仍停留在桌面端。
    bool isMobile = DeviceUtil.isMobile(context);
    // Web 无摄像头扫码能力，隐藏"扫一扫"入口
    final showScan = isMobile && !DeviceUtil.isRealWeb();

    // 气泡宽度自适应最长文案（中文短、日/英文长），避免文字溢出报错；
    // 超出上限时由文案省略号兜底
    final menuWidth = _measureMenuWidth(
      context,
      titles: [
        'chat_create_group'.tr(),
        'chat_add_friend'.tr(),
        if (showScan) 'chat_scan_qr_code'.tr(),
      ],
      maxWidth: isMobile ? 200 : 220,
    );

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
            // 气泡宽度随文案自适应，移动端箭头偏移跟随宽度，保持指向右上角按钮
            arrowOffset: isMobile ? menuWidth + 34 : 25,
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
              // 2. 宽度自适应最长文案，所有菜单项等宽、内容统一居中
              width: menuWidth,
              padding: const EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 3,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 创建群聊
                  _buildMenuItem(
                    context: context,
                    icon: HugeIcons.strokeRoundedChatting01,
                    title: 'chat_create_group'.tr(),
                    textMaxWidth: menuWidth - _fixedContentWidth,
                    onTap: () {
                      close?.call();
                      if (isMobile) {
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
                    textMaxWidth: menuWidth - _fixedContentWidth,
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
                    _buildMenuItem(
                      context: context,
                      icon: HugeIcons.strokeRoundedScan,
                      title: 'chat_scan_qr_code'.tr(),
                      textMaxWidth: menuWidth - _fixedContentWidth,
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

  /// 测量菜单气泡宽度：取所有文案中的最大宽度，加上图标与内边距，
  /// 并以 [maxWidth] 为上限。
  static double _measureMenuWidth(
    BuildContext context, {
    required List<String> titles,
    required double maxWidth,
  }) {
    // 与 _buildMenuItem 中 Text 的样式保持一致
    const style = TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400);
    final textScaler = MediaQuery.textScalerOf(context);
    var maxTextWidth = 0.0;
    for (final title in titles) {
      final painter = TextPainter(
        text: TextSpan(text: title, style: style),
        textDirection: Directionality.of(context),
        textScaler: textScaler,
      )..layout();
      if (painter.width > maxTextWidth) maxTextWidth = painter.width;
    }
    return min(maxWidth, maxTextWidth + _fixedContentWidth);
  }

  static Widget _buildMenuItem({
    required BuildContext context,
    required dynamic icon,
    required String title,
    required double textMaxWidth,
    required VoidCallback onTap,
  }) {
    final color = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _itemHPadding,
          vertical: 7,
        ),
        child: Row(
          // 所有菜单项等宽，内容统一水平居中，避免长文案左对齐、短文案居中
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: icon,
              size: _iconWidth,
              color: color.withValues(alpha: 0.85),
            ),
            const SizedBox(width: _iconGap),
            // 限制文案最大宽度：正常情况下恰好等于最宽文案，超上限时省略号兜底
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: textMaxWidth),
              child: Text(
                title,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: color,
                ),
              ),
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
