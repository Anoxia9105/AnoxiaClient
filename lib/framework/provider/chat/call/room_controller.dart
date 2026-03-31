import 'dart:async';
import 'dart:convert';

import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../pages/chat/call/component/WindowScreenSelectDialog.dart';
import '../../../domain/RoomState.dart';
import '../../../network/DioClient.dart';

part 'room_controller.g.dart';

@riverpod
class RoomController extends _$RoomController {
  EventsListener<RoomEvent>? _listener;

  bool _isTogglingMic = false;
  bool _isTogglingCamera = false;
  bool _isTogglingScreen = false;

  @override
  Future<RoomState> build(String token) async {
    final room = Room(
      roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
    );

    ref.onDispose(() async {
      _disposeResources();
      try {
        await room.disconnect();
      } catch (_) {}
      try {
        await room.dispose();
      } catch (_) {}
      log.info("房间控制器已销毁");
    });

    try {
      await _connectRoom(room, token);

      final listener = room.createListener();
      _listener = listener;
      listener
        ..on<RoomConnectedEvent>((event) {
          log.info("✓ 房间已连接: ${event.room.name}");
          final current = state.value;
          if (current != null && current.connectionError != null) {
            state = AsyncData(current.copyWith(connectionError: null));
          }
        })
        ..on<RoomDisconnectedEvent>((event) {
          log.info("✗ 房间已断开");
        })
        ..on<RoomReconnectingEvent>((event) {
          log.warning("🔄 房间正在重新连接...");
          final current = state.value;
          if (current != null) {
            state = AsyncData(current.copyWith(isReconnecting: true));
          }
        })
        ..on<RoomReconnectedEvent>((event) {
          log.info("✅ 房间已重新连接");
          final current = state.value;
          if (current != null) {
            state = AsyncData(
              current.copyWith(isReconnecting: false, connectionError: null),
            );
          }
        })
        ..on<RoomMetadataChangedEvent>((event) {
          log.info("📝 房间元数据变化: ${event.metadata}");
          final current = state.value;
          if (current != null) {
            state = AsyncData(current.copyWith(roomMetadata: event.metadata));
          }
        })
        ..on<RoomRecordingStatusChanged>((event) {
          log.info("📹 录制状态变化: ${event.activeRecording}");
          final current = state.value;
          if (current != null) {
            state = AsyncData(
              current.copyWith(isRecording: event.activeRecording),
            );
          }
        })
        // ---- 参与者变化 ----
        ..on<ParticipantConnectedEvent>((e) {
          log.info("➕ 参与者加入: ${e.participant.identity}");
          _updateParticipants();
        })
        ..on<ParticipantDisconnectedEvent>((e) {
          log.info("➖ 参与者离开: ${e.participant.identity}");
          _updateParticipants();
        })
        ..on<ActiveSpeakersChangedEvent>((e) {
          log.info("🔊 活跃发言者变化 (${e.speakers.length} 人)");
          final current = state.value;
          if (current != null && e.speakers.isNotEmpty) {
            state = AsyncData(
              current.copyWith(focusedParticipantId: e.speakers.first.identity),
            );
          }
        })
        // ---- 连接质量（官方用 ParticipantConnectionQualityUpdatedEvent）----
        ..on<ParticipantConnectionQualityUpdatedEvent>((e) {
          log.info(
            "📶 连接质量变化: ${e.participant.identity} → ${e.connectionQuality}",
          );
          final current = state.value;
          if (current != null) {
            final qmap = Map<String, ConnectionQuality>.from(
              current.participantQuality ?? {},
            );
            qmap[e.participant.identity] = e.connectionQuality;
            state = AsyncData(current.copyWith(participantQuality: qmap));
          }
        })
        // ---- Track 状态变化 ----
        ..on<TrackPublishedEvent>((e) {
          log.info(
            "📡 远端轨道发布: ${e.participant.identity} - ${e.publication.sid}",
          );
          _updateParticipants();
        })
        ..on<TrackUnpublishedEvent>((e) {
          log.info(
            "📡 远端轨道撤销: ${e.participant.identity} - ${e.publication.sid}",
          );
          _updateParticipants();
        })
        ..on<LocalTrackPublishedEvent>((e) {
          log.info("📡 本地轨道发布: ${e.publication.sid}");
          _updateParticipants();
        })
        ..on<LocalTrackUnpublishedEvent>((e) {
          log.info("📡 本地轨道撤销: ${e.publication.sid}");
          _updateParticipants();
        })
        ..on<TrackMutedEvent>((e) {
          log.info(
            "🔇 轨道已静音: ${e.participant.identity} - ${e.publication.sid}",
          );
          _updateParticipants();
        })
        ..on<TrackUnmutedEvent>((e) {
          log.info(
            "🔈 轨道已取消静音: ${e.participant.identity} - ${e.publication.sid}",
          );
          _updateParticipants();
        })
        // ---- 自定义数据通道（举手/表情等功能入口）----
        ..on<DataReceivedEvent>((e) {
          _handleDataEvent(e);
        });

      _bindDeviceEvents();

      final devices = await _getInitialDevices();
      await _initLocalTracks(room);

      return RoomState(
        room: room,
        token: token,
        connectionState: room.connectionState,
        micEnabled: room.localParticipant?.isMicrophoneEnabled() ?? false,
        cameraEnabled: room.localParticipant?.isCameraEnabled() ?? false,
        screenSharing: false,
        speakerOn: true,
        audioInputs: devices.where((d) => d.kind == 'audioinput').toList(),
        audioOutputs: devices.where((d) => d.kind == 'audiooutput').toList(),
        videoInputs: devices.where((d) => d.kind == 'videoinput').toList(),
        currentAudioInput: Hardware.instance.selectedAudioInput,
        currentAudioOutput: Hardware.instance.selectedAudioOutput,
        currentVideoInput: Hardware.instance.selectedVideoInput,
        remoteParticipants: room.remoteParticipants.values.toList(),
        joinedAt: DateTime.now(),
        participantQuality: {},
        participantVolumes: {},
      );
    } catch (e) {
      log.error("房间初始化失败: $e");
      await room.dispose();
      rethrow;
    }
  }

