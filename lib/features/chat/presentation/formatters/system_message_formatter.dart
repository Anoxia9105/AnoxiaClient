/// 系统消息格式化工具，负责将聊天中的系统消息解析为可展示的图标和文本。
///
/// 支持房间创建/解散、成员加入/离开/踢出、禁言/解禁、消息撤回、通话开始/结束/拒绝等系统消息类型的格式化。
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hugeicons/hugeicons.dart';

/// 系统消息展示数据
///
/// 包含系统消息的动作类型、图标和国际化后的展示文本。
class SystemMessageDisplay {
  const SystemMessageDisplay({
    required this.action,
    required this.icon,
    required this.text,
  });

  /// 系统消息动作类型，如 ROOM_CREATED、USER_JOINED 等
  final String action;

  /// 对应的图标，支持 IconData 或 HugeIcon 类型
  final dynamic icon;

  /// 国际化后的展示文本
  final String text;
}

/// 系统消息格式化器
///
/// 提供静态方法判断消息是否为系统消息、生成预览文本、
/// 以及根据消息内容解析出对应的 [SystemMessageDisplay] 展示数据。
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
    'CALL_REJECTED',
  };

  /// 判断消息是否为系统消息
  ///
  /// [message] 待判断的消息，为 null 时返回 false。
  static bool isSystemMessage(ChatMessage? message) {
    if (message == null) return false;
    return message.messageType == MessageType.system ||
        actionOf(message) != null;
  }

  /// 生成消息预览文本
///
/// 系统消息返回统一的预览占位符，普通消息返回原始内容。
static String previewText(ChatMessage? message) {
    if (!isSystemMessage(message)) return message?.content ?? '';
    return 'system_msg_preview'.tr();
  }

  /// 解析系统消息并返回展示数据
///
/// 根据消息的动作类型和属性，匹配对应的图标和国际化文本。
/// [message] 待解析的聊天消息。
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
      'CALL_REJECTED' => SystemMessageDisplay(
        action: action,
        icon: HugeIcons.strokeRoundedCallEnd03,
        text: '${message.properties['nickName'] ?? '--'} 拒绝了通话',
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

  /// 从消息中提取系统动作类型
///
/// 依次尝试从消息的 properties、payload.content、content 中提取动作类型，
/// 返回匹配已知动作类型的标准化字符串，无匹配时返回 null。
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
