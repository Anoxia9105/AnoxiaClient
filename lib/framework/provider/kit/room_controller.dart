import 'dart:async';
import 'dart:math';

import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../pages/sub_window/component/WindowScreenSelectDialog.dart';
import '../../domain/RoomState.dart';
import '../../network/DioClient.dart';

part 'room_controller.g.dart';

@riverpod
class RoomController extends _$RoomController {
  final List<CancelListenFunc> _roomEventCancels = [];
  StreamSubscription? _deviceSub;
  StreamSubscription? _reconnectSub;
  Timer? _reconnectTimer;

  // 重连配置
  static const int _maxReconnectAttempts = 5;
  int _reconnectAttempts = 0;

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
      _bindRoomEvents(room);
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

    // 初始化麦克风（默认开启）
    if (localParticipant.audioTrackPublications.isEmpty) {
      final audioTrack = await LocalAudioTrack.create();
      await localParticipant.publishAudioTrack(audioTrack);
    }

    // 初始化摄像头（默认开启）
    if (localParticipant.videoTrackPublications.isEmpty) {
      final videoTrack = await LocalVideoTrack.createCameraTrack();
      await localParticipant.publishVideoTrack(videoTrack);
    }
  }

  /// 绑定房间事件
  void _bindRoomEvents(Room room) {
    // 连接状态变化
    _roomEventCancels.add(
      room.events.listen((event) {
        final currentState = state.value;
        if (currentState == null) return;

        if (event is RoomConnectedEvent) {
          log.info("房间已连接");
          state = AsyncData(
            currentState.copyWith(
              connectionState: room.connectionState,
              isReconnecting: false,
              connectionError: null,
            ),
          );
          _reconnectAttempts = 0; // 重置重连次数
        } else if (event is RoomDisconnectedEvent) {
          log.error("房间已断开: ${event.reason}");
          state = AsyncData(
            currentState.copyWith(
              connectionState: room.connectionState,
              connectionError: "连接已断开",
              isReconnecting: true,
            ),
          );
          _startReconnect(room); // 触发重连
        } else if (event is ParticipantConnectedEvent ||
            event is ParticipantDisconnectedEvent) {
          log.info("参与者变化: $event");
          state = AsyncData(
            currentState.copyWith(
              remoteParticipants: room.remoteParticipants.values.toList(),
            ),
          );
        } else if (event is TrackPublishedEvent ||
            event is TrackUnpublishedEvent) {
          log.info("轨道状态变化: $event");
          state = AsyncData(
            currentState.copyWith(
              remoteParticipants: room.remoteParticipants.values.toList(),
            ),
          );
        }
      }),
    );
  }

  /// 绑定设备事件
  void _bindDeviceEvents() {
    _deviceSub = Hardware.instance.onDeviceChange.stream.listen((_) async {
      await _loadDeviceList();
    });
  }

  /// 启动重连逻辑
  void _startReconnect(Room room) {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      log.error("重连次数达到上限，停止重连");
      final currentState = state.value;
      if (currentState != null) {
        state = AsyncData(
          currentState.copyWith(
            isReconnecting: false,
            connectionError: "重连失败，请手动重新连接",
          ),
        );
      }
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(seconds: pow(2, _reconnectAttempts).toInt()), // 指数退避
      () async {
        _reconnectAttempts++;
        log.info("开始第 $_reconnectAttempts 次重连");
        final currentState = state.value;
        if (currentState != null) {
          state = AsyncData(currentState.copyWith(isReconnecting: true));
        }

        try {
          await _connectRoom(room, currentState?.token ?? "");
        } catch (e) {
          log.error("第 $_reconnectAttempts 次重连失败: $e");
          _startReconnect(room); // 继续重连
        }
      },
    );
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
    // 取消所有事件监听
    for (var cancel in _roomEventCancels) {
      cancel();
    }
    _deviceSub?.cancel();
    _reconnectSub?.cancel();

    // 取消重连定时器
    _reconnectTimer?.cancel();

    // 清理屏幕共享轨道
    final currentState = state.value;
    if (currentState?.screenShareTrack != null) {
      currentState!.screenShareTrack!.stop();
      currentState.screenShareTrack!.dispose();
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

        final options = ScreenShareCaptureOptions(
          sourceId: sourceId,
          captureScreenAudio: true,
          maxFrameRate: 30,
          params: VideoParametersPresets.screenShareH1080FPS30,
        );

        final screenTrack = await LocalVideoTrack.createScreenShareTrack(
          options,
        );
        await localParticipant.publishVideoTrack(screenTrack);

        // 更新状态（保存屏幕共享轨道引用）
        state = AsyncData(
          currentState.copyWith(
            screenSharing: true,
            screenShareTrack: screenTrack,
          ),
        );
        log.info("屏幕共享已开启");
      } else {
        // 关闭屏幕共享（只关闭屏幕轨道，保留摄像头和麦克风）
        if (currentState.screenShareTrack != null) {
          // 停止并释放屏幕共享轨道，SDK会自动取消发布
          await currentState.screenShareTrack!.stop();
          await currentState.screenShareTrack!.dispose();
        }

        // 更新状态
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

    _reconnectAttempts = 0;
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
