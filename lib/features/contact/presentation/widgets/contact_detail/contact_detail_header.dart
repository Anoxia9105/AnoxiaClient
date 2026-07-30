import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:flutter/material.dart';

/// 联系人详情头部组件
///
/// 展示联系人大头像、昵称、备注和在线状态，带渐变背景
class ContactDetailHeader extends StatelessWidget {
  final String? avatar;
  final String? nickName;
  final String? remark;
  final bool isOnline;

  const ContactDetailHeader({
    super.key,
    this.avatar,
    this.nickName,
    this.remark,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.3),
            colorScheme.surface,
          ],
        ),
      ),
      child: Column(
        children: [
          AvatarWidget(
            url: avatar,
            name: nickName,
            size: 96,
            borderRadius: 16,
            status: isOnline ? AvatarStatus.online : AvatarStatus.offline,
          ),
          const SizedBox(height: 14),
          Text(
            nickName ?? '',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          if (remark != null && remark!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              remark!,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}