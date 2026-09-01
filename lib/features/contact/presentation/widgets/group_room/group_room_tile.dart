import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/common/widgets/vibrating_badge.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 群聊列表项组件
///
/// 卡片式布局展示群聊头像、名称、最新消息、成员数和未读数，支持悬停高亮。
class GroupRoomTile extends StatefulWidget {
  final String avatar;
  final String roomName;
  final String subtitle;
  final String lastMessageAt;
  final int unreadCount;
  final int memberCount;
  final VoidCallback? onTap;

  const GroupRoomTile({
    super.key,
    required this.avatar,
    required this.roomName,
    required this.subtitle,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.memberCount,
    this.onTap,
  });

  @override
  State<GroupRoomTile> createState() => _GroupRoomTileState();
}

class _GroupRoomTileState extends State<GroupRoomTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          color: _hovered
              ? cs.surfaceContainerHighest.withValues(alpha: isDark ? 0.5 : 0.6)
              : cs.surface,
          borderRadius: BorderRadius.circular(RadiusToken.xl),
          border: Border.all(
            color: _hovered
                ? cs.primary.withValues(alpha: 0.35)
                : cs.outlineVariant.withValues(alpha: 0.55),
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(RadiusToken.xl),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AvatarWidget(
                url: widget.avatar,
                name: widget.roomName,
                size: 48,
                borderRadius: 14,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.roomName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        if (widget.lastMessageAt.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              widget.lastMessageAt,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant.withValues(
                                  alpha: 0.75,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedUserMultiple,
                          size: 12,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'group_card_member_count'.tr(
                            args: [widget.memberCount.toString()],
                          ),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              VibratingBadge(count: widget.unreadCount),
            ],
          ),
        ),
      ),
    );
  }
}
