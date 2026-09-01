import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:flutter/material.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 好友请求列表项组件
///
/// 显示单个好友请求的头像、昵称、验证消息和时间，卡片式布局，
/// 支持悬停高亮（桌面端）。
class NewFriendsRequestTile extends StatefulWidget {
  final String avatar;
  final String nickName;
  final String remark;
  final String createdAtText;
  final Widget trailing;

  const NewFriendsRequestTile({
    super.key,
    required this.avatar,
    required this.nickName,
    required this.remark,
    required this.createdAtText,
    required this.trailing,
  });

  @override
  State<NewFriendsRequestTile> createState() => _NewFriendsRequestTileState();
}

class _NewFriendsRequestTileState extends State<NewFriendsRequestTile> {
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AvatarWidget(
              url: widget.avatar,
              name: widget.nickName,
              size: 44,
              borderRadius: 12,
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
                          widget.nickName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      if (widget.createdAtText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            widget.createdAtText,
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
                  if (widget.remark.isNotEmpty)
                    Text(
                      widget.remark,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            widget.trailing,
          ],
        ),
      ),
    );
  }
}
