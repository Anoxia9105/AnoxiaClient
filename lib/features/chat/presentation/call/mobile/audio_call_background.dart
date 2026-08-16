import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 音频通话背景组件
///
/// 渐变主题背景由外层统一绘制（见 MobileCallPage），这里只负责
/// 中央对方头像 + 房间名称 + 「语音通话中」内容。
/// 保持简洁：无装饰光球、无图标圆环，头像即视觉中心。
class AudioCallBackground extends StatelessWidget {
  const AudioCallBackground({
    super.key,
    required this.title,
    this.avatarUrl = '',
  });

  final String title;
  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final scale = (MediaQuery.sizeOf(context).width / 375).clamp(0.85, 1.1);

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 116),
        child: Column(
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
            Text(
              'call_voice_call_in_progress'.tr(),
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 13 * scale,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
