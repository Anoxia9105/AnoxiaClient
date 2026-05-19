import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/BubbleDialog.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/features/chat/presentation/widgets/create_chat_dialog_widget.dart';
import 'package:anoxia/features/contact/presentation/pages/add_friend_page.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

class RoomListDialogMenus {
    /// 显示添加房间/好友的详情菜单
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
            arrowOffset: isMobile ? 180 : 25,
            backgroundColor: Theme.of(context).colorScheme.surface,
            border: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 0.5,
            ),
            contentBuilder: (context) => Container(
              constraints: BoxConstraints(maxWidth: isMobile ? 200 : 220, maxHeight: 600),
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
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
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
                        close?.call();
                        if (ref != null) {
                          // 这里可以回调处理 showAddFriendDialog
                          ref(context);
                        }
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


  
void _showAddFriendDialog(BuildContext context, WidgetRef ref) {
    final isDesktop = DeviceUtil.isRealDesktop();
    final dialogWidth = isDesktop ? 900.0 : 400.0;
    final dialogHeight = isDesktop ? 700.0 : 600.0;

    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.7),
              width: 1,
            ),
          ),
          child: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: const AddFriendPage(),
          ),
        );
      },
    );
  }
}