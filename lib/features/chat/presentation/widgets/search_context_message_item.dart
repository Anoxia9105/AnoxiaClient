import 'package:anoxia/features/chat/application/message_preview_formatter.dart';
import 'package:anoxia/features/chat/application/system_message_formatter.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 单条搜索结果的渲染（头像 + 发送者 + 时间 + 高亮文本/图片缩略图）。
///
/// 匹配状态与关键词由搜索页面传入。
class SearchContextMessageItem extends ConsumerWidget {
  const SearchContextMessageItem({
    super.key,
    required this.message,
    required this.isHighlighted,
    required this.keyword,
    required this.roomId,
  });

  /// 搜索结果消息
  final ChatMessage message;

  final bool isHighlighted;
  final String keyword;

  /// 所属房间 ID（用于拉取成员以解析昵称/头像）
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bool isDesktop = DeviceUtil.isRealDesktop();
    final currentUser = ref.watch(authControllerProvider).value;
    final members = ref.watch(roomMembersProvider(roomId));
    final senderMember = members
        .where((member) => member.userId == message.senderId)
        .firstOrNull;
    final bool isCurrentUser = message.senderId == currentUser?.userId;
    final String displayName = isCurrentUser
        ? (currentUser?.nickName.trim().isNotEmpty == true
              ? currentUser!.nickName.trim()
              : ('search_unknown'.tr()))
        : ((senderMember?.nickName?.trim().isNotEmpty == true)
              ? senderMember!.nickName!.trim()
              : ('search_unknown'.tr()));
    final String? avatarUrl = isCurrentUser
        ? currentUser?.avatar
        : senderMember?.avatar;

    final pattern = MessagePreviewFormatter.searchPattern(keyword);
    final searchable = MessagePreviewFormatter.searchText(message);
    final match = keyword.isNotEmpty && isHighlighted
        ? pattern.firstMatch(searchable)
        : null;
    final highlighted = match != null;
    final String preview;
    if (match != null) {
      final before = searchable.substring(0, match.start);
      preview = before.length > 24 || before.contains('\n')
          ? '…${searchable.substring(match.start)}'
          : searchable;
    } else if (SystemMessageFormatter.isSystemMessage(message)) {
      final isGroup = ref.watch(
        currentRoomProvider(roomId).select((room) => room?.roomType == 1),
      );
      preview = SystemMessageFormatter.display(message, isGroup: isGroup).text;
    } else {
      preview = MessagePreviewFormatter.format(message);
    }

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isDesktop ? 16 : 12,
        vertical: isDesktop ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: highlighted
            ? colorScheme.primary.withValues(alpha: 0.08)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        border: Border.all(
          color: highlighted
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: highlighted ? 1.5 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户头像
            AvatarWidget(
              size: isDesktop ? 44 : 40,
              url: avatarUrl,
              name: displayName,
              borderRadius: isDesktop ? 22 : 20,
            ),
            const SizedBox(width: 12),
            // 消息内容区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 消息发送者和时间
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.outline,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(message.timestamp),
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.outline.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // 消息内容（根据消息类型显示）
                  _buildMessageContent(
                    context,
                    message,
                    colorScheme,
                    textTheme,
                    preview,
                    highlighted ? pattern : null,
                  ),
                ],
              ),
            ),
            // 高亮指示器
            if (highlighted) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(RadiusToken.sm),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                  size: 16,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建消息内容（根据消息类型显示）
  Widget _buildMessageContent(
    BuildContext context,
    ChatMessage chatMessage,
    ColorScheme colorScheme,
    TextTheme textTheme,
    String preview,
    RegExp? pattern,
  ) {
    // 检查消息类型（image: 1）
    final imageAttachment = chatMessage.payload?.image;
    if (chatMessage.messageType == MessageType.image) {
      // 图片消息：显示附件缩略图
      if (imageAttachment?.url?.isNotEmpty == true) {
        final attachment = imageAttachment!;
        // 缩略图显示尺寸（桌面 160，其余 120），用于限制解码尺寸
        final double imageSize = DeviceUtil.isRealDesktop() ? 160 : 120;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 显示图片缩略图
            ClipRRect(
              borderRadius: BorderRadius.circular(RadiusToken.md),
              child: Image.network(
                attachment.url ?? '',
                width: imageSize,
                height: imageSize,
                // 按显示尺寸×DPR 解码，避免整图（可能上 MB）全量解入内存
                cacheWidth: (imageSize * MediaQuery.devicePixelRatioOf(context))
                    .round(),
                cacheHeight:
                    (imageSize * MediaQuery.devicePixelRatioOf(context))
                        .round(),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stackTrace) {
                  final size = DeviceUtil.isRealDesktop() ? 160.0 : 120.0;
                  return Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(RadiusToken.md),
                    ),
                    child: Center(
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedImageNotFound01,
                        color: colorScheme.outline,
                        size: 32,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (MessagePreviewFormatter.searchText(
                  chatMessage,
                ).trim().isNotEmpty ||
                pattern != null) ...[
              const SizedBox(height: 8),
              _buildHighlightedText(
                preview,
                pattern,
                colorScheme,
                textTheme,
                maxLines: 2,
              ),
            ],
          ],
        );
      } else {
        return _buildHighlightedText(preview, pattern, colorScheme, textTheme);
      }
    }

    // 其他消息类型：显示文本内容（带高亮）
    return _buildHighlightedText(
      preview,
      pattern,
      colorScheme,
      textTheme,
      maxLines: 3,
    );
  }

  /// 构建高亮文本
  Widget _buildHighlightedText(
    String text,
    RegExp? pattern,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    int maxLines = 3,
  }) {
    final style = textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface);
    return Text.rich(
      TextSpan(
        style: style,
        children: pattern == null
            ? [TextSpan(text: text)]
            : _highlightSpans(text, pattern, colorScheme),
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  List<TextSpan> _highlightSpans(
    String text,
    RegExp pattern,
    ColorScheme colors,
  ) {
    final spans = <TextSpan>[];
    var end = 0;
    for (final match in pattern.allMatches(text)) {
      spans.add(TextSpan(text: text.substring(end, match.start)));
      spans.add(
        TextSpan(
          text: match[0],
          style: TextStyle(
            color: colors.onPrimary,
            backgroundColor: colors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      end = match.end;
    }
    spans.add(TextSpan(text: text.substring(end)));
    return spans;
  }

  /// 格式化时间
  String _formatTime(int? timestamp) {
    if (timestamp == null) return '';
    final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('HH:mm').format(dateTime);
  }
}
