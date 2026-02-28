import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../../logs/talker.dart';
import 'room_controller.dart';

/// 转录消息段
class TranscriptionSegment {
  final String id;
  final String text;
  final bool isFinal;
  final DateTime timestamp;

  TranscriptionSegment({
    required this.id,
    required this.text,
    required this.isFinal,
    required this.timestamp,
  });
}

/// 参与者的转录信息
class ParticipantTranscription {
  final String participantId;
  final String participantName;
  final List<TranscriptionSegment> segments;

  ParticipantTranscription({
    required this.participantId,
    required this.participantName,
    required this.segments,
  });
}

/// LiveKit 转录状态
class LiveKitTranscriptionState {
  final List<ParticipantTranscription> transcriptions;
  final bool isEnabled;
  final bool isTranscribing;

  const LiveKitTranscriptionState({
    this.transcriptions = const [],
    this.isEnabled = false,
    this.isTranscribing = false,
  });

  LiveKitTranscriptionState copyWith({
    List<ParticipantTranscription>? transcriptions,
    bool? isEnabled,
    bool? isTranscribing,
  }) {
    return LiveKitTranscriptionState(
      transcriptions: transcriptions ?? this.transcriptions,
      isEnabled: isEnabled ?? this.isEnabled,
      isTranscribing: isTranscribing ?? this.isTranscribing,
    );
  }
}

/// LiveKit 转录控制器
class LiveKitTranscriptionController extends Notifier<LiveKitTranscriptionState> {
  @override
  LiveKitTranscriptionState build() {
    _setupTranscriptionListener();
    return const LiveKitTranscriptionState();
  }

  lk.EventsListener<lk.RoomEvent>? _listener;

  void _setupTranscriptionListener() {
    final token = ref.params['token'];
    if (token == null) return;

    final roomState = ref.read(roomControllerProvider(token)).value;
    if (roomState == null) return;

    final room = roomState.room;
    _listener = room.createListener();

    _listener!.on<lk.TranscriptionReceivedEvent>((event) {
      _handleTranscriptionReceived(event);
    });
  }

  void _handleTranscriptionReceived(lk.TranscriptionReceivedEvent event) {
    final participant = event.participant;
    final participantId = participant.identity;
    final participantName = participant.name ?? participantId;

    final segments = event.transcriptions.map((t) {
      return TranscriptionSegment(
        id: t.id,
        text: t.text,
        isFinal: t.isFinal,
        timestamp: DateTime.now(),
      );
    }).toList();

    final existingIndex = state.transcriptions.indexWhere(
      (p) => p.participantId == participantId,
    );

    List<ParticipantTranscription> newTranscriptions;
    if (existingIndex >= 0) {
      newTranscriptions = [...state.transcriptions];
      final existing = newTranscriptions[existingIndex];
      newTranscriptions[existingIndex] = ParticipantTranscription(
        participantId: participantId,
        participantName: participantName,
        segments: [...existing.segments, ...segments],
      );
    } else {
      newTranscriptions = [
        ...state.transcriptions,
        ParticipantTranscription(
          participantId: participantId,
          participantName: participantName,
          segments: segments,
        ),
      ];
    }

    state = state.copyWith(
      transcriptions: newTranscriptions,
      isTranscribing: true,
    );

    log.info('收到转录: ${segments.first.text} from $participantName');
  }

  void toggleTranscription(bool enabled) {
    state = state.copyWith(isEnabled: enabled);
  }

  void clear() {
    state = state.copyWith(transcriptions: [], isTranscribing: false);
  }

  @override
  void dispose() {
    _listener?.dispose();
    super.dispose();
  }
}

/// LiveKit 转录 Provider
final liveKitTranscriptionProvider = NotifierProvider.autoDispose
    .withParams<LiveKitTranscriptionController, LiveKitTranscriptionState, ({String token})>(
  LiveKitTranscriptionController.new,
  paramName: 'token',
  paramFrom: (token) => (token: token),
);
