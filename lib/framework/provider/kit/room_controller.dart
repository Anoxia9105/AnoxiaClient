import 'dart:async';
import 'dart:math';

import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../pages/call_window/component/WindowScreenSelectDialog.dart';
import '../../domain/RoomState.dart';
import '../../network/DioClient.dart';

part 'room_controller.g.dart';

@riverpod
class RoomController extends _$RoomController {
  late final EventsListener<RoomEvent> _listener;

  // 操作防抖
  bool _isToggling = false;

  @override
  Future<RoomState> build(String token) async {
    // 初始化房间实例
    final room = Room(
      roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
    );

    // 注册销毁回调（最高优先级）
    ref.onDispose(() async {
      _disposeResources();
      await room.disconnect();
      await room.dispose();
      log.info("房间控制器已销毁");
    });

    try {
      // 连接房间（带超时处理）
      await _connectRoom(room, token);

      // 绑定事件监听
      _listener = room.createListener();

      _listener
        ..on<RoomConnectedEvent>((_) => log.info("房间已连接"))
        ..on<RoomDisconnectedEvent>((_) => log.info("房间已断开"))
        ..on<ParticipantConnectedEvent>((e) {
          log.info("有人加入: ${e.participant.identity}");
          updateState(); // 有人加入，列表变了，必须刷新
        })
        ..on<ParticipantDisconnectedEvent>((e) {
          log.info("有人离开: ${e.participant.identity}");
          updateState(); // 有人离开，列表变了，必须刷新
        })
        ..on<ActiveSpeakersChangedEvent>((e) {
          // 说话者变化。虽然 UI 组件自己会监听，但这里更新有助于排序
          updateState();
        });

      room.addListener(updateState);

      _bindDeviceEvents();

      // 获取初始设备列表
      final devices = await _getInitialDevices();

      // 初始化本地轨道（麦克风/摄像头）
      await _initLocalTracks(room);

      // 返回初始状态
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
    } catch (e) {
      log.error("房间初始化失败: $e");
      // 清理资源
      await room.dispose();
      rethrow;
    }
  }

  void updateState() {
    if (state.value != null) {
      state = AsyncData(
        state.value!.copyWith(
          remoteParticipants: state.value?.room.remoteParticipants.values
              .toList(),
          // 这里可以强制更新一个随机数或时间戳来触发 notify，
          // 但通常 copyWith 列表就够了
        ),
      );
    }
  }

  // ================= 核心私有方法 =================

  /// 连接房间（带超时）
  Future<void> _connectRoom(Room room, String token) async {
    await Future.wait([
      room.prepareConnection(API.wsRoomBaseUrl, token),
      room
          .connect(API.wsRoomBaseUrl, token)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException("连接房间超时"),
          ),
    ]);
    log.info("房间连接成功: ${room.name}");
  }

  /// 获取初始设备列表
  Future<List<MediaDevice>> _getInitialDevices() async {
    try {
      return await Hardware.instance.enumerateDevices();
    } catch (e) {
      log.error("获取设备列表失败: $e");
      return [];
    }
  }

  /// 初始化本地轨道
  Future<void> _initLocalTracks(Room room) async {
    final localParticipant = room.localParticipant;
    if (localParticipant == null) return;

    try {
      localParticipant.setCameraEnabled(false);
      localParticipant.setMicrophoneEnabled(false);

      log.info(
        "本地轨道初始化》mic：${localParticipant.isMicrophoneEnabled()}video：${localParticipant.isCameraEnabled()}screen：${localParticipant.isScreenShareEnabled()}",
      );
    } catch (e) {
      log.error("初始化本地硬件失败，可能设备被占用或无权限: $e");
    }
  }

  /// 绑定设备事件
  void _bindDeviceEvents() {
    // 这里的监听直接存为局部变量
    final sub = Hardware.instance.onDeviceChange.stream.listen((_) async {
      await _loadDeviceList();
    });

    // 销毁时自动取消
    ref.onDispose(() => sub.cancel());
  }

  /// 加载设备列表
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

  /// 清理资源
  void _disposeResources() {
    _listener.dispose();

    final currentState = state.value;
    if (currentState != null) {
      currentState.room.removeListener(updateState);
    }

    log.info("资源已清理");
  }

  // ================= 公开功能 API =================

  /// 切换麦克风
  Future<void> toggleMic() async {
    if (_isToggling) return;
    _isToggling = true;

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
      _isToggling = false;
    }
  }

  /// 切换摄像头
  Future<void> toggleCamera() async {
    if (_isToggling) return;
    _isToggling = true;

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
      _isToggling = false;
    }
  }

  /// 切换屏幕共享（精细化管理轨道，不影响摄像头）
  Future<void> toggleScreenShare(BuildContext context) async {
    if (_isToggling) return;
    _isToggling = true;

    try {
      final currentState = state.value;
      if (currentState == null || !context.mounted) return;

      final next = !currentState.screenSharing;
      final localParticipant = currentState.room.localParticipant;
      if (localParticipant == null) return;

      if (next) {
        // 开启屏幕共享
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
      // 恢复状态
      final currentState = state.value;
      if (context.mounted && currentState != null) {
        state = AsyncData(
          currentState.copyWith(screenSharing: false, screenShareTrack: null),
        );
      }
    } finally {
      _isToggling = false;
    }
  }

  /// 切换扬声器
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

  /// 切换音频输入设备（麦克风）
  Future<void> switchAudioInput(MediaDevice device) async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      await Hardware.instance.selectAudioInput(device);
      // 重启音频轨道以应用新设备
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

  /// 切换视频输入设备（摄像头）
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

  /// 切换音频输出设备（扬声器/耳机）
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

  /// 离开房间
  Future<void> leave() async {
    final currentState = state.value;
    if (currentState != null) {
      await currentState.room.disconnect();
      log.info("已离开房间");
    }
  }

  /// 手动重连
  Future<void> reconnect() async {
    final currentState = state.value;
    if (currentState == null) return;
    await _connectRoom(currentState.room, currentState.token);
  }
}

@riverpod
Future<String> roomToken(Ref ref, String roomId) async {
  try {
    final res = await DioClient().get(
      "/call/room",
      queryParameters: {"roomId": roomId},
      options: Options(responseType: ResponseType.plain),
    );
    return res.data.toString();
  } catch (e) {
    log.error("获取房间Token失败: $e");
    rethrow;
  }
}
