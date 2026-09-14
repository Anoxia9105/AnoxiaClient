import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 音频通话背景组件
///
/// 渐变主题背景由外层统一绘制（见 MobileCallPage），这里只负责
/// 中央对方头像 + 房间名称 + 「语音通话中」内容。
/// 保持简洁：无装饰光球、无图标圆环，头像即视觉中心。
///
/// 矮屏（手机 Web 横屏等）切换为左右排版，避免竖向内容超出可视高度。
class AudioCallBackground extends StatelessWidget {
  const AudioCallBackground({
    super.key,
    required this.title,
    this.avatarUrl = '',
    this.participantCount = 0,
  });

  final String title;

  final String avatarUrl;

  /// 通话中的人数（含自己）；小于等于 2 时不展示，避免 1:1 场景冗余
  final int participantCount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    // 横屏时按短边缩放：按宽度会让头像在横屏下被异常放大
    final scale = (size.shortestSide / 375).clamp(0.85, 1.1).toDouble();
    final isShortScreen = size.width > size.height && size.height < 560;

    return Center(
      child: Padding(
        padding: EdgeInsets.only(bottom: isShortScreen ? 24 : 116),
        child: isShortScreen
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AvatarWidget(size: 68 * scale, url: avatarUrl, name: title),
                  const SizedBox(width: 18),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 20 * scale,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _StatusText(
                          participantCount: participantCount,
                          scale: scale,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AvatarWidget(
                    size: 96 * scale,
                    url: avatarUrl,
                    name: title,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 22 * scale,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _StatusText(participantCount: participantCount, scale: scale),
                ],
              ),
      ),
    );
  }
}

/// 语音通话状态文案：多方通话时补充「N 人在通话」
class _StatusText extends StatelessWidget {
  const _StatusText({required this.participantCount, required this.scale});

  final int participantCount;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = participantCount > 2
        ? 'call_n_in_call'.tr(namedArgs: {'count': '$participantCount'})
        : 'call_voice_call_in_progress'.tr();
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13 * scale),
    );
  }
}
