import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/framework/theme/app_colors.dart';
import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 会话详情档案头（纯展示，不承载任何操作入口）
///
/// - 群聊：大头像 + 在线点 + 群名（+管理员徽章）+「共 N 人 · M 在线」
/// - 单聊：大头像 + 在线点 + 备注名 + 在线状态徽章
/// - 不展示群号 / 用户 ID（评审结论）
class RoomDetailHero extends StatelessWidget {
  final String? avatarUrl;
  final String displayName;
  final bool isGroup;
  final int memberTotal;
  final int onlineCount;
  final bool isAdmin;
  final bool peerOnline;

  const RoomDetailHero({
    super.key,
    required this.avatarUrl,
    required this.displayName,
    required this.isGroup,
    required this.memberTotal,
    required this.onlineCount,
    required this.isAdmin,
    this.peerOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(RadiusToken.xl),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.38),
            colorScheme.primaryContainer.withValues(alpha: 0.12),
          ],
        ),
      ),
      child: Row(
        children: [
          AvatarWidget(
            url: avatarUrl,
            name: displayName,
            size: 56,
            borderRadius: RadiusToken.xl,
            status: _avatarStatus(),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                      ),
                    ),
                    if (isGroup && isAdmin) ...[
                      const SizedBox(width: 7),
                      _Badge(
                        text: 'chat_admin'.tr(),
                        filled: true,
                      ),
                    ],
                    if (!isGroup) ...[
                      const SizedBox(width: 7),
                      _Badge(
                        text: peerOnline
                            ? 'contact_online'.tr()
                            : 'contact_offline'.tr(),
                        filled: false,
                      ),
                    ],
                  ],
                ),
                if (isGroup) ...[
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                      children: [
                        TextSpan(
                          text: 'chat_member_total'
                              .tr(args: [memberTotal.toString()]),
                        ),
                        const TextSpan(text: ' · '),
                        TextSpan(
                          text: 'common_online_count'
                              .tr(args: [onlineCount.toString()]),
                          style: TextStyle(
                            color: Theme.of(context)
                                    .extension<AppColors>()
                                    ?.success ??
                                colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  AvatarStatus _avatarStatus() {
    if (isGroup) return AvatarStatus.none;
    return peerOnline ? AvatarStatus.online : AvatarStatus.offline;
  }
}

/// 名称旁的小徽章（管理员实心 / 在线状态柔色）
class _Badge extends StatelessWidget {
  final String text;
  final bool filled;

  const _Badge({required this.text, required this.filled});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2.5),
      decoration: BoxDecoration(
        color: filled
            ? colorScheme.primary
            : colorScheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(RadiusToken.pill),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: filled
                  ? colorScheme.onPrimary
                  : colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w800,
              fontSize: 10.5,
            ),
      ),
    );
  }
}
