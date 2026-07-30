import 'package:livekit_client/livekit_client.dart';

/// 音视频通话房间状态
///
/// 聚合 LiveKit 房间的连接状态、设备状态、参与者信息等，用于 UI 层展示和状态同步。
class RoomState {
  /// LiveKit 房间实例
  final Room room;

  /// 加入房间的授权令牌
  final String token;

  /// 连接状态
  final ConnectionState connectionState;

  /// 连接错误信息（连接失败时填充）
  final String? connectionError;

  /// 麦克风开关状态
  final bool micEnabled;

  /// 摄像头开关状态
  final bool cameraEnabled;

  /// 是否正在共享屏幕
  final bool screenSharing;

  /// 扬声器开关状态
  final bool speakerOn;

  /// 屏幕共享的本地视频轨道
  final LocalVideoTrack? screenShareTrack;

  /// 是否处于重连状态
  final bool isReconnecting;

  /// 是否正在录制
  final bool isRecording;

  /// 房间元数据（JSON 字符串）
  final String? roomMetadata;

  /// 当前焦点参与者 ID（用于高亮显示）
  final String? focusedParticipantId;

  /// 可用的音频输入设备列表（麦克风）
  final List<MediaDevice> audioInputs;

  /// 可用的音频输出设备列表（扬声器）
  final List<MediaDevice> audioOutputs;

  /// 可用的视频输入设备列表（摄像头）
  final List<MediaDevice> videoInputs;

  /// 当前选中的音频输入设备
  final MediaDevice? currentAudioInput;

  /// 当前选中的音频输出设备
  final MediaDevice? currentAudioOutput;

  /// 当前选中的视频输入设备
  final MediaDevice? currentVideoInput;

  /// 远端参与者列表
  final List<RemoteParticipant> remoteParticipants;

  /// 本地客户端加入房间的时间点
  final DateTime? joinedAt;

  /// 每个参与者的连接质量
  ///
  /// key = participant.identity，value = ConnectionQuality（excellent/good/poor/lost）
  /// 对应官方 ParticipantConnectionQualityUpdatedEvent 事件
  final Map<String, ConnectionQuality>? participantQuality;

  /// 每个参与者的音量等级 (0.0-1.0)
  ///
  /// key = participant.identity
  final Map<String, double>? participantVolumes;

  /// 举手状态映射
  ///
  /// key = participant.identity，value = 是否举手
  final Map<String, bool>? handRaiseMap;

  /// 消息反应列表
  final List<ReactionItem>? reactions;

  const RoomState({
    required this.room,
    required this.token,
    required this.connectionState,
    required this.micEnabled,
    required this.cameraEnabled,
    required this.screenSharing,
    required this.speakerOn,
    required this.audioInputs,
    required this.audioOutputs,
    required this.videoInputs,
    required this.remoteParticipants,
    this.connectionError,
    this.screenShareTrack,
    this.isReconnecting = false,
    this.isRecording = false,
    this.roomMetadata,
    this.focusedParticipantId,
    this.currentAudioInput,
    this.currentAudioOutput,
    this.currentVideoInput,
    this.joinedAt,
    this.participantQuality,
    this.participantVolumes,
    this.handRaiseMap,
    this.reactions,
  });

  /// 创建当前实例的变体副本
  RoomState copyWith({
    String? token,
    Room? room,
    ConnectionState? connectionState,
    String? connectionError,
    bool? micEnabled,
    bool? cameraEnabled,
    bool? screenSharing,
    bool? speakerOn,
    bool? isReconnecting,
    bool? isRecording,
    LocalVideoTrack? screenShareTrack,
    String? roomMetadata,
    String? focusedParticipantId,
    List<MediaDevice>? audioInputs,
    List<MediaDevice>? audioOutputs,
    List<MediaDevice>? videoInputs,
    MediaDevice? currentAudioInput,
    MediaDevice? currentAudioOutput,
    MediaDevice? currentVideoInput,
    List<RemoteParticipant>? remoteParticipants,
    DateTime? joinedAt,
    Map<String, ConnectionQuality>? participantQuality,
    Map<String, double>? participantVolumes,
    Map<String, bool>? handRaiseMap,
    List<ReactionItem>? reactions,
  }) {
    return RoomState(
      token: token ?? this.token,
      room: room ?? this.room,
      connectionState: connectionState ?? this.connectionState,
      connectionError: connectionError ?? this.connectionError,
      micEnabled: micEnabled ?? this.micEnabled,
      cameraEnabled: cameraEnabled ?? this.cameraEnabled,
      screenSharing: screenSharing ?? this.screenSharing,
      speakerOn: speakerOn ?? this.speakerOn,
      isReconnecting: isReconnecting ?? this.isReconnecting,
      isRecording: isRecording ?? this.isRecording,
      screenShareTrack: screenShareTrack ?? this.screenShareTrack,
      roomMetadata: roomMetadata ?? this.roomMetadata,
      focusedParticipantId: focusedParticipantId ?? this.focusedParticipantId,
      audioInputs: audioInputs ?? this.audioInputs,
      audioOutputs: audioOutputs ?? this.audioOutputs,
      videoInputs: videoInputs ?? this.videoInputs,
      currentAudioInput: currentAudioInput ?? this.currentAudioInput,
      currentAudioOutput: currentAudioOutput ?? this.currentAudioOutput,
      currentVideoInput: currentVideoInput ?? this.currentVideoInput,
      remoteParticipants: remoteParticipants ?? this.remoteParticipants,
      joinedAt: joinedAt ?? this.joinedAt,
      participantQuality: participantQuality ?? this.participantQuality,
      participantVolumes: participantVolumes ?? this.participantVolumes,
      handRaiseMap: handRaiseMap ?? this.handRaiseMap,
      reactions: reactions ?? this.reactions,
    );
  }

  @override
  String toString() =>
      'RoomState{connectionState: $connectionState, mic: $micEnabled, camera: $cameraEnabled, screen: $screenSharing, reconnecting: $isReconnecting}';
}

/// 消息反应项
///
/// 表示参与者在通话中发送的快捷消息/反应
class ReactionItem {
  /// 唯一标识
  final String id;

  /// 反应内容（emoji 或预设文本）
  final String message;

  /// 发送者用户ID
  final String uid;

  /// 发送者昵称
  final String name;

  /// 发送者头像
  final String? avatar;

  /// 发送时间
  final DateTime createdAt;

  ReactionItem({
    required this.message,
    required this.uid,
    required this.createdAt,
    required this.name,
    this.avatar,
  }) : id = '${uid}_${DateTime.now().microsecondsSinceEpoch}';
}
