/// 直播房间控制器
///
/// 基于 LiveKit 管理直播房间的连接、音视频控制和屏幕共享功能。
/// 保持活跃状态，不随 UI 销毁而释放。
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

/// 直播房间控制器
///
/// 管理 LiveKit 房间的完整生命周期：连接、重连、音视频开关、屏幕共享。
/// 监听房间事件并更新状态，包括参与者进出、轨道发布订阅等。
@Riverpod(keepAlive: true)
class LiveRoomController extends _$LiveRoomController {
  EventsListener<RoomEvent>? _listener;
  bool _isTogglingCamera = false;
  bool _isTogglingMic = false;
  bool _isTogglingScreen = false;

  /// 初始化并连接直播房间
  ///
  /// [roomId] 房间 ID
  /// [isHost] 是否为房主
  ///
  /// 获取 token 后连接 LiveKit 房间，注册各类房间事件监听器。
  /// 返回初始化后的 [RoomState]。
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

  /// 切换摄像头开关
  ///
  /// 切换本地摄像头的启用状态，并显示对应的 Toast 提示。
  /// 通过 [_isTogglingCamera] 防止重复操作。
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

  /// 切换麦克风开关
  ///
  /// 切换本地麦克风的启用状态，并显示对应的 Toast 提示。
  /// 通过 [_isTogglingMic] 防止重复操作。
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

  /// 切换屏幕共享
  ///
  /// [context] 构建上下文，用于弹出屏幕选择对话框
  /// [sourceId] 屏幕源 ID，桌面端为 null 时会弹出选择对话框
  ///
  /// 开启屏幕共享时，桌面端会先弹出屏幕/窗口选择对话框。
  /// 关闭屏幕共享时，会移除已发布的屏幕共享轨道。
  /// 通过 [_isTogglingScreen] 防止重复操作。
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

  /// 获取直播房间 token
  ///
  /// [roomId] 房间 ID
  ///
  /// 从服务端获取用于连接 LiveKit 房间的 token。
  /// 请求失败时抛出异常。
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

  /// 构建房间状态快照
  ///
  /// [room] LiveKit 房间实例
  /// [token] 连接 token
  /// [isReconnecting] 是否正在重连
  /// [connectionError] 连接错误信息
  ///
  /// 从当前房间和参与者信息构建 [RoomState] 快照，保留部分历史状态字段。
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
