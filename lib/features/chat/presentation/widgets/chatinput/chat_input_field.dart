import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/mobile/mobile_chat_input.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/desktop_chat_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../framework/provider/chat/room/room_list_service.dart';

/// 聊天输入框组件
///
/// 提供完整的聊天输入功能，包括：
/// - 富文本编辑器（支持加粗、斜体等格式）
/// - 图片/文件上传
/// - @提及用户
/// - 表情选择
/// - 粘贴图片支持
/// - 桌面端/移动端适配（Android 使用简化输入框）
class ChatInputField extends ConsumerWidget {
  final VoidCallback bottomSheet;

  const ChatInputField({super.key, required this.bottomSheet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomId = ref.watch(activeRoomIdProvider);
    if (roomId == null) return const SizedBox.shrink();

    /// 根据设备类型选择不同的输入组件。
    ///
    /// 布局按屏幕宽度（响应式）决定，而不是按“真实移动设备”判断：
    /// Web 上的窄窗口 / 手机浏览器 isRealMobile() 永远为 false，会错误地
    /// 一直使用桌面端输入框。平台能力（窗口插件等）用 isRealMobile，
    /// UI 布局用宽度断点（与 chat_page.dart 保持一致）。
    if (DeviceUtil.isRealMobile() || DeviceUtil.isMobile(context)) {
      return MobileChatInput(
        key: ValueKey('mobile_$roomId'),
        roomId: roomId,
        bottomSheet: bottomSheet,
      );
    }

    return DesktopChatInput(
      key: ValueKey('desktop_$roomId'),
      roomId: roomId,
      bottomSheet: bottomSheet,
    );
  }
}
