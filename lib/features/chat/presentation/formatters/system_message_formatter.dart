import 'package:anoxia/framework/domain/ChatMessage.dart';
import 'package:anoxia/framework/protocol/message/MessageEunm.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hugeicons/hugeicons.dart';

class SystemMessageDisplay {
  const SystemMessageDisplay({
    required this.action,
    required this.icon,
    required this.text,
  });

  final String action;
  final dynamic icon;
  final String text;
}

class SystemMessageFormatter {
  static const Set<String> _knownActions = {
    'ROOM_CREATED',
    'ROOM_CREATED_GROUP',
    'USER_JOINED',
    'USER_LEFT',
    'USER_KICKED',
    'ROOM_DISSOLVED',
    'ROOM_CLOSED',
    'ROOM_MUTED',
    'ROOM_UNMUTED',
    'ROOM_UPDATED',
    'MESSAGE_RECALL',
    'CALL_STARTED',
    'CALL_ENDED',
  };

  static bool isSystemMessage(ChatMessage? message) {
    if (message == null) return false;
    return message.messageType == MessageType.system ||
        actionOf(message) != null;
  }

  static String previewText(ChatMessage? message) {
    if (!isSystemMessage(message)) return message?.content ?? '';
    return 'system_msg_preview'.tr();
  }

  static SystemMessageDisplay display(ChatMessage message) {
    final action = actionOf(message);
    if (action == null) {
      return SystemMessageDisplay(
        action: 'UNKNOWN',
        icon: HugeIcons.strokeRoundedSettingsError02,
        text: 'system_msg_unknown'.tr(),
      );
    }

    return switch (action) {
      'ROOM_CREATED_GROUP' || 'USER_JOINED' => SystemMessageDisplay(
        action: action,
        icon: HugeIcons.strokeRoundedHome03,
        text: 'system_msg_invite'.tr(
          namedArgs: {
            'nickName': message.properties['nickName'] ?? '',
            'names': message.properties['names'] ?? '',
          },
        ),
      ),
      'ROOM_MUTED' => SystemMessageDisplay(
        action: action,
        icon: message.properties['isMute'] == 'true'
            ? HugeIcons.strokeRoundedVolumeMute01
            : HugeIcons.strokeRoundedVolumeHigh,
        text: message.properties['isMute'] == 'true'
            ? 'system_msg_mute_on'.tr()
            : 'system_msg_mute_off'.tr(),
      ),
      'ROOM_UNMUTED' => SystemMessageDisplay(
        action: action,
        icon: HugeIcons.strokeRoundedVolumeHigh,
        text: 'system_msg_mute_off'.tr(),
      ),
      'USER_KICKED' => SystemMessageDisplay(
        action: action,
        icon: HugeIcons.strokeRoundedUserRemove02,
        text: 'system_msg_kicked'.tr(
          namedArgs: {'nickName': message.properties['nickName'] ?? ''},
        ),
      ),
      'ROOM_CLOSED' => SystemMessageDisplay(
        action: action,
        icon: HugeIcons.strokeRoundedHome03,
        text: 'system_msg_room_closed'.tr(),
      ),
      'MESSAGE_RECALL' => SystemMessageDisplay(
        action: action,
        icon: HugeIcons.strokeRoundedUndo,
        text: 'system_msg_recall'.tr(
          args: [message.properties['nickName'] ?? '--'],
        ),
      ),
      'CALL_STARTED' => SystemMessageDisplay(
        action: action,
        icon: HugeIcons.strokeRoundedCall02,
        text: 'system_msg_callstart'.tr(
          args: [message.properties['nickName'] ?? '--'],
        ),
      ),
      'CALL_ENDED' => SystemMessageDisplay(
        action: action,
        icon: HugeIcons.strokeRoundedCallEnd03,
        text: 'system_msg_callend'.tr(
          args: [message.properties['durationText'] ?? '--'],
        ),
      ),
      'ROOM_DISSOLVED' => SystemMessageDisplay(
        action: action,
        icon: HugeIcons.strokeRoundedCancel01,
        text: message.properties['type'] == 'ban'
            ? 'system_msg_room_banned'.tr()
            : 'system_msg_room_closed'.tr(),
      ),
      'ROOM_UPDATED' when message.properties['field'] == 'announcement' =>
        SystemMessageDisplay(
          action: action,
          icon: HugeIcons.strokeRoundedMegaphone01,
          text: 'system_msg_room_announcement_updated'.tr(
            namedArgs: {'nickName': message.properties['nickName'] ?? '--'},
          ),
        ),
      'ROOM_UPDATED' => SystemMessageDisplay(
        action: action,
        icon: HugeIcons.strokeRoundedEdit01,
        text: 'system_msg_room_updated'.tr(
          namedArgs: {
            'nickName': message.properties['nickName'] ?? '--',
            'oldName': message.properties['oldName'] ?? '--',
            'newName': message.properties['newName'] ?? '--',
          },
        ),
      ),
      'ROOM_CREATED' when message.properties['type'] == 'unban' =>
        SystemMessageDisplay(
          action: action,
          icon: HugeIcons.strokeRoundedHome03,
          text: 'system_msg_room_unbanned'.tr(),
        ),
      _ => SystemMessageDisplay(
        action: action,
        icon: HugeIcons.strokeRoundedSettingsError02,
        text: 'system_msg_unknown'.tr(),
      ),
    };
  }

  static String? actionOf(ChatMessage message) {
    final propertyAction = message.properties['action'];
    final candidates = [
      propertyAction,
      message.payload?.content,
      message.content,
    ];

    for (final candidate in candidates) {
      final action = _normalizeAction(candidate);
      if (action != null) return action;
    }
    return null;
  }

  static String? _normalizeAction(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    return _knownActions.contains(normalized) ? normalized : null;
  }
}
