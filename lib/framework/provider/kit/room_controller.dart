import 'dart:async';

import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/RoomState.dart';
import '../../network/DioClient.dart';

part 'room_controller.g.dart';

@riverpod
class RoomController extends _$RoomController {
  final List<CancelListenFunc> _roomEventCancels = [];
  StreamSubscription? _deviceSub;

  @override
  Future<RoomState> build(String token) async {
    final room = Room(
      roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
    );

    // 1. 注册销毁回调（最先注册，确保万无一失）
    ref.onDispose(() async {
      _dispose(); // 清理监听
      await room.disconnect();
      await room.dispose();
    });

    // 2. 异步连接
    await room.prepareConnection(API.wsRoomBaseUrl, token);
    await room.connect(API.wsRoomBaseUrl, token);

    // 3. 绑定监听
    _bindRoomEvents(room);
    _bindDeviceEvents();

    // 4. 获取初始硬件设备
    final devices = await Hardware.instance.enumerateDevices();

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
    );
  }

  // ================= 事件绑定 =================

  void _bindRoomEvents(Room room) {
    final cancel = room.events.listen((event) {
      // 关键：在事件回调内部获取最新状态
      final currentState = state.value;
      if (currentState == null) return;

      if (event is RoomConnectedEvent || event is RoomDisconnectedEvent) {
        log.info("房间状态发生变化：$event");
        state = AsyncData(currentState.copyWith(connectionState: room.connectionState));
      } else if (event is ParticipantConnectedEvent || event is ParticipantDisconnectedEvent) {
        log.info("参与者发生变化：$event");
        state = AsyncData(currentState.copyWith(
          remoteParticipants: room.remoteParticipants.values.toList(),
        ));
      } else if (event is TrackPublishedEvent || event is TrackUnpublishedEvent) {
        log.info("轨道发生变化：$event");
        state = AsyncData(currentState.copyWith(
          remoteParticipants: room.remoteParticipants.values.toList(),
        ));
      }
    });
    _roomEventCancels.add(cancel);
  }

  void _bindDeviceEvents() {
    _deviceSub = Hardware.instance.onDeviceChange.stream.listen((_) => _loadInitialDevices());
  }

  // ================= 核心功能 API =================

  Future<void> _loadInitialDevices() async {
    final currentState = state.value;
    if (currentState == null) return;

    final devices = await Hardware.instance.enumerateDevices();
    state = AsyncData(currentState.copyWith(
      audioInputs: devices.where((d) => d.kind == 'audioinput').toList(),
      audioOutputs: devices.where((d) => d.kind == 'audiooutput').toList(),
      videoInputs: devices.where((d) => d.kind == 'videoinput').toList(),
      currentAudioInput: Hardware.instance.selectedAudioInput,
      currentAudioOutput: Hardware.instance.selectedAudioOutput,
      currentVideoInput: Hardware.instance.selectedVideoInput,
    ));
  }

  Future<void> toggleMic() async {
    final currentState = state.value;
    if (currentState == null) return;

    final next = !currentState.micEnabled;
    await currentState.room.localParticipant?.setMicrophoneEnabled(next);
    state = AsyncData(currentState.copyWith(micEnabled: next));
  }

  Future<void> toggleCamera() async {
    final currentState = state.value;
    if (currentState == null) return;

    final next = !currentState.cameraEnabled;
    await currentState.room.localParticipant?.setCameraEnabled(next);
    state = AsyncData(currentState.copyWith(cameraEnabled: next));
  }

  Future<void> toggleScreenShare(BuildContext context) async {
    final currentState = state.value;
    if (currentState == null) return;

    final next = !currentState.screenSharing;
    try {
      if (next) {
        String? sourceId;
        if (lkPlatformIsDesktop()) {
          final source = await showDialog<rtc.DesktopCapturerSource?>(
            context: context,
            builder: (context) => ScreenSelectDialog(),
          );
          if (source == null) return;
          sourceId = source.id;
        }

        if (!context.mounted) return;
        final options = ScreenShareCaptureOptions(
          sourceId: sourceId,
          captureScreenAudio: true,
          maxFrameRate: 30,
          params: VideoParametersPresets.screenShareH1080FPS30,
        );
        var track = await LocalVideoTrack.createScreenShareTrack(options);
        await currentState.room.localParticipant?.publishVideoTrack(track);
      } else {
        await currentState.room.localParticipant?.unpublishAllTracks();
      }
      state = AsyncData(currentState.copyWith(screenSharing: next));
    } catch (e) {
      log.error("屏幕共享操作失败: $e");
      state = AsyncData(currentState.copyWith(screenSharing: false));
    }
  }

  Future<void> toggleSpeaker() async {
    final currentState = state.value;
    if (currentState == null) return;

    final next = !currentState.speakerOn;
    await currentState.room.setSpeakerOn(next);
    state = AsyncData(currentState.copyWith(speakerOn: next));
  }

  Future<void> switchAudioInput(MediaDevice device) async {
    final currentState = state.value;
    if (currentState == null) return;

    await Hardware.instance.selectAudioInput(device);
    state = AsyncData(currentState.copyWith(currentAudioInput: device));
  }

  Future<void> switchVideoInput(MediaDevice device) async {
    final currentState = state.value;
    if (currentState == null) return;

    await currentState.room.setVideoInputDevice(device);
    state = AsyncData(currentState.copyWith(currentVideoInput: device));
  }

  Future<void> leave() async {
    state.value?.room.disconnect();
  }

  void _dispose() {
    for (var cancel in _roomEventCancels) {
      cancel();
    }
    _deviceSub?.cancel();
  }
}

@riverpod
Future<String> roomToken(Ref ref, String roomId) async {
  final res = await DioClient().get(
    "/call/room",
    queryParameters: {"roomId": roomId},
    options: Options(responseType: ResponseType.plain),
  );

  return res.data.toString();
}