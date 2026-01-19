import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/RoomState.dart';

part 'room_controller.g.dart';

@riverpod
class RoomController extends _$RoomController {
  late final Room _room;
  final List<CancelListenFunc> _roomEventCancels = [];
  StreamSubscription? _deviceSub;

  @override
  RoomState build(Room room) {
    _room = room;

    // 1. 自动清理资源
    ref.onDispose(_dispose);

    // 2. 绑定事件监听
    _bindRoomEvents();
    _bindDeviceEvents();

    // 3. 异步初始化硬件列表
    Future.microtask(() => _loadInitialDevices());

    // 4. 返回当前房间的真实快照作为初始状态
    // 这样 UI 一进来就是正确的，不需要等待第一个事件触发
    return RoomState.initial().copyWith(
      connectionState: _room.connectionState,
      remoteParticipants: _room.remoteParticipants.values.toList(),
      micEnabled: _room.localParticipant?.isMicrophoneEnabled() ?? true,
      cameraEnabled: _room.localParticipant?.isCameraEnabled() ?? false,
      speakerOn: true, // 默认开启扬声器
    );
  }

  // ================= 事件绑定 =================

  void _bindRoomEvents() {
    final cancel = _room.events.listen((event) {
      if (event is RoomConnectedEvent || event is RoomDisconnectedEvent) {
        state = state.copyWith(connectionState: _room.connectionState);
      } else if (event is ParticipantConnectedEvent ||
          event is ParticipantDisconnectedEvent) {
        state = state.copyWith(
          remoteParticipants: _room.remoteParticipants.values.toList(),
        );
      }
      // 当有轨道发布/取消发布时，也可以触发 UI 刷新
      if (event is TrackPublishedEvent || event is TrackUnpublishedEvent) {
        state = state.copyWith(
          remoteParticipants: _room.remoteParticipants.values.toList(),
        );
      }
    });
    _roomEventCancels.add(cancel);
  }

  void _bindDeviceEvents() {
    _deviceSub = Hardware.instance.onDeviceChange.stream.listen(
      (_) => _loadInitialDevices(),
    );
  }

  // ================= 核心功能 API =================

  /// 加载并同步所有硬件设备
  Future<void> _loadInitialDevices() async {
    final devices = await Hardware.instance.enumerateDevices();
    state = state.copyWith(
      audioInputs: devices.where((d) => d.kind == 'audioinput').toList(),
      audioOutputs: devices.where((d) => d.kind == 'audiooutput').toList(),
      videoInputs: devices.where((d) => d.kind == 'videoinput').toList(),
      currentAudioInput: Hardware.instance.selectedAudioInput,
      currentAudioOutput: Hardware.instance.selectedAudioOutput,
      currentVideoInput: Hardware.instance.selectedVideoInput,
    );
  }

  /// 切换麦克风开关
  Future<void> toggleMic() async {
    final next = !state.micEnabled;
    await _room.localParticipant?.setMicrophoneEnabled(next);
    state = state.copyWith(micEnabled: next);
  }

  /// 切换摄像头开关
  Future<void> toggleCamera() async {
    final next = !state.cameraEnabled;
    await _room.localParticipant?.setCameraEnabled(next);
    state = state.copyWith(cameraEnabled: next);
  }

  /// 切换屏幕共享
  Future<void> toggleScreenShare(BuildContext context) async {
    final next = !state.screenSharing;

    try {
      if (next) {
        String? sourceId;

        // 1. 如果是桌面端，必须弹出你源码里的那个对话框
        if (lkPlatformIsDesktop()) {
          final source = await showDialog<rtc.DesktopCapturerSource?>(
            context: context,
            builder: (context) => ScreenSelectDialog(),
          );

          // 如果用户取消了选择，直接返回，不开启共享
          if (source == null) return;
          sourceId = source.id;
        }

        if (!context.mounted) return;
        print(
          "准备创建轨道，使用 SourceID: '${sourceId}' (类型: ${sourceId.runtimeType})",
        );
        final options = ScreenShareCaptureOptions(
          sourceId: sourceId,
          captureScreenAudio: true,
          maxFrameRate: 30,
          params: VideoParametersPresets.screenShareH1080FPS30,
        );
        var track = await LocalVideoTrack.createScreenShareTrack(options);
        print("轨道创建成功，准备发布...$track");
        await _room.localParticipant?.publishVideoTrack(track);
        print("_room发布成功");
      } else {
        final screenTracks = _room.localParticipant?.videoTrackPublications
            .where((p) => p.source == TrackSource.screenShareVideo)
            .toList();

        if (screenTracks != null) {
          for (var t in screenTracks) {
            // await _room.localParticipant?.unpublishAllTracks(notify: true,stopOnUnpublish: true);
            await t
                .mute(); // 或者 await _room.localParticipant.unpublishTrack(t.track!.sid!);
            if (t.track != null) {
              await _room.localParticipant?.unpublishAllTracks();
            }
          }
        }
      }

      // 3. 更新状态
      state = state.copyWith(screenSharing: next);
    } catch (e) {
      print("屏幕共享操作失败: $e");
      // 发生错误（如权限拒绝）时，重置 UI 状态
      state = state.copyWith(screenSharing: false);
    }
  }

  /// 切换扬声器/听筒 (Native 平台支持)
  Future<void> toggleSpeaker() async {
    final next = !state.speakerOn;
    await _room.setSpeakerOn(next);
    state = state.copyWith(speakerOn: next);
  }

  /// 切换具体的输入设备（如换一个摄像头或麦克风）
  Future<void> switchAudioInput(MediaDevice device) async {
    await Hardware.instance.selectAudioInput(device);
    state = state.copyWith(currentAudioInput: device);
  }

  Future<void> switchVideoInput(MediaDevice device) async {
    await _room.setVideoInputDevice(device);
    state = state.copyWith(currentVideoInput: device);
  }

  Future<void> leave() async {
    try {
      // 在 LiveKit 中，断开连接使用 disconnect()
      await _room.disconnect();
      print("已成功离开房间");
    } catch (e) {
      print("离开房间时出错: $e");
    }
  }

  // ================= 资源释放 =================

  void _dispose() {
    for (var cancel in _roomEventCancels) {
      cancel();
    }
    _deviceSub?.cancel();
    // 注意：Room 对象通常在 NotCodePage 处 disconnect，这里负责清理 Provider 内部监听
  }
}
