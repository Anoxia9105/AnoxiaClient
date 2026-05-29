import 'package:flutter/material.dart';

import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/SkeletonBox.dart';

/// 聊天输入框骨架屏
class ChatInputSkeleton extends StatelessWidget {
  const ChatInputSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return DeviceUtil.isRealDesktop()
        ? const _DesktopChatInputSkeleton()
        : const _MobileChatInputSkeleton();
  }
}

/// =========================
/// Desktop Skeleton
/// =========================
class _DesktopChatInputSkeleton extends StatelessWidget {
  const _DesktopChatInputSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(50, 0, 50, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            width: 1,
            color: colorScheme.onSurface.withValues(alpha: 0.1),
          ),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: SkeletonBox(height: 18, radius: 9)),

                SizedBox(width: 12),

                SkeletonBox(width: 22, height: 22, circle: true),

                SizedBox(width: 8),

                SkeletonBox(width: 22, height: 22, circle: true),
              ],
            ),

            SizedBox(height: 8),

            Align(
              alignment: Alignment.centerLeft,
              child: SkeletonLine(width: 120, height: 10),
            ),
          ],
        ),
      ),
    );
  }
}

/// =========================
/// Mobile Skeleton
/// =========================
class _MobileChatInputSkeleton extends StatelessWidget {
  const _MobileChatInputSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          /// 左侧语音按钮
          const SkeletonBox(width: 40, height: 40, radius: 8),

          const SizedBox(width: 6),

          /// 输入框区域
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.centerLeft,
              child: const SkeletonLine(width: 140, height: 14, radius: 7),
            ),
          ),

          const SizedBox(width: 6),

          /// 表情按钮
          const SkeletonBox(width: 40, height: 40, radius: 8),

          const SizedBox(width: 6),

          /// 更多/发送按钮
          const SkeletonBox(width: 40, height: 40, radius: 8),
        ],
      ),
    );
  }
}
