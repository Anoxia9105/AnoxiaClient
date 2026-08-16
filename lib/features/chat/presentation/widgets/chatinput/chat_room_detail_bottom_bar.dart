import 'package:anoxia/common/utils/device_util.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/chat_input_field.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/chat_room_detail_status_tag.dart';
import 'package:anoxia/features/chat/presentation/widgets/skeleton/chat_input_skeleton.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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

  const ChatRoomDetailBottomBar({
    super.key,
    required this.showSkeleton,
    this.roomStatus,
    required this.onFieldTap,
  });

  @override
  Widget build(BuildContext context) {
    if (showSkeleton) return const ChatInputSkeleton();

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    /// 桌面布局：真实桌面环境，或宽度超过平板的 Web 页面
    final isDesktop = DeviceUtil.isRealDesktop() ||
        (DeviceUtil.isRealWeb() && DeviceUtil.isDesktop(context));
    final content = switch (roomStatus) {
      0 => ChatInputField(bottomSheet: onFieldTap),
      1 => ChatRoomDetailStatusTag(
        text: 'chat_room_muted'.tr(),
        icon: HugeIcons.strokeRoundedVolumeMute01,
      ),
      2 => const SizedBox.shrink(),
      3 => ChatRoomDetailStatusTag(
        text: 'chat_room_dissolved'.tr(),
        icon: HugeIcons.strokeRoundedDelete02,
      ),
      _ => const SizedBox.shrink(),
    };

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isDesktop ? 50 : 12,
          isDesktop ? 12 : 6,
          isDesktop ? 50 : 12,
          isDesktop ? 16 : 12,
        ),
        child: isDesktop
            ? Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    width: 1,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: content,
              )
            : Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  // 移动端外层为悬浮圆角胶囊：阴影上浮避开屏幕底边，
                  // 与内层输入胶囊（圆角 12 + 描边）形成嵌套层次。
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.35 : 0.14,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: content,
              ),
      ),
    );
  }
}
