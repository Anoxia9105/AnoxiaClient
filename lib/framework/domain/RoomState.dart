import 'package:livekit_client/livekit_client.dart';

class RoomState {
  final Room room;
  final String token;

  // --- 连接状态 ---
  final ConnectionState connectionState;
  final String? connectionError;

  // --- 开关控制状态 ---
  final bool micEnabled;
  final bool cameraEnabled;
  final bool screenSharing;
  final bool speakerOn;

  // --- 轨道与房间状态 ---
  final LocalVideoTrack? screenShareTrack;
  final bool isReconnecting;
  final bool isRecording;
  final String? roomMetadata;
  final String? focusedParticipantId;

  // --- 可用设备列表 ---
  final List<MediaDevice> audioInputs;
  final List<MediaDevice> audioOutputs;
  final List<MediaDevice> videoInputs;

  // --- 当前选中的设备 ---
  final MediaDevice? currentAudioInput;
  final MediaDevice? currentAudioOutput;
  final MediaDevice? currentVideoInput;

  // --- 参与者 ---
  final List<RemoteParticipant> remoteParticipants;

  // --- 监控数据 ---
  /// 本地客户端加入房间的时间点
  final DateTime? joinedAt;

  /// 每个参与者的连接质量
  /// key = participant.identity，value = ConnectionQuality（excellent/good/poor/lost）
  /// 对应官方 ParticipantConnectionQualityUpdatedEvent 事件
  final Map<String, ConnectionQuality>? participantQuality;

  /// 每个参与者的音量等级 (0.0-1.0)，key = participant.identity
  final Map<String, double>? participantVolumes;

  // 举手状态：key = participant.identity
  final Map<String, bool>? handRaiseMap;

  // 表情：当前飘动的表情列表
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

class ReactionItem {
  final String id;
  final String message;
  final String uid;
  final DateTime createdAt;
  ReactionItem({
    required this.message,
    required this.uid,
    required this.createdAt,
  }) : id = '${uid}_${DateTime.now().microsecondsSinceEpoch}';
}
