import 'dart:async';

import 'package:anoxia/common/constants/api.dart';
import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/features/chat/presentation/call/component/window_screen_select_dialog.dart';
import 'package:anoxia/framework/domain/room_state.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/framework/network/dio_client.dart';
import 'package:easy_localization/easy_localization.dart';
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
          state = AsyncData(
            _buildState(room, token, isReconnecting: false, connectionError: null),
          );
        })
        ..on<RoomReconnectingEvent>((_) {
          state = AsyncData(
            _buildState(room, token, isReconnecting: true, connectionError: null),
          );
        })
        ..on<RoomReconnectedEvent>((_) {
          state = AsyncData(
            _buildState(room, token, isReconnecting: false, connectionError: null),
          );
        })
        ..on<RoomDisconnectedEvent>((event) {
          final reason = event.reason?.toString();
          state = AsyncData(
            _buildState(
              room,
              token,
              isReconnecting: false,
              connectionError: (reason == null || reason.isEmpty)
                  ? 'disconnected'
                  : reason,
            ),
          );
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
      Toast.showNotificationNow(next ? 'live_camera_turned_on'.tr() : 'live_camera_turned_off'.tr());
    } catch (e) {
      Toast.showNotificationNow('live_switch_camera_error'.tr(args: [e.toString()]));
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
      Toast.showNotificationNow('live_switch_microphone_error'.tr(args: [e.toString()]));
    } finally {
      _isTogglingMic = false;
    }
  }

  Future<void> toggleScreenShare(
    BuildContext context, {
    String? sourceId,
  }) async {
    if (_isTogglingScreen) return;
    _isTogglingScreen = true;
    try {
      final current = state.value;
      if (current == null || !context.mounted) return;
      final localParticipant = current.room.localParticipant;
      if (localParticipant == null) return;

      final next = !current.screenSharing;
      if (next) {
        if (sourceId == null && DeviceUtil.isRealDesktop() && context.mounted) {
          final source = await showDialog<dynamic>(
            context: context,
            builder: (context) => const WindowScreenSelectDialog(),
          );
          if (source == null) return;
          sourceId = source.id?.toString();
        }
        final screenTrack = await LocalVideoTrack.createScreenShareTrack(
          ScreenShareCaptureOptions(
            sourceId: sourceId,
            captureScreenAudio: true,
            maxFrameRate: 15,
            params: VideoParametersPresets.screenShareH1080FPS30,
          ),
        );
        await localParticipant.publishVideoTrack(screenTrack);
        state = AsyncData(
          current.copyWith(screenSharing: true, screenShareTrack: screenTrack),
        );
        Toast.showNotificationNow('live_screen_share_started'.tr());
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
        Toast.showNotificationNow('live_screen_share_stopped'.tr());
      }
    } catch (e) {
      Toast.showNotificationNow('live_switch_screen_share_error'.tr(args: [e.toString()]));
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

  RoomState _buildState(
    Room room,
    String token, {
    bool? isReconnecting,
    String? connectionError,
  }) {
    final previous = state.value;

    return RoomState(
      room: room,
      token: token,
      connectionState: room.connectionState,
      connectionError: connectionError ?? previous?.connectionError,
      micEnabled: room.localParticipant?.isMicrophoneEnabled() ?? false,
      cameraEnabled: room.localParticipant?.isCameraEnabled() ?? false,
      screenSharing:
          room.localParticipant?.videoTrackPublications.any(
            (pub) => pub.isScreenShare,
          ) ??
          false,
      speakerOn: true,
      isReconnecting: isReconnecting ?? previous?.isReconnecting ?? false,
      audioInputs: const [],
      audioOutputs: const [],
      videoInputs: const [],
      currentAudioInput: null,
      currentAudioOutput: null,
      currentVideoInput: null,
      remoteParticipants: room.remoteParticipants.values.toList(),
      joinedAt: previous?.joinedAt ?? DateTime.now(),
      participantQuality: {},
      participantVolumes: {},
      handRaiseMap: {},
      reactions: [],
    );
  }
}
