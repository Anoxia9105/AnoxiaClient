/// 系统消息格式化工具，负责将聊天中的系统消息解析为可展示的图标和文本。
///
/// 支持房间创建/解散、成员加入/离开/踢出、禁言/解禁、消息撤回、通话开始/结束/拒绝等系统消息类型的格式化。
///
/// 该文件位于 application 层，供 provider（数据层）和 presentation 层共同使用，
/// 避免 presentation 层代码被导入到 provider 中。
library;

import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:easy_localization/easy_localization.dart';

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
    'CALL_CANCELED',
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
  /// [message] 待解析的系统消息。
  /// [isGroup] 当前会话是否为群聊：仅影响「通话开始」文案——
  /// 1:1 显示「xx 发起了通话」，群聊（会议）显示「xx 开启了会议」。
  /// 未知会话类型（如收藏页按消息单独渲染）按 1:1 处理，
  /// 「发起了通话」对单聊与群聊都成立，不会出现语义错误。
  static SystemMessageDisplay display(
    ChatMessage message, {
    bool isGroup = false,
  }) {
    final action = actionOf(message);
    if (action == null) {
      return SystemMessageDisplay(
        action: 'UNKNOWN',
        icon: HugeIcons.strokeRoundedSettingsError02,
        text: 'system_msg_unknown'.tr(),
      );
    }

    return switch (action) {
      // 通过分享群聊卡片进入：展示“xx 通过分享进入群聊”
      'USER_JOINED' when message.properties['viaShare'] == 'true' =>
        SystemMessageDisplay(
          action: action,
          icon: HugeIcons.strokeRoundedHome03,
          text: 'system_msg_join_via_share'.tr(
            namedArgs: {'names': message.properties['names'] ?? ''},
          ),
        ),
      // 自由加入群聊（无审批）：操作人与加入人是同一人，展示“xx 加入了房间”
      'USER_JOINED'
          when message.properties['names'] == message.properties['nickName'] &&
              (message.properties['nickName'] ?? '').isNotEmpty =>
        SystemMessageDisplay(
          action: action,
          icon: HugeIcons.strokeRoundedHome03,
          text: 'system_msg_joined'.tr(
            namedArgs: {'nickName': message.properties['nickName'] ?? ''},
          ),
        ),
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
      'USER_LEFT' => SystemMessageDisplay(
        action: action,
        icon: HugeIcons.strokeRoundedLogout01,
        text: 'system_msg_left'.tr(
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
        text: callStartedText(message.properties, isGroup: isGroup),
      ),
      'CALL_ENDED' => SystemMessageDisplay(
        action: action,
        icon: HugeIcons.strokeRoundedCallEnd03,
        text: callEndedText(message.properties, isGroup: isGroup),
      ),
      'CALL_REJECTED' => SystemMessageDisplay(
        action: action,
        icon: HugeIcons.strokeRoundedCallEnd03,
        text: 'system_msg_call_rejected'.tr(
          namedArgs: {'nickName': message.properties['nickName'] ?? '--'},
        ),
      ),
      'CALL_CANCELED' => SystemMessageDisplay(
        action: action,
        icon: HugeIcons.strokeRoundedCallEnd03,
        text: 'system_msg_call_cancelled'.tr(
          namedArgs: {'nickName': message.properties['nickName'] ?? '--'},
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
      'ROOM_CREATED' => SystemMessageDisplay(
        action: action,
        icon: HugeIcons.strokeRoundedHome03,
        text: 'system_msg_room_created'.tr(),
      ),
      _ => SystemMessageDisplay(
          action: action,
          icon: HugeIcons.strokeRoundedSettingsError02,
          text: 'system_msg_unknown'.tr(),
        ),
    };
  }

  /// 通话开始文案
  ///
  /// 1:1 是「xx 发起了通话」，群聊（会议）才是「xx 开启了会议」。
  /// 服务端下发的 action/nickName 不区分会话类型，因此这里由 [isGroup] 决定，
  /// 而不是笼统地用「开启了会议」。
  ///
  /// public：通话开始的桌面通知横幅等处复用同一套文案，避免出现第二种说法。
  static String callStartedText(
    Map<String, String> properties, {
    required bool isGroup,
  }) {
    final nickName = properties['nickName'] ?? '--';
    return isGroup
        ? 'system_msg_callstart'.tr(args: [nickName])
        : 'system_msg_callstart_single'.tr(args: [nickName]);
  }

  /// 通话结束文案
  ///
  /// 有通话时长时带时长展示；缺失时长（历史缓存的老数据、0 秒通话等）时只报结束，
  /// 避免出现「通话已结束 --」这类残缺文案。同样按会话类型分口径：
  /// 1:1 是「通话已结束 x」，群聊是「会议已结束 x」。
  ///
  /// public：通话结束的桌面通知横幅等处复用同一套文案。
  static String callEndedText(
    Map<String, String> properties, {
    required bool isGroup,
  }) {
    final durationText = callDurationText(properties);
    if (durationText == null) {
      return isGroup
          ? 'system_msg_callend_noduration'.tr()
          : 'call_ended'.tr();
    }
    return isGroup
        ? 'system_msg_callend'.tr(args: [durationText])
        : 'system_msg_callend_single'.tr(args: [durationText]);
  }

  /// 通话时长文案（国际化）
  ///
  /// 档位规则（秒数向下截断，不夸大时长）：
  /// - 不足 1 分钟：`39秒`
  /// - 不足 1 小时：`2分钟`（整分）/ `3分39秒`（带秒）
  /// - 1 小时以上：`1小时`（整点）/ `1小时4分`（秒一律不回显，避免过长）
  ///
  /// 秒数缺失（历史缓存的老数据）时回退到服务端的 mm:ss 文本；
  /// 都没有（或 0 秒）时返回 null，由调用方走「不带时长」的文案。
  static String? callDurationText(Map<String, String> properties) {
    final durationSec = _readDurationSeconds(properties);
    if (durationSec != null) {
      final hours = durationSec ~/ 3600;
      final minutes = (durationSec % 3600) ~/ 60;
      final seconds = durationSec % 60;

      if (hours > 0) {
        if (minutes == 0) return 'call_duration_hours'.tr(args: ['$hours']);
        return 'call_duration_hours_minutes'.tr(
          namedArgs: {'hours': '$hours', 'minutes': '$minutes'},
        );
      }
      if (minutes > 0) {
        if (seconds == 0) {
          return 'call_duration_minutes'.tr(args: ['$minutes']);
        }
        return 'call_duration_minutes_seconds'.tr(
          namedArgs: {'minutes': '$minutes', 'seconds': '$seconds'},
        );
      }
      return 'call_duration_seconds'.tr(args: ['$seconds']);
    }

    final durationText = properties['durationText']?.toString();
    return (durationText == null || durationText.isEmpty) ? null : durationText;
  }

  /// 通话时长格式化（按消息）
  ///
  /// 无可用时长时返回 `--`；需要区分「有没有时长」的场景请用
  /// [callDurationText]（返回 null 表示没有）。
  static String formatCallDuration(ChatMessage message) =>
      callDurationText(message.properties) ?? '--';

  /// 读取服务端下发的通话秒数
  ///
  /// 非数字、负数与 0 都视为「没有可用时长」：0 秒通话不该展示「0秒」，
  /// 也不该让上层把它当成有时长而拼出「通话已结束 --」。
  static int? _readDurationSeconds(Map<String, String> properties) {
    final seconds = int.tryParse(properties['duration']?.toString() ?? '');
    return (seconds != null && seconds > 0) ? seconds : null;
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
