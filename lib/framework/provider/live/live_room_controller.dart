import 'dart:async';

import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/framework/domain/RoomState.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:livekit_client/livekit_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'live_room_controller.g.dart';

@Riverpod(keepAlive: true)
class LiveRoomController extends _$LiveRoomController {
  EventsListener<RoomEvent>? _listener;
  bool _isTogglingCamera = false;
  bool _isTogglingMic = false;
  bool _isTogglingScreen = false;

  @override
  Future<RoomState> build(String roomId, bool isHost) async {
    final room = Room(
      roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
    );

    ref.onDispose(() async {
      _listener?.dispose();
      try {
        await room.disconnect();
      } catch (_) {}
      try {
        await room.dispose();
      } catch (_) {}
    });

    try {
      final token = await _fetchToken(roomId);
      await room.prepareConnection(API.wsRoomBaseUrl, token);
      await room.connect(API.wsRoomBaseUrl, token);

      final listener = room.createListener();
      _listener = listener;

      listener
        ..on<RoomConnectedEvent>((_) {
          log.info('直播房间已连接: $roomId');
        })
        ..on<ParticipantConnectedEvent>((_) {
          state = AsyncData(_buildState(room, token));
        })
        ..on<ParticipantDisconnectedEvent>((_) {
          state = AsyncData(_buildState(room, token));
        })
        ..on<TrackPublishedEvent>((_) {
          state = AsyncData(_buildState(room, token));
        })
        ..on<TrackUnpublishedEvent>((_) {
          state = AsyncData(_buildState(room, token));
        })
        ..on<TrackSubscribedEvent>((_) {
          state = AsyncData(_buildState(room, token));
        })
        ..on<TrackUnsubscribedEvent>((_) {
          state = AsyncData(_buildState(room, token));
        });

      return _buildState(room, token);
    } catch (e) {
      log.error('直播房间初始化失败: $e');
      rethrow;
    }
  }

  Future<void> toggleCamera() async {
    if (_isTogglingCamera) return;
    _isTogglingCamera = true;
    try {
      final current = state.value;
      if (current == null) return;
      final next = !current.cameraEnabled;
      await current.room.localParticipant?.setCameraEnabled(next);
      state = AsyncData(current.copyWith(cameraEnabled: next));
      Toast.showNotificationNow(next ? '摄像头已开启' : '摄像头已关闭');
    } catch (e) {
      Toast.showNotificationNow('切换摄像头失败：$e');
    } finally {
      _isTogglingCamera = false;
    }
  }

  Future<void> toggleMic() async {
    if (_isTogglingMic) return;
    _isTogglingMic = true;
    try {
      final current = state.value;
      if (current == null) return;
      final next = !current.micEnabled;
      await current.room.localParticipant?.setMicrophoneEnabled(next);
      state = AsyncData(current.copyWith(micEnabled: next));
    } catch (e) {
      Toast.showNotificationNow('切换麦克风失败：$e');
    } finally {
      _isTogglingMic = false;
    }
  }

  Future<void> toggleScreenShare(BuildContext context) async {
    if (_isTogglingScreen) return;
    _isTogglingScreen = true;
    try {
      final current = state.value;
      if (current == null || !context.mounted) return;
      final localParticipant = current.room.localParticipant;
      if (localParticipant == null) return;

      final next = !current.screenSharing;
      if (next) {
        final screenTrack = await LocalVideoTrack.createScreenShareTrack(
          const ScreenShareCaptureOptions(
            captureScreenAudio: true,
            maxFrameRate: 15,
            params: VideoParametersPresets.screenShareH1080FPS30,
          ),
        );
        await localParticipant.publishVideoTrack(screenTrack);
        state = AsyncData(
          current.copyWith(screenSharing: true, screenShareTrack: screenTrack),
        );
        Toast.showNotificationNow('屏幕共享已开启');
      } else {
        TrackPublication? screenPub;
        for (final publication in localParticipant.videoTrackPublications) {
          if (publication.isScreenShare) {
            screenPub = publication;
            break;
          }
        }
        if (screenPub != null) {
          await localParticipant.removePublishedTrack(screenPub.sid);
        }
        state = AsyncData(
          current.copyWith(screenSharing: false, screenShareTrack: null),
        );
        Toast.showNotificationNow('屏幕共享已关闭');
      }
    } catch (e) {
      Toast.showNotificationNow('切换屏幕共享失败：$e');
    } finally {
      _isTogglingScreen = false;
    }
  }

  Future<String> _fetchToken(String roomId) async {
    final res = await DioClient().get(
      '/live/token',
      queryParameters: {'roomId': roomId},
    );

    if (res.data?['code'] == 200) {
      return res.data!['data'].toString();
    }
    throw Exception(res.data?['message'] ?? '获取直播 token 失败');
  }

  RoomState _buildState(Room room, String token) {
    return RoomState(
      room: room,
      token: token,
      connectionState: room.connectionState,
      micEnabled: room.localParticipant?.isMicrophoneEnabled() ?? false,
      cameraEnabled: room.localParticipant?.isCameraEnabled() ?? false,
      screenSharing:
          room.localParticipant?.videoTrackPublications.any(
            (pub) => pub.isScreenShare,
          ) ??
          false,
      speakerOn: true,
      audioInputs: const [],
      audioOutputs: const [],
      videoInputs: const [],
      currentAudioInput: null,
      currentAudioOutput: null,
      currentVideoInput: null,
      remoteParticipants: room.remoteParticipants.values.toList(),
      joinedAt: DateTime.now(),
      participantQuality: {},
      participantVolumes: {},
      handRaiseMap: {},
      reactions: [],
    );
  }
}
