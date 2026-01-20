import 'package:livekit_client/livekit_client.dart';

/// 房间状态类：用于保存 LiveKit 会话中所有的 UI 状态和媒体信息
class RoomState {
  final Room room;
  final String token;

  // --- 连接状态 ---
  final ConnectionState connectionState; // 当前房间的连接状态（如：连接中、已连接、断开等）

  // --- 开关控制状态 ---
  final bool micEnabled; // 本地麦克风是否已开启（静音控制）
  final bool cameraEnabled; // 本地摄像头是否已开启
  final bool screenSharing; // 当前是否正在进行屏幕共享
  final bool speakerOn; // 扬声器是否开启（声音播放路径切换）

  // --- 可用设备列表 ---
  final List<MediaDevice> audioInputs; // 系统检测到的所有音频输入设备（麦克风）
  final List<MediaDevice> audioOutputs; // 系统检测到的所有音频输出设备（扬声器/耳机）
  final List<MediaDevice> videoInputs; // 系统检测到的所有视频输入设备（摄像头）

  // --- 当前选中的设备 ---
  final MediaDevice? currentAudioInput; // 当前正在使用的麦克风
  final MediaDevice? currentAudioOutput; // 当前正在使用的扬声器
  final MediaDevice? currentVideoInput; // 当前正在使用的摄像头

  // --- 参与者列表 ---
  final List<RemoteParticipant> remoteParticipants; // 房间内除自己以外的其他所有参与者

  /// 构造函数：初始化所有必要字段
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
    this.currentAudioInput,
    this.currentAudioOutput,
    this.currentVideoInput,
  });

  /// 状态克隆方法：由于属性是 final 的，通过此方法局部更新状态并返回新实例
  RoomState copyWith({
    String? token,
    Room? room,
    ConnectionState? connectionState,
    bool? micEnabled,
    bool? cameraEnabled,
    bool? screenSharing,
    bool? speakerOn,
    List<MediaDevice>? audioInputs,
    List<MediaDevice>? audioOutputs,
    List<MediaDevice>? videoInputs,
    MediaDevice? currentAudioInput,
    MediaDevice? currentAudioOutput,
    MediaDevice? currentVideoInput,
    List<RemoteParticipant>? remoteParticipants,
  }) {
    return RoomState(
      token: token ?? this.token,
      room: room ?? this.room,
      connectionState: connectionState ?? this.connectionState,
      micEnabled: micEnabled ?? this.micEnabled,
      cameraEnabled: cameraEnabled ?? this.cameraEnabled,
      screenSharing: screenSharing ?? this.screenSharing,
      speakerOn: speakerOn ?? this.speakerOn,
      audioInputs: audioInputs ?? this.audioInputs,
      audioOutputs: audioOutputs ?? this.audioOutputs,
      videoInputs: videoInputs ?? this.videoInputs,
      currentAudioInput: currentAudioInput ?? this.currentAudioInput,
      currentAudioOutput: currentAudioOutput ?? this.currentAudioOutput,
      currentVideoInput: currentVideoInput ?? this.currentVideoInput,
      remoteParticipants: remoteParticipants ?? this.remoteParticipants,
    );
  }

  @override
  String toString() {
    return 'RoomState{connectionState: $connectionState, micEnabled: $micEnabled, cameraEnabled: $cameraEnabled, screenSharing: $screenSharing, speakerOn: $speakerOn, audioInputs: $audioInputs, audioOutputs: $audioOutputs, videoInputs: $videoInputs, currentAudioInput: $currentAudioInput, currentAudioOutput: $currentAudioOutput, currentVideoInput: $currentVideoInput, remoteParticipants: $remoteParticipants}';
  }
}