  // ================= 核心私有方法 =================

  Future<void> _connectRoom(Room room, String token) async {
    await room.prepareConnection(API.wsRoomBaseUrl, token);
    await room
        .connect(API.wsRoomBaseUrl, token)
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException("连接房间超时"),
        );
    log.info("房间连接成功: ${room.name}");
  }

  Future<List<MediaDevice>> _getInitialDevices() async {
    try {
      return await Hardware.instance.enumerateDevices();
    } catch (e) {
      log.error("获取设备列表失败: $e");
      return [];
    }
  }

  Future<void> _initLocalTracks(Room room) async {
    final localParticipant = room.localParticipant;
    if (localParticipant == null) return;
    try {
      localParticipant.setCameraEnabled(false);
      localParticipant.setMicrophoneEnabled(false);
      log.info(
        "本地轨道初始化 → mic: ${localParticipant.isMicrophoneEnabled()}, video: ${localParticipant.isCameraEnabled()}",
      );
    } catch (e) {
      log.error("初始化本地硬件失败，可能设备被占用或无权限: $e");
    }
  }

  void _updateParticipants() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        remoteParticipants: current.room.remoteParticipants.values.toList(),
      ),
    );
  }

  void _handleDataEvent(DataReceivedEvent e) {
    try {
      final json = jsonDecode(utf8.decode(e.data)) as Map<String, dynamic>;
      log.info("📨 收到数据事件原始内容: $json");
      final type = json['type'] as String?;
      log.info("📨 收到数据事件: type=$type 来自: ${e.participant?.identity}");

      switch (type) {
        case 'hand_raise':
          // TODO: 处理举手
          break;
        case 'reaction':
          // TODO: 处理表情
          break;
        case 'mute_command':
          // TODO: 处理主持人静音指令
          break;
      }
    } catch (err) {
      log.error("解析数据事件失败: $err");
    }
  }

  void _bindDeviceEvents() {
    final sub = Hardware.instance.onDeviceChange.stream.listen((_) async {
      await _loadDeviceList();
    });
    ref.onDispose(() => sub.cancel());
  }

  Future<void> _loadDeviceList() async {
    final currentState = state.value;
    if (currentState == null) return;
    final devices = await _getInitialDevices();
    state = AsyncData(
      currentState.copyWith(
        audioInputs: devices.where((d) => d.kind == 'audioinput').toList(),
        audioOutputs: devices.where((d) => d.kind == 'audiooutput').toList(),
        videoInputs: devices.where((d) => d.kind == 'videoinput').toList(),
        currentAudioInput: Hardware.instance.selectedAudioInput,
        currentAudioOutput: Hardware.instance.selectedAudioOutput,
        currentVideoInput: Hardware.instance.selectedVideoInput,
      ),
    );
  }

  void _disposeResources() {
    _listener?.dispose();
    log.info("资源已清理");
  }

  // ================= 公开功能 API =================

  Future<void> toggleMic() async {
    if (_isTogglingMic) return;
    _isTogglingMic = true;
    try {
      final currentState = state.value;
      if (currentState == null) return;
      final next = !currentState.micEnabled;
      await currentState.room.localParticipant?.setMicrophoneEnabled(next);
      state = AsyncData(currentState.copyWith(micEnabled: next));
      log.info("麦克风${next ? "开启" : "关闭"}");
    } catch (e) {
      log.error("切换麦克风失败: $e");
    } finally {
      _isTogglingMic = false;
    }
  }

  Future<void> toggleCamera() async {
    if (_isTogglingCamera) return;
    _isTogglingCamera = true;
    try {
      final currentState = state.value;
      if (currentState == null) return;
      final next = !currentState.cameraEnabled;
      await currentState.room.localParticipant?.setCameraEnabled(next);
      state = AsyncData(currentState.copyWith(cameraEnabled: next));
      log.info("摄像头${next ? "开启" : "关闭"}");
    } catch (e) {
      log.error("切换摄像头失败: $e");
    } finally {
      _isTogglingCamera = false;
    }
  }

  Future<void> toggleScreenShare(BuildContext context) async {
    if (_isTogglingScreen) return;
    _isTogglingScreen = true;
    try {
      final currentState = state.value;
      if (currentState == null || !context.mounted) return;
      final next = !currentState.screenSharing;
      final localParticipant = currentState.room.localParticipant;
      if (localParticipant == null) return;

      if (next) {
        String? sourceId;
        if (lkPlatformIsDesktop()) {
          final source = await showDialog<rtc.DesktopCapturerSource?>(
            context: context,
            builder: (context) => WindowScreenSelectDialog(),
          );
          if (source == null) return;
          sourceId = source.id;
        }
        final screenTrack = await LocalVideoTrack.createScreenShareTrack(
          ScreenShareCaptureOptions(
            sourceId: sourceId,
            captureScreenAudio: true,
            maxFrameRate: 30,
            params: VideoParametersPresets.screenShareH1080FPS30,
          ),
        );
        await localParticipant.publishVideoTrack(screenTrack);
        state = AsyncData(
          currentState.copyWith(
            screenSharing: true,
            screenShareTrack: screenTrack,
          ),
        );
        log.info("屏幕共享已开启");
      } else {
        final screenPub = localParticipant.videoTrackPublications
            .where((p) => p.isScreenShare)
            .firstOrNull;
        if (screenPub != null) {
          await localParticipant.removePublishedTrack(screenPub.sid);
        }
        state = AsyncData(
          currentState.copyWith(screenSharing: false, screenShareTrack: null),
        );
        log.info("屏幕共享已关闭");
      }
    } catch (e) {
      log.error("切换屏幕共享失败: $e");
      final currentState = state.value;
      if (context.mounted && currentState != null) {
        state = AsyncData(
          currentState.copyWith(screenSharing: false, screenShareTrack: null),
        );
      }
    } finally {
      _isTogglingScreen = false;
    }
  }

  Future<void> toggleSpeaker() async {
    final currentState = state.value;
    if (currentState == null) return;
    try {
      final next = !currentState.speakerOn;
      await Hardware.instance.setSpeakerphoneOn(next);
      state = AsyncData(currentState.copyWith(speakerOn: next));
      log.info("扬声器${next ? "开启" : "关闭"}");
    } catch (e) {
      log.error("切换扬声器失败: $e");
    }
  }

  Future<void> switchAudioInput(MediaDevice device) async {
    final currentState = state.value;
    if (currentState == null) return;
    try {
      await Hardware.instance.selectAudioInput(device);
      final localParticipant = currentState.room.localParticipant;
      if (localParticipant != null &&
          localParticipant.audioTrackPublications.isNotEmpty) {
        final audioTrack =
            localParticipant.audioTrackPublications.first.track
                as LocalAudioTrack;
        await audioTrack.restartTrack();
      }
      state = AsyncData(currentState.copyWith(currentAudioInput: device));
      log.info("切换麦克风至: ${device.label}");
    } catch (e) {
      log.error("切换麦克风失败: $e");
    }
  }

  Future<void> switchVideoInput(MediaDevice device) async {
    final currentState = state.value;
    if (currentState == null) return;
    try {
      await currentState.room.setVideoInputDevice(device);
      state = AsyncData(currentState.copyWith(currentVideoInput: device));
      log.info("切换摄像头至: ${device.label}");
    } catch (e) {
      log.error("切换摄像头失败: $e");
    }
  }

  Future<void> switchAudioOutput(MediaDevice device) async {
    final currentState = state.value;
    if (currentState == null) return;
    try {
      await Hardware.instance.selectAudioOutput(device);
      state = AsyncData(currentState.copyWith(currentAudioOutput: device));
      log.info("切换扬声器至: ${device.label}");
    } catch (e) {
      log.error("切换扬声器失败: $e");
    }
  }

  Future<void> leave() async {
    final currentState = state.value;
    if (currentState != null) {
      await currentState.room.disconnect();
      log.info("已离开房间");
    }
  }

  Future<void> reconnect() async {
    final currentState = state.value;
    if (currentState == null) return;
    await _connectRoom(currentState.room, currentState.token);
  }

  /// 发送自定义数据事件（举手/表情/主持人指令等）
  Future<void> sendDataEvent(String type, Map<String, dynamic> payload) async {
    final currentState = state.value;
    if (currentState == null) return;
    try {
      final data = jsonEncode({
        'type': type,
        'payload': payload,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      await currentState.room.localParticipant?.publishData(
        utf8.encode(data),
        topic: 'app-event',
      );
      log.info("📤 发送数据事件: type=$type");
    } catch (e) {
      log.error("发送数据事件失败: $e");
    }
  }
}

@riverpod
Future<String> roomToken(Ref ref, String roomId) async {
  try {
    log.info("请求房间 Token");
    final res = await DioClient().get(
      API.callToken,
      queryParameters: {"roomId": roomId},
    );
    if (res.data == null) throw Exception("Token 获取失败，响应数据异常");
    if (res.data["code"] == 200) {
      log.info("获取房间 Token 成功");
      return res.data["data"].toString();
    } else {
      throw Exception("Token 获取失败: ${res.data["message"] ?? "未知错误"}");
    }
  } catch (e) {
    log.error("获取房间 Token 失败: $e");
    rethrow;
  }
}
