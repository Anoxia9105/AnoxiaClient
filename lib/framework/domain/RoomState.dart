import 'package:livekit_client/livekit_client.dart';

class RoomState {
  final ConnectionState connectionState;

  final bool micEnabled;
  final bool cameraEnabled;
  final bool screenSharing;
  final bool speakerOn;

  final List<MediaDevice> audioInputs;
  final List<MediaDevice> audioOutputs;
  final List<MediaDevice> videoInputs;

  final MediaDevice? currentAudioInput;
  final MediaDevice? currentAudioOutput;
  final MediaDevice? currentVideoInput;

  final List<RemoteParticipant> remoteParticipants;

  const RoomState({
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

  factory RoomState.initial() => const RoomState(
    connectionState: ConnectionState.disconnected,
    micEnabled: true,
    cameraEnabled: false,
    screenSharing: false,
    speakerOn: true,
    audioInputs: [],
    audioOutputs: [],
    videoInputs: [],
    remoteParticipants: [],
  );

  RoomState copyWith({
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
}
