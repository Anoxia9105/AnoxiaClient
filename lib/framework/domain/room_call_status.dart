/// 房间通话状态
///
/// 记录指定房间当前是否处于通话中及通话开始时间。
class RoomCallStatus {
  /// 是否正在通话
  final bool calling;

  /// 通话开始时间戳（毫秒）
  final int startTime;

  const RoomCallStatus({required this.calling, required this.startTime});

  /// 空闲状态常量
  const RoomCallStatus.idle() : calling = false, startTime = 0;

  /// 从 JSON 构造 [RoomCallStatus] 实例
  factory RoomCallStatus.fromJson(Map<String, dynamic> json) {
    return RoomCallStatus(
      calling: json['calling'] == true,
      startTime: _readInt(json['startTime']) ?? 0,
    );
  }
}

int? _readInt(dynamic raw) {
  if (raw == null) return null;
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw.toString());
}
