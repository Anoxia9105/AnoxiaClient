/// 通话记录条目状态
///
/// 与服务端 [CallLogEntryVO.status] 一一对应。
enum CallLogStatus {
  /// 已接通并正常结束
  completed,

  /// 被对端拒绝
  rejected,

  /// 呼出方取消 / 被新通话顶掉
  canceled,

  /// 尚未出现终态（进行中）
  ongoing,
}

/// 通话记录条目
///
/// 服务端将房间内 CALL_STARTED 与其后首个终态系统消息折叠成一条
/// 会话级聚合记录；[outgoing] 依据发起人是否是本人计算。
class CallLogEntry {
  final String messageId;
  final String roomId;

  /// 0=单聊, 1=群聊
  final int roomType;

  /// 单聊对端用户 ID
  final int? peerId;

  /// 单聊对端昵称
  final String? peerName;

  /// 单聊对端头像
  final String? peerAvatar;

  /// 群聊房间名
  final String? roomName;

  /// 发起人用户 ID（呼出/呼入判断依据）
  final int? callerId;

  /// 是否本人发起（呼出）
  final bool outgoing;

  /// 通话开始时间戳（服务器毫秒）
  final int startAt;

  /// 结束时间戳；未结束（进行中）为 null
  final int? endAt;

  /// 通话秒数（仅 completed 有值）
  final int? durationSec;

  /// 服务端预格式化时长（如 `01:20`）
  final String? durationText;

  final CallLogStatus status;

  const CallLogEntry({
    required this.messageId,
    required this.roomId,
    required this.roomType,
    required this.outgoing,
    required this.startAt,
    required this.status,
    this.peerId,
    this.peerName,
    this.peerAvatar,
    this.roomName,
    this.callerId,
    this.endAt,
    this.durationSec,
    this.durationText,
  });

  /// 服务端 [CallLogEntryVO] JSON 反序列化
  ///
  /// 字段全部容错解析（缺失/类型漂移不抛异常，回退安全默认值），
  /// 以便旧部署或字段演进时页面仍可渲染可解析部分。
  factory CallLogEntry.fromJson(Map<String, dynamic> json) {
    return CallLogEntry(
      messageId: json['messageId']?.toString() ?? '',
      roomId: json['roomId']?.toString() ?? '',
      roomType: _readInt(json['roomType']) ?? 0,
      peerId: _readInt(json['peerId']),
      peerName: json['peerName']?.toString(),
      peerAvatar: json['peerAvatar']?.toString(),
      roomName: json['roomName']?.toString(),
      callerId: _readInt(json['callerId']),
      outgoing: json['outgoing'] == true,
      startAt: _readInt(json['startAt']) ?? 0,
      endAt: _readInt(json['endAt']),
      durationSec: _readInt(json['durationSec']),
      durationText: json['durationText']?.toString(),
      status: _statusFrom(json['status']?.toString()),
    );
  }

  /// 显示用标题：单聊取对端昵称，群聊取房间名，均缺失回退占位。
  ///
  /// 占位 key 由 UI 层翻译（`call_history_unknown_peer`），模型保持纯数据。
  String get displayName {
    final name = roomType == 1 ? (roomName ?? peerName) : (peerName ?? roomName);
    return (name == null || name.isEmpty) ? '' : name;
  }
}

/// 通话记录分页数据（对应服务端 TableDataInfo 顶层 total + rows）
class CallHistoryPageData {
  final List<CallLogEntry> entries;
  final int total;

  const CallHistoryPageData({required this.entries, required this.total});

  static const CallHistoryPageData empty = CallHistoryPageData(
    entries: [],
    total: 0,
  );

  /// 解析服务端 `GET /call/history` 响应
  ///
  /// `rows` 缺失或非 List 视为脏数据：条目按行容错解析，
  /// 解析失败的行丢弃而不是让整页失败。
  factory CallHistoryPageData.fromJson(Map<String, dynamic> json) {
    final rows = json['rows'];
    final entries = rows is List
        ? rows
              .whereType<Map>()
              .map((row) => CallLogEntry.fromJson(Map<String, dynamic>.from(row)))
              .toList()
        : <CallLogEntry>[];
    return CallHistoryPageData(
      entries: entries,
      total: _readInt(json['total']) ?? entries.length,
    );
  }
}

CallLogStatus _statusFrom(String? raw) {
  switch (raw) {
    case 'REJECTED':
      return CallLogStatus.rejected;
    case 'CANCELED':
      return CallLogStatus.canceled;
    case 'ONGOING':
      return CallLogStatus.ongoing;
    default:
      return CallLogStatus.completed;
  }
}

int? _readInt(dynamic raw) {
  if (raw == null) return null;
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw.toString());
}
