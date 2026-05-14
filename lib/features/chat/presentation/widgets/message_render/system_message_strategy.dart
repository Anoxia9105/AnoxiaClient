import 'package:anoxia/common/utils/DateUtil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../../framework/domain/ChatMessage.dart';
import 'base/message_render_strategy.dart';

/// 系统消息渲染策略
/// 用于渲染各种系统消息，如创建房间、加入房间、离开房间等
class SystemMessageStrategy extends MessageRenderStrategy {
  @override
  Widget buildContent(
    BuildContext context,
    ChatMessage message,
    Color textColor,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
        child: _buildSystemMessage(context, message),
      ),
    );
  }

  /// 根据 action 解析图标 + 文本
  Widget _buildSystemMessage(BuildContext context, ChatMessage message) {
    if (message.extra['action'] == null) {
      return _buildChip(
        context,
        icon: HugeIcons.strokeRoundedSettingsError02,
        text: 'system_msg_unknown'.tr(),
        timestamp: message.timestamp,
      );
    }

    final type = message.extra['action'];

    final (dynamic icon, String text) = switch (type) {
      'ROOM_CREATED_GROUP' => (
        HugeIcons.strokeRoundedHome03,
        'system_msg_invite'.tr(
          namedArgs: {
            'nickName': message.extra['nickName'] ?? '',
            'names': message.extra['names'] ?? '',
          },
        ),
      ),
      'ROOM_MUTED' => (
        message.extra['isMute'] == true
            ? HugeIcons.strokeRoundedVolumeMute01
            : HugeIcons.strokeRoundedVolumeHigh,
        message.extra['isMute'] == true
            ? 'system_msg_mute_on'.tr()
            : 'system_msg_mute_off'.tr(),
      ),
      'USER_KICKED' => (
        HugeIcons.strokeRoundedUserRemove02,
        'system_msg_kicked'.tr(
          namedArgs: {'nickName': message.extra['nickName'] ?? ''},
        ),
      ),
      'ROOM_CLOSED' => (
        HugeIcons.strokeRoundedHome03,
        'system_msg_room_closed'.tr(),
      ),
      'MESSAGE_RECALL' => (
        HugeIcons.strokeRoundedUndo,
        'system_msg_recall'.tr(args: [message.extra['nickName'] ?? '--']),
      ),
      'CALL_STARTED' => (
        HugeIcons.strokeRoundedCall02,
        'system_msg_callstart'.tr(args: [message.extra['nickName'] ?? '--']),
      ),
      'CALL_ENDED' => (
        HugeIcons.strokeRoundedCallEnd03,
        'system_msg_callend'.tr(args: [message.extra['durationText'] ?? '--']),
      ),
      'ROOM_DISSOLVED' => (
        HugeIcons.strokeRoundedCancel01,
        message.extra['type'] == 'ban'
            ? 'system_msg_room_banned'.tr()
            : 'system_msg_room_closed'.tr(),
      ),
      'ROOM_CREATED' when message.extra['type'] == 'unban' => (
        HugeIcons.strokeRoundedHome03,
        'system_msg_room_unbanned'.tr(),
      ),
      _ => (null, ''),
    };

    if (icon == null) return const SizedBox.shrink();

    return _buildChip(
      context,
      icon: icon,
      text: text,
      timestamp: message.timestamp,
    );
  }

  /// 居中气泡式系统消息
  Widget _buildChip(
    BuildContext context, {
    required dynamic icon,
    required String text,
    required int? timestamp,
  }) {
    final cs = Theme.of(context).colorScheme;
    final fgColor = cs.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, size: 14, color: fgColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: fgColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            DateUtil.formatTimestampToTime(timestamp),
            style: TextStyle(
              fontSize: 10,
              color: fgColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
