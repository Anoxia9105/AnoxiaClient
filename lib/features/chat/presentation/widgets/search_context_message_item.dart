import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/message/search_message_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 单条搜索结果的渲染（头像 + 发送者 + 时间 + 高亮文本/图片缩略图）。
///
/// 从 [SearchContextPage] 拆出，仅依赖传入的 [message]/[index]/[roomId] 与
/// 各 provider，便于独立复用与测试。
class SearchContextMessageItem extends ConsumerWidget {
  const SearchContextMessageItem({
    super.key,
    required this.message,
    required this.index,
    required this.roomId,
  });

  /// 搜索结果消息
  final ChatMessage message;

  /// 在结果列表中的下标（用于判断是否为高亮匹配区间）
  final int index;

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
              : (message.senderId?.toString() ?? 'search_unknown'.tr()))
        : ((senderMember?.nickName?.trim().isNotEmpty == true)
              ? senderMember!.nickName!.trim()
              : (message.senderId?.toString() ?? 'search_unknown'.tr()));
    final String? avatarUrl = isCurrentUser
        ? currentUser?.avatar
        : senderMember?.avatar;
    final String? senderMeta = message.senderId != null
        ? 'ID: ${message.senderId}'
        : null;

    // 判断是否在高亮范围内
    final searchState = ref.read(searchMessageServiceProvider);
    bool isHighlighted =
        index >= searchState.firstMatchIndex &&
        index <= searchState.lastMatchIndex;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isDesktop ? 16 : 12,
        vertical: isDesktop ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: isHighlighted
            ? colorScheme.primary.withValues(alpha: 0.08)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        border: Border.all(
          color: isHighlighted
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: isHighlighted ? 1.5 : 0.8,
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
                  if (senderMeta != null) ...[
                    Text(
                      senderMeta,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.outline.withValues(alpha: 0.75),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                  ],
                  // 消息内容（根据消息类型显示）
                  _buildMessageContent(
                    context,
                    message,
                    colorScheme,
                    textTheme,
                    ref.read(searchMessageServiceProvider).keyword,
                  ),
                ],
              ),
            ),
            // 高亮指示器
            if (isHighlighted) ...[
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
    String keyword,
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
            if (chatMessage.content.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              _buildHighlightedText(
                chatMessage.content,
                keyword,
                colorScheme,
                textTheme,
                maxLines: 2,
              ),
            ],
          ],
        );
      } else {
        return Text(
          'search_image_placeholder'.tr(),
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            fontStyle: FontStyle.italic,
          ),
        );
      }
    }

    // 其他消息类型：显示文本内容（带高亮）
    return _buildHighlightedText(
      chatMessage.content,
      keyword,
      colorScheme,
      textTheme,
      maxLines: 3,
    );
  }

  /// 构建高亮文本
  Widget _buildHighlightedText(
    String text,
    String keyword,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    int maxLines = 3,
  }) {
    if (keyword.isEmpty || !text.contains(keyword)) {
      return Text(
        text,
        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    // 使用手动查找替换而不是 RegExp.split
    final spans = <TextSpan>[];
    int lastIndex = 0;

    // 查找所有匹配的关键词位置
    while (true) {
      // 不区分大小写的查找（对于中文实际上没区别）
      int index = text.indexOf(keyword, lastIndex);

      if (index == -1) {
        // 没有找到，添加剩余的文本
        if (lastIndex < text.length) {
          spans.add(
            TextSpan(
              text: text.substring(lastIndex),
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          );
        }
        break;
      }

      // 添加关键词之前的文本
      if (index > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex, index),
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
          ),
        );
      }

      // 添加高亮的关键词
      spans.add(
        TextSpan(
          text: keyword,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onPrimary,
            backgroundColor: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

      // 更新位置
      lastIndex = index + keyword.length;
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 格式化时间
  String _formatTime(int? timestamp) {
    if (timestamp == null) return '';
    final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('HH:mm').format(dateTime);
  }
}
