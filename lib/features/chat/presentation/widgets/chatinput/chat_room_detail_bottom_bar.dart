import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/chat_input_field.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/chat_room_detail_status_tag.dart';
import 'package:anoxia/features/chat/presentation/widgets/skeleton/chat_input_skeleton.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// 聊天房间详情页底部栏组件
///
/// 根据房间状态显示不同的底部内容：
/// - 正常状态（0）：显示聊天输入框
/// - 全员禁言（1）：显示禁言提示标签
/// - 封禁状态（2）：不显示任何内容
/// - 已解散（3）：显示已解散提示标签
///
/// 支持骨架屏加载状态和键盘自适应布局
class ChatRoomDetailBottomBar extends StatelessWidget {
  /// 是否显示骨架屏
  final bool showSkeleton;

  /// 房间状态码
  ///
  /// - 0：正常
  /// - 1：全员禁言
  /// - 2：封禁
  /// - 3：已解散
  final int? roomStatus;

  /// 输入框点击回调
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
          // 全员禁言
          1 => ChatRoomDetailStatusTag(text: 'chat_room_muted'.tr(), icon: HugeIcons.strokeRoundedVolumeMute01),
          // 封禁
          2 => const SizedBox.shrink(),
          // 已解散
          3 => ChatRoomDetailStatusTag(text: 'chat_room_dissolved'.tr(), icon: HugeIcons.strokeRoundedDelete02),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}
