import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/chat_input_field.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/chat_room_detail_status_tag.dart';
import 'package:anoxia/features/chat/presentation/widgets/skeleton/chat_input_skeleton.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// 聊天房间详情页底部栏
class ChatRoomDetailBottomBar extends StatelessWidget {
  final bool showSkeleton;
  final int? roomStatus;
  final VoidCallback onFieldTap;
  const ChatRoomDetailBottomBar({super.key, required this.showSkeleton, this.roomStatus, required this.onFieldTap});

  @override
  Widget build(BuildContext context) {
    if (showSkeleton) return const ChatInputSkeleton();

    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          left: DeviceUtil.isRealDesktop() ? 50 : 0,
          right: DeviceUtil.isRealDesktop() ? 50 : 0,
          bottom: (keyboardInset > 0 ? keyboardInset : 0),
        ),
        child: switch (roomStatus) {
          0 => ChatInputField(bottomSheet: onFieldTap),
          /// 全员禁言
          1 => ChatRoomDetailStatusTag(text: 'chat_room_muted'.tr(), icon: HugeIcons.strokeRoundedVolumeMute01),
          /// 封禁
          2 => const SizedBox.shrink(),
          /// 解散
          3 => ChatRoomDetailStatusTag(text: 'chat_room_dissolved'.tr(), icon: HugeIcons.strokeRoundedDelete02),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}