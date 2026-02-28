import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:livekit_client/livekit_client.dart';

/// 屏幕共享状态栏组件
/// 当本地参与者共享屏幕时显示专用状态栏，提示用户正在共享
/// 包含停止共享的快速操作按钮
class ScreenShareStatusBar extends StatelessWidget {
  final Room room;
  final VoidCallback onStopScreenShare;

  const ScreenShareStatusBar({
    super.key,
    required this.room,
    required this.onStopScreenShare,
  });

  /// 检查本地参与者是否正在共享屏幕
  bool _isLocalScreenSharing() {
    final localParticipant = room.localParticipant;
    if (localParticipant == null) return false;

    return localParticipant.videoTrackPublications
        .any((pub) => pub.isScreenShare && !pub.muted);
  }

  @override
  Widget build(BuildContext context) {
    // 只在正在共享屏幕时显示
    if (!_isLocalScreenSharing()) {
      return SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade700,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左侧：图标和文字
          Expanded(
            child: Row(
              children: [
                // 闪烁的屏幕共享图标
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: 0.4),
                  duration: const Duration(milliseconds: 1000),
                  onEnd: () {}, // 让动画持续循环
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Icon(
                        Icons.screen_share,
                        color: Colors.white,
                        size: 20,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                // 文字提示
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'call_screen_sharing'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'call_screen_sharing_hint'.tr(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 右侧：停止按钮
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onStopScreenShare,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.stop_circle_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'call_stop_sharing'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
