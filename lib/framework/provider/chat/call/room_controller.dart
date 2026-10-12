import 'dart:async';
import 'dart:convert';

import 'package:anoxia/common/constants/api.dart';
import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/utils/app_permission.dart';
import 'package:anoxia/framework/provider/core/toast_service_provider.dart';
import 'package:anoxia/framework/provider/core/call_repository_provider.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:anoxia/platform/shims/flutter_background_shim.dart' as rtc;
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:anoxia/platform/shims/window_manager_shim.dart';

import '../../../domain/room_state.dart';
import 'call_initial_media.dart';
import 'call_initialization.dart';
import '../../../domain/call_media_preferences.dart';
import 'call_screen_share.dart';
import 'call_connection_warmup.dart';
import 'call_media_lifecycle.dart';
import 'call_recovery_policy.dart';
import 'mobile_call_session_provider.dart';

part 'room_controller.g.dart';

/// 房间控制器
/// 负责管理 LiveKit 房间的完整生命周期：
///   - 连接 / 断开 / 重连
///   - 本地媒体（麦克风、摄像头、屏幕共享）
///   - 设备切换
///   - 自定义数据通道（举手、表情、弹幕、主持人静音指令）
@Riverpod(keepAlive: true)
class RoomController extends _$RoomController {
  /// 已主动离开的 token 集合（静态，跨实例共享）。
  ///
  /// `leave()` 和 `_handleRemovedFromCall()` 在调用 `ref.invalidateSelf()`
  /// 之前会将当前 token 加入此集合。`build()` 重建时检查此集合，
  /// 若 token 已在其中则直接抛异常，阻止重新创建 Room 并连接。
  ///
  /// 这是为了防止 Web WASM 环境下 `invalidateSelf` → 重建 → 连接 →
  /// 断开 → 事件回调 → 再次 `invalidateSelf` 的无限循环导致的栈溢出。
  static final Set<String> _disposedTokens = <String>{};

  /// LiveKit 事件监听器，负责监听房间内所有事件
  EventsListener<RoomEvent>? _listener;

  /// 设备热插拔监听订阅
  StreamSubscription<dynamic>? _deviceSub;

  /// 各操作的独立防抖锁，防止用户快速连续点击导致状态错乱
  bool _isTogglingMic = false;
  bool _isTogglingCamera = false;
  bool _isTogglingScreen = false;
  bool _removedFromCallHandled = false;

  /// 1:1 通话「远端全部离开」兜底检测定时器。
  ///
  /// 信令（CALL_END）可能因网络/进程被杀而丢失，这里用媒体层兜底：
  /// 一旦曾出现过远端参与者，且连续 3 秒远端为空、房间仍连接且非重连态，
  /// 判定对端已挂断/断线，本地结束通话（详见 [_schedulePeerGoneCheck]）。
  Timer? _peerGoneTimer;
  bool _everHadRemote = false;

  /// 防止 leave() 重入
  bool _isLeaving = false;
  final _recoveryPolicy = CallRecoveryPolicy();
  Timer? _recoveryTimer;
  bool _recoveringConnection = false;
  DisconnectReason? _lastDisconnectReason;

  /// 进行中的「离开房间」过程。
  ///
  /// 并发调用 [leave]（例如桌面端「挂断按钮」与「窗口关闭回调」同时触发）
  /// 会复用同一个 Future，调用方可以安全 await：必须等 WebRTC 资源真正释放
  /// 之后再销毁窗口，因为桌面端子窗口关闭会直接拆除该窗口的引擎，带着活跃的
  /// 通话会话销毁引擎会让原生侧在析构过程中崩溃（表现为整个应用闪退）。
  Future<void>? _leaveFuture;
  CallMediaLifecycle? _mediaLifecycle;
  CallMediaPreferences _preferences = const CallMediaPreferences();
  Set<String> _supportedVideoCodecs = {'vp8'};
  CallScreenShare? _screenSession;
  bool _applyingPreferences = false;
  final _mediaQueues = <CallMediaLane, CallMediaOperationQueue>{};
  Duration? connectionDuration;
  RoomState? get _currentState =>
      ref.mounted && !_isLeaving && _mediaLifecycle?.isClosing != true
      ? state.value
      : null;

  // ================= Riverpod build =================

  /// Provider 入口
  /// [token] 是加入房间用的 JWT Token，由服务端下发
  ///
  /// 执行顺序：
  ///   1. 创建 Room 实例
  ///   2. 注册 dispose 回调（最高优先级，确保资源一定被释放）
  ///   3. 绑定事件监听
  ///   4. 连接房间
  ///   5. 初始化设备列表 & 本地轨道
  ///   6. 返回初始 RoomState
  @override
  Future<RoomState> build(String token) async {
    // 若此 token 已被 leave()/onDispose 标记为已处理，不再重新连接。
    // 防止 invalidateSelf 重建后陷入"连接→断开→重建"的无限循环（Web WASM 栈溢出根因）。
    // Riverpod 3 会自动重试失败的 build，不能检查后就移除标记，
    // 否则下一次重试会在挂断后重新开启媒体。重新拨号应使用新 token。
    if (_disposedTokens.contains(token)) {
      throw StateError('房间已离开，不再重连');
    }

    final room = Room(
      roomOptions: const RoomOptions(
        adaptiveStream: true, // 自适应流：根据网络自动降码率
        dynacast: true, // 动态广播：只向订阅者发流，节省带宽
      ),
    );

    final lifecycle = CallMediaLifecycle(
      dispose: () async {
        await _disposeResources();
        try {
          // 等待 SDK 自己结束断连，不用 timeout 制造并行的 dispose。
          await room.disconnect();
        } catch (e, st) {
          debugLog('断连失败，继续释放房间资源', e, st);
        }
        // 释放失败必须传给关窗流程，不能带着未释放的资源销毁引擎。
        await room.dispose();
        await _releaseScreenShareKeepAlive();
      },
    );
    _mediaLifecycle = lifecycle;

    // 注册销毁回调（Provider 被销毁时自动执行）
    // 注意：onDispose 中不能访问 provider state，否则会触发 Riverpod 断言
    ref.onDispose(() {
      // 与 leave / 初始化失败共用同一次清理，不能并发 disconnect / dispose。
      unawaited(
        lifecycle.close().catchError((Object e, StackTrace st) {
          debugLog('通话资源兜底清理失败', e, st);
        }),
      );
    });

    try {
      return await lifecycle.run(() => _initializeRoom(room, token, lifecycle));
    } catch (e) {
      debugLog('房间初始化失败: $e');
      await lifecycle.close();
      rethrow;
    }
  }

  Future<RoomState> _initializeRoom(
    Room room,
    String token,
    CallMediaLifecycle lifecycle,
  ) async {
    // 偏好读取和编码能力探测与建连并行，不把设备探测放到信令关键路径。
    final preferencesReady = _loadMediaPreferences();
    // 创建事件监听器并保存引用（用于 dispose）
    // 注意：用局部变量接收，避免 _listener 可空导致的 null check 问题
    final listener = room.createListener();
    _listener = listener;

    listener
      // ============ 房间级别事件 ============
      /// 房间连接成功
      /// 通常在 build 中 connect 之后就会触发，这里主要用于清除之前的错误状态
      ..on<RoomConnectedEvent>((event) {
        _recoveryPolicy.markConnected(DateTime.now());
        if (_recoveringConnection) return;
        final current = _currentState;
        if (current != null && current.connectionError != null) {
          state = AsyncData(
            current.copyWith(
              connectionState: ConnectionState.connected,
              clearConnectionError: true,
              isReconnecting: false,
            ),
          );
        }
      })
      /// 房间断开连接
      /// SDK 会在网络中断或主动 disconnect 后触发
      /// 重连逻辑由 SDK 自动处理，不需要手动干预
      ..on<RoomDisconnectedEvent>((event) {
        if (_isLeaving || lifecycle.isClosing) return;
        _lastDisconnectReason = event.reason;
        _recoveryTimer?.cancel();
        debugLog(
          'LiveKit 意外断开: reason=${event.reason?.name ?? 'unknown'}, '
          'room=${room.name}, remoteCount=${room.remoteParticipants.length}',
        );
        if (event.reason == DisconnectReason.participantRemoved) {
          unawaited(_handleRemovedFromCall('call_host'.tr()));
          return;
        }
        _updateState(
          (current) => current.copyWith(
            connectionState: ConnectionState.disconnected,
            isReconnecting: false,
            connectionError: event.reason?.name ?? 'connectionLost',
          ),
        );
        if (!_recoveringConnection) _scheduleConnectionRecovery(event.reason);
      })
      /// 房间正在重连中（网络抖动时触发）
      /// 更新 isReconnecting 状态，UI 层展示重连遮罩
      ..on<RoomReconnectingEvent>((event) {
        final current = _currentState;
        if (current != null) {
          state = AsyncData(
            current.copyWith(
              connectionState: ConnectionState.reconnecting,
              isReconnecting: true,
              clearConnectionError: true,
            ),
          );
        }
      })
      /// 房间重连成功
      /// 清除重连状态和错误信息
      ..on<RoomReconnectedEvent>((event) {
        _recoveryTimer?.cancel();
        _recoveryPolicy.markConnected(DateTime.now());
        final current = _currentState;
        if (current != null) {
          state = AsyncData(
            current.copyWith(
              connectionState: ConnectionState.connected,
              isReconnecting: false,
              clearConnectionError: true,
            ),
          );
        }
      })
      /// 房间元数据变化（服务端通过 Server API 更新的房间信息）
      ..on<RoomMetadataChangedEvent>((event) {
        final current = _currentState;
        if (current != null) {
          state = AsyncData(current.copyWith(roomMetadata: event.metadata));
        }
      })
      /// 录制状态变化（服务端开启/停止录制时触发）
      ..on<RoomRecordingStatusChanged>((event) {
        final current = _currentState;
        if (current != null) {
          state = AsyncData(
            current.copyWith(isRecording: event.activeRecording),
          );
        }
      })
      // ============ 参与者事件 ============
      /// 新参与者加入房间
      ..on<ParticipantConnectedEvent>((e) {
        // 远端参与者出现过：兜底检测可生效；有人加入时取消待触发的结束检测
        _peerGoneTimer?.cancel();
        _everHadRemote = true;
        _updateParticipants();
      })
      /// 参与者离开房间
      ..on<ParticipantDisconnectedEvent>((e) {
        _updateParticipants();
        _schedulePeerGoneCheck();
      })
      /// 活跃发言者变化（SDK 根据音量实时检测）
      /// 将第一个发言者设为焦点，UI 层可以据此高亮或置顶
      ..on<ActiveSpeakersChangedEvent>((e) {
        final current = _currentState;
        if (current != null && e.speakers.isNotEmpty) {
          state = AsyncData(
            current.copyWith(focusedParticipantId: e.speakers.first.identity),
          );
        }
      })
      /// 参与者连接质量变化
      /// 对应官方 participant_context.dart 中的 ParticipantConnectionQualityUpdatedEvent
      /// quality 枚举值：excellent / good / poor / lost
      ..on<ParticipantConnectionQualityUpdatedEvent>((e) {
        final current = _currentState;
        if (current != null) {
          final qmap = Map<String, ConnectionQuality>.from(
            current.participantQuality ?? {},
          );
          qmap[e.participant.identity] = e.connectionQuality;
          state = AsyncData(current.copyWith(participantQuality: qmap));
          debugLog(
            '远端信号更新: ${e.participant.identity} '
            '${e.participant.sid} -> ${e.connectionQuality.name}',
          );
        }
      })
      // ============ Track（媒体轨道）事件 ============
      // 以下事件都需要刷新参与者列表，确保 UI 中摄像头/静音状态实时更新
      // 不监听这些事件的话，别人开关摄像头/静音你这边 UI 不会更新
      /// 远端参与者发布了新轨道（如开启摄像头）
      ..on<TrackPublishedEvent>((e) {
        _updateParticipants();
      })
      /// 远端参与者撤销了轨道（如关闭摄像头）
      ..on<TrackUnpublishedEvent>((e) {
        _updateParticipants();
      })
      /// 本地轨道发布成功（自己开启摄像头/麦克风后触发）
      ..on<LocalTrackPublishedEvent>((e) {
        _updateParticipants();
      })
      /// 本地轨道撤销（自己关闭摄像头/麦克风后触发）
      ..on<LocalTrackUnpublishedEvent>((e) {
        _updateParticipants();
        if (e.publication.source == TrackSource.screenShareVideo &&
            !_isTogglingScreen &&
            !_isLeaving) {
          unawaited(
            stopScreenShare().catchError(
              (Object error, StackTrace stack) =>
                  debugLog('系统停止共享失败', error, stack),
            ),
          );
        }
      })
      /// 轨道被静音（任意参与者）
      ..on<TrackMutedEvent>((e) {
        _updateParticipants();
      })
      /// 轨道取消静音（任意参与者）
      ..on<TrackUnmutedEvent>((e) {
        _updateParticipants();
      })
      /// 远端轨道订阅成功 / 取消订阅（任意参与者）
      ///
      /// 订阅完成前远端画面轨道的 track 为 null，无法渲染；
      /// 订阅完成后需刷新参与者列表，让 UI（尤其手机端）切换到共享大屏等视图。
      ..on<TrackSubscribedEvent>((e) {
        _updateParticipants();
      })
      ..on<TrackUnsubscribedEvent>((e) {
        _updateParticipants();
      })
      // ============ 自定义数据通道 ============
      /// 收到房间内任意参与者发送的自定义数据
      /// 注意：LiveKit publishData 不会回传给发送方自己，
      /// 所以发送方需要在发送时直接更新本地状态
      ..on<DataReceivedEvent>((e) {
        _handleDataEvent(e);
      });

    // 先监听再连接，避免快速建连或远端加入时漏掉事件。
    await _connectRoom(room, token);
    lifecycle.ensureOpen();
    await preferencesReady;
    lifecycle.ensureOpen();

    // 绑定设备热插拔监听（耳机插拔、摄像头连接等）
    _bindDeviceEvents();

    // 初始化本地轨道（默认关闭麦克风和摄像头，由用户手动开启）
    // 注意：必须先初始化轨道再枚举设备——Web 端只有获得媒体权限后
    // enumerateDevices 才会返回带名称的设备列表，否则菜单里全是空名称
    await _initLocalTracks(room);
    lifecycle.ensureOpen();

    // 应用「呼出振铃页 / 来电页」上选择的免提偏好（仅原生移动端生效；
    // Web/桌面由系统输出设备决定，无听筒概念）。
    final speakerPref = ref.read(
      callSpeakerPreferenceProvider(room.name ?? ''),
    );
    if (!speakerPref && DeviceUtil.isRealMobile()) {
      try {
        await AudioManager.instance.setSpeakerOutputPreferred(false);
      } catch (e) {
        debugLog('应用免提偏好失败: $e');
      }
    }

    // 获取初始设备列表
    final devices = await _getInitialDevices();
    lifecycle.ensureOpen();
    if (room.connectionState != ConnectionState.connected) {
      throw StateError('房间在初始化期间断开');
    }
    _everHadRemote = room.remoteParticipants.isNotEmpty;

    return RoomState(
      room: room,
      token: token,
      connectionState: room.connectionState,
      micEnabled: room.localParticipant?.isMicrophoneEnabled() ?? false,
      cameraEnabled: room.localParticipant?.isCameraEnabled() ?? false,
      screenSharing: false,
      speakerOn: speakerPref,
      audioInputs: devices.where((d) => d.kind == 'audioinput').toList(),
      audioOutputs: devices.where((d) => d.kind == 'audiooutput').toList(),
      videoInputs: devices.where((d) => d.kind == 'videoinput').toList(),
      currentAudioInput: Hardware.instance.selectedAudioInput,
      currentAudioOutput: Hardware.instance.selectedAudioOutput,
      currentVideoInput: Hardware.instance.selectedVideoInput,
      remoteParticipants: room.remoteParticipants.values.toList(),
      joinedAt: DateTime.now(),
      participantQuality: {},
      mediaPreferences: _preferences,
      supportedVideoCodecs: _supportedVideoCodecs,
      participantVolumes: {},
      handRaiseMap: {},
      reactions: [],
    );
  }

  // ================= 核心私有方法 =================

  Future<void> _loadMediaPreferences() async {
    _preferences = await CallMediaPreferences.load();
    try {
      final caps = await rtc
          .getRtpSenderCapabilities('video')
          .timeout(const Duration(seconds: 2));
      final codecs = (caps.codecs ?? [])
          .map((codec) => codec.mimeType.toLowerCase().split('/').last)
          .where((codec) => {'vp8', 'h264', 'vp9', 'av1'}.contains(codec))
          .toSet();
      if (codecs.isNotEmpty) _supportedVideoCodecs = codecs;
    } catch (error, stack) {
      debugLog('探测编码器失败，使用 VP8', error, stack);
    }
  }

  Future<void> _setCameraEnabled(Room room, bool enabled) async {
    _mediaLifecycle?.ensureOpen();
    final participant = room.localParticipant;
    if (participant == null) return;
    if (!enabled ||
        participant.getTrackPublicationBySource(TrackSource.camera) != null) {
      await participant.setCameraEnabled(enabled);
      return;
    }
    final track = await LocalVideoTrack.createCameraTrack(
      _preferences.cameraCaptureOptions(
        deviceId: Hardware.instance.selectedVideoInput?.deviceId,
      ),
    );
    try {
      _mediaLifecycle?.ensureOpen();
      final codec = selectVideoCodec(
        _preferences.cameraCodec,
        _supportedVideoCodecs,
        preferHardwareCodec: DeviceUtil.isRealMobile(),
      );
      await participant.publishVideoTrack(
        track,
        publishOptions: _preferences.cameraPublishOptions(codec),
      );
    } catch (_) {
      await track.dispose();
      rethrow;
    }
  }

  /// 共享设置在下次共享生效；摄像头设置立即重建一次采集/发布。
  Future<void> applyMediaPreferences(
    CallMediaPreferences preferences,
  ) => _runMediaOperation(() async {
    if (_applyingPreferences || _isTogglingCamera || _isTogglingScreen) {
      throw StateError('媒体操作进行中');
    }
    _applyingPreferences = true;
    try {
      final current = _currentState;
      if (current == null) return;
      final cameraChanged =
          preferences.cameraQuality != _preferences.cameraQuality ||
          preferences.cameraCodec != _preferences.cameraCodec;
      await preferences.save();
      _preferences = preferences;
      _updateState((latest) => latest.copyWith(mediaPreferences: preferences));
      _mediaLifecycle?.ensureOpen();
      if (cameraChanged && current.cameraEnabled) {
        final participant = current.room.localParticipant;
        final camera = participant?.getTrackPublicationBySource(
          TrackSource.camera,
        );
        final oldTrack = camera?.track;
        final position =
            oldTrack is LocalVideoTrack &&
                oldTrack.currentOptions is CameraCaptureOptions
            ? (oldTrack.currentOptions as CameraCaptureOptions).cameraPosition
            : CameraPosition.front;
        if (camera != null) await participant!.removePublishedTrack(camera.sid);
        try {
          await _setCameraEnabled(current.room, true);
          final track = participant
              ?.getTrackPublicationBySource(TrackSource.camera)
              ?.track;
          if (track is LocalVideoTrack) await track.setCameraPosition(position);
        } finally {
          _updateState(
            (latest) => latest.copyWith(
              cameraEnabled: participant?.isCameraEnabled() ?? false,
            ),
          );
        }
      }
    } finally {
      _applyingPreferences = false;
    }
  }, lane: CallMediaLane.camera);

  /// 连接房间
  /// 预热在振铃时启动；即使预热还未完成，也不阻塞正式建连。
  /// 使用 SDK 的连接超时；外层 timeout 不会取消原生建连，不能用于资源屏障。
  Future<void> _connectRoom(Room room, String token) async {
    ref.read(callConnectionWarmupProvider).start();
    final watch = Stopwatch()..start();
    await room.connect(API.wsRoomBaseUrl, token);
    connectionDuration = watch.elapsed;
    debugLog('LiveKit 建连完成: ${connectionDuration!.inMilliseconds}ms');
  }

  /// 枚举系统可用媒体设备
  /// 过滤掉无名称设备（Web 端未授权时 enumerateDevices 返回空 label）并去重
  Future<List<MediaDevice>> _getInitialDevices() async {
    try {
      final devices = await Hardware.instance.enumerateDevices();
      return _filterUsableDevices(devices);
    } catch (e) {
      debugLog('获取设备列表失败: $e');
      return [];
    }
  }

  /// 过滤空名称设备并去重
  List<MediaDevice> _filterUsableDevices(List<MediaDevice> devices) {
    final seen = <String>{};
    return devices.where((d) {
      final key = '${d.kind}:${d.deviceId}';
      return d.label.trim().isNotEmpty && seen.add(key);
    }).toList();
  }

  /// 初始化本地轨道
  /// 接受通话后优先打开麦克风，视频通话再启动摄像头。
  Future<void> _initLocalTracks(Room room) async {
    final localParticipant = room.localParticipant;
    if (localParticipant == null) return;
    final roomName = room.name;
    final initialMedia = roomName == null || roomName.isEmpty
        ? CallInitialMedia.audio
        : ref.read(callInitialMediaProvider(roomName));
    var enableCamera = initialMedia == CallInitialMedia.video;
    await initializeCallMedia(
      microphone: () async {
        var enabled = true;
        if (DeviceUtil.isRealMobile()) {
          enabled =
              await appPermissionService.request(Permission.microphone) ==
              AppPermissionResult.granted;
        }
        _mediaLifecycle?.ensureOpen();
        await localParticipant.setMicrophoneEnabled(enabled);
      },
      camera: () async {
        if (enableCamera && DeviceUtil.isRealMobile()) {
          enableCamera =
              await appPermissionService.request(Permission.camera) ==
              AppPermissionResult.granted;
        }
        _mediaLifecycle?.ensureOpen();
        await _setCameraEnabled(room, enableCamera);
      },
      ensureOpen: () => _mediaLifecycle?.ensureOpen(),
      onError: (error, stack) {
        debugLog('初始化本地设备失败', error, stack);
        _notifyMediaFailure('call_media_device_failed');
      },
    );
    if (DeviceUtil.isAndroid()) {
      try {
        await appPermissionService.request(Permission.bluetoothConnect);
      } catch (error, stack) {
        debugLog('蓝牙权限不可用，不阻断通话', error, stack);
      }
    }
  }

  /// 刷新远端参与者列表
  /// 在任何参与者/轨道变化事件中调用，确保 UI 同步最新状态
  /// 同时检测本地屏幕共享轨道是否仍然活跃，防止浏览器取消共享后 UI 状态不同步
  void _updateParticipants() {
    if (!ref.mounted || _isLeaving || _mediaLifecycle?.isClosing == true) {
      return;
    }
    final current = _currentState;
    if (current == null) return;

    bool screenStillActive = current.screenSharing;
    if (current.screenSharing) {
      final localParticipant = current.room.localParticipant;
      screenStillActive =
          localParticipant != null &&
          localParticipant.videoTrackPublications.any(
            (p) => p.isScreenShare && !p.muted,
          );
    }

    state = AsyncData(
      current.copyWith(
        remoteParticipants: current.room.remoteParticipants.values.toList(),
        screenSharing: screenStillActive,
        // 共享结束（系统侧停止/轨道被回收）时释放轨道引用，
        // 否则 copyWith 的 `??` 语义会让旧轨道一直挂在状态里
        clearScreenShareTrack: !screenStillActive,
      ),
    );
  }

  /// 1:1 通话「远端全部离开」兜底检测。
  ///
  /// 触发条件（全部满足才判定结束，避免误杀）：
  /// - 曾出现过远端参与者（排除刚接通、对方尚未加入的窗口期）
  /// - 连续 3 秒远端为空
  /// - 房间仍处于 connected 且非重连态（排除网络抖动重连期）
  /// - 非群聊（群成员进出自如，不触发）
  void _schedulePeerGoneCheck() {
    _peerGoneTimer?.cancel();
    _peerGoneTimer = Timer(const Duration(seconds: 3), () {
      final current = _currentState;
      if (current == null || _isLeaving) return;
      if (current.isReconnecting) return;
      if (current.room.connectionState != ConnectionState.connected) return;
      if (current.remoteParticipants.isNotEmpty) return;
      if (!_everHadRemote) return;
      final roomName = current.room.name ?? '';
      if (roomName.isEmpty) return;
      if (ref.read(callIsGroupProvider(roomName))) return;
      debugLog('1:1 通话远端全部离开，判定通话结束（媒体层兜底）');
      unawaited(_handlePeerLeft(roomName));
    });
  }

  /// 对端挂断/断线兜底：本地结束通话（信令丢失时的最后保障）。
  Future<void> _handlePeerLeft(String roomId) async {
    if (DeviceUtil.isRealMobile() || DeviceUtil.isWeb) {
      final session = ref.read(mobileCallSessionControllerProvider);
      if (session?.roomId != roomId) return;
      ref.read(mobileCallSessionControllerProvider.notifier).end();
      await leave();
      ref.read(toastServiceProvider).showNotificationNow('call_ended'.tr());
      return;
    }
    // 桌面端：关闭通话窗口（主窗口经 on_call_window_close 去重补发信令）
    await windowManager.close();
  }

  /// 处理自定义数据通道事件
  /// LiveKit 的 publishData 不会回传给发送方，
  /// 所以这里只处理其他人发来的消息
  void _handleDataEvent(DataReceivedEvent e) {
    try {
      final json = jsonDecode(utf8.decode(e.data)) as Map<String, dynamic>;
      // payload 是业务数据，timestamp 是发送时间戳（可用于排序或去重）
      final payload = json['payload'] as Map<String, dynamic>? ?? {};

      switch (e.topic) {
        case 'app-hand-raise':
          _onHandRaise(payload);
          break;
        case 'app-chat':
          // 表情和弹幕统一走这个 topic
          _onChat(payload);
          break;
        case 'app-mute-command':
          _onMuteCommand(payload);
          break;
        case 'app-kick-command':
          unawaited(_onKickCommand(payload));
          break;
      }
    } catch (err) {
      debugLog('解析数据事件失败: $err');
    }
  }

  /// 处理远端举手/放手消息
  /// raised=true 加入 map，raised=false 从 map 移除
  void _onHandRaise(Map<String, dynamic> payload) {
    final uid = payload['uid'] as String?;
    final raised = payload['raised'] as bool? ?? false;
    final name = payload['name'] as String? ?? uid ?? '';
    if (uid == null) return;

    final current = _currentState;
    if (current == null) return;

    final map = Map<String, bool>.from(current.handRaiseMap ?? {});
    if (raised) {
      map[uid] = true;
    } else {
      map.remove(uid);
    }
    state = AsyncData(current.copyWith(handRaiseMap: map));

    // Toast 提示
    ref
        .read(toastServiceProvider)
        .showNotificationNow(
          raised
              ? 'call_hand_raised'.tr(args: [name])
              : 'call_hand_lowered'.tr(args: [name]),
        );
  }

  /// 处理远端表情/弹幕消息
  void _onChat(Map<String, dynamic> payload) {
    final message = payload['message'] as String?;
    final uid = payload['uid'] as String?;
    final name = payload['name'] as String? ?? uid ?? '';
    final avatar = payload['avatar'] as String?;
    if (message == null || uid == null) return;

    final current = _currentState;
    if (current == null) return;

    final item = ReactionItem(
      message: message,
      uid: uid,
      name: name,
      avatar: avatar?.isNotEmpty == true ? avatar : null,
      createdAt: DateTime.now(),
    );

    final list = List<ReactionItem>.from(current.reactions ?? [])..add(item);
    state = AsyncData(current.copyWith(reactions: list));

    // 3 秒后自动移除远端 ReactionItem
    _scheduleReactionRemoval(item.id);
  }

  /// 处理主持人静音指令
  /// 收到指令后检查目标是否是自己，是则执行静音/取消静音
  void _onMuteCommand(Map<String, dynamic> payload) {
    unawaited(
      _runMediaOperation(
        () => _applyMuteCommand(payload),
        lane: CallMediaLane.microphone,
      ).catchError((Object e, StackTrace st) => debugLog('执行远端静音指令失败', e, st)),
    );
  }

  Future<void> _applyMuteCommand(Map<String, dynamic> payload) async {
    final targetUid = payload['uid'] as String?;
    final muted = payload['muted'] as bool? ?? true;
    final senderName = payload['senderName'] as String? ?? 'call_host'.tr();
    final current = _currentState;
    if (current == null) return;

    // 只处理发给自己的指令
    final localIdentity = current.room.localParticipant?.identity;
    if (targetUid != localIdentity) return;

    await current.room.localParticipant?.setMicrophoneEnabled(!muted);
    if (!ref.mounted || _isLeaving) return;
    _updateState((latest) => latest.copyWith(micEnabled: !muted));

    // Toast 提示
    ref
        .read(toastServiceProvider)
        .showNotificationNow(
          muted
              ? 'call_muted_by_host'.tr(args: [senderName])
              : 'call_unmuted_by_host'.tr(args: [senderName]),
          type: muted ? ToastType.warning : ToastType.info,
        );
  }

  Future<void> _onKickCommand(Map<String, dynamic> payload) async {
    final targetUid = payload['uid'] as String?;
    final senderName = payload['senderName'] as String? ?? 'call_host'.tr();
    final current = _currentState;
    if (current == null) return;

    final localIdentity = current.room.localParticipant?.identity;
    if (targetUid != localIdentity) return;

    await _handleRemovedFromCall(senderName);
  }

  Future<void> _handleRemovedFromCall(String senderName) async {
    if (_removedFromCallHandled) return;
    _removedFromCallHandled = true;

    ref
        .read(toastServiceProvider)
        .showNotificationNow(
          'call_removed_by_host'.tr(args: [senderName]),
          type: ToastType.warning,
          duration: const Duration(seconds: 2),
        );

    if (DeviceUtil.isRealMobile() || DeviceUtil.isWeb) {
      ref.read(mobileCallSessionControllerProvider.notifier).end();
      await leave();
      return;
    }

    // 桌面统一交给窗口先卸载通话 UI，再等待 leave。
    await windowManager.close();
  }

  /// 绑定设备热插拔监听
  /// 当用户插拔耳机、摄像头等设备时自动刷新设备列表
  void _bindDeviceEvents() {
    _deviceSub = Hardware.instance.onDeviceChange.stream.listen((_) {
      unawaited(
        _runMediaOperation(_loadDeviceList).catchError(
          (Object e, StackTrace st) => debugLog('刷新媒体设备列表失败', e, st),
        ),
      );
    });
    // 订阅在 _disposeResources() 中统一取消（由 leave()/onDispose 调用）
  }

  /// 刷新设备列表
  Future<void> _loadDeviceList() async {
    final currentState = _currentState;
    if (currentState == null) return;
    final devices = await _getInitialDevices();
    // leave() 会等待生命周期内的设备枚举结束；退出期间不再回写旧状态。
    if (_isLeaving || !ref.mounted) return;
    _updateState(
      (latest) => latest.copyWith(
        audioInputs: devices.where((d) => d.kind == 'audioinput').toList(),
        audioOutputs: devices.where((d) => d.kind == 'audiooutput').toList(),
        videoInputs: devices.where((d) => d.kind == 'videoinput').toList(),
        currentAudioInput: Hardware.instance.selectedAudioInput,
        currentAudioOutput: Hardware.instance.selectedAudioOutput,
        currentVideoInput: Hardware.instance.selectedVideoInput,
      ),
    );
  }

  /// 手动刷新设备列表
  ///
  /// 打开设备选择菜单前调用，确保 Web 端获取到授权后的完整设备列表
  Future<void> refreshDevices() => _runMediaOperation(_loadDeviceList);

  /// 清理资源
  /// 释放 listener 和设备订阅等本地资源，不访问 provider state。
  /// 幂等操作，可安全重复调用。
  Future<void> _disposeResources() async {
    _recoveryTimer?.cancel();
    _recoveryTimer = null;
    _peerGoneTimer?.cancel();
    _peerGoneTimer = null;
    final listener = _listener;
    _listener = null;
    final deviceSub = _deviceSub;
    _deviceSub = null;
    try {
      await _screenSession?.stop();
    } catch (error, stack) {
      debugLog('释放共享失败，继续由房间释放全部轨道', error, stack);
    }
    _screenSession = null;
    await listener?.dispose();
    await deviceSub?.cancel();
  }

  // ================= 公开功能 API =================

  Future<void> _runMediaOperation(
    Future<void> Function() operation, {
    CallMediaLane? lane,
  }) async {
    final lifecycle = _mediaLifecycle;
    if (lifecycle == null || lifecycle.isClosing || _isLeaving) return;
    await lifecycle.run(() async {
      if (lane == null) {
        await operation();
      } else {
        final queue = _mediaQueues.putIfAbsent(
          lane,
          CallMediaOperationQueue.new,
        );
        await queue.run(() async {
          if (lifecycle.isClosing || _isLeaving) return;
          await operation();
        });
      }
    });
  }

  /// 异步操作只合并到最新状态，退出期间不允许再回写。
  void _updateState(RoomState Function(RoomState) update) {
    if (!ref.mounted || _isLeaving || _mediaLifecycle?.isClosing == true) {
      return;
    }
    final latest = _currentState;
    if (latest != null) state = AsyncData(update(latest));
  }

  /// 切换麦克风开关
  /// 使用独立防抖锁 _isTogglingMic，避免快速连点
  Future<void> toggleMic() =>
      _currentState?.isReconnecting == true || _recoveringConnection
      ? Future<void>.value()
      : _runMediaOperation(_toggleMic, lane: CallMediaLane.microphone);

  Future<void> _toggleMic() async {
    if (_isTogglingMic) return;
    _isTogglingMic = true;
    try {
      final currentState = _currentState;
      if (currentState == null) return;
      final next = !currentState.micEnabled;
      if (next && DeviceUtil.isRealMobile()) {
        final permission = await appPermissionService.request(
          Permission.microphone,
        );
        if (permission != AppPermissionResult.granted) {
          ref
              .read(toastServiceProvider)
              .showNotificationNow(
                'call_mic_permission_required'.tr(),
                type: ToastType.warning,
              );
          return;
        }
      }
      await currentState.room.localParticipant?.setMicrophoneEnabled(next);
      _updateState((latest) => latest.copyWith(micEnabled: next));
    } catch (e) {
      debugLog('切换麦克风失败: $e');
    } finally {
      _isTogglingMic = false;
    }
  }

  /// 切换摄像头开关
  /// 使用独立防抖锁 _isTogglingCamera，避免快速连点
  Future<void> toggleCamera() =>
      _currentState?.isReconnecting == true || _recoveringConnection
      ? Future<void>.value()
      : _runMediaOperation(_toggleCamera, lane: CallMediaLane.camera);

  Future<void> _toggleCamera() async {
    if (_isTogglingCamera) return;
    _isTogglingCamera = true;
    try {
      final currentState = _currentState;
      if (currentState == null) return;
      final next = !currentState.cameraEnabled;
      if (next && DeviceUtil.isRealMobile()) {
        final permission = await appPermissionService.request(
          Permission.camera,
        );
        if (permission != AppPermissionResult.granted) {
          ref
              .read(toastServiceProvider)
              .showNotificationNow(
                'call_camera_permission_required'.tr(),
                type: ToastType.warning,
              );
          return;
        }
      }
      if (_applyingPreferences) return;
      await _setCameraEnabled(currentState.room, next);
      _updateState((latest) => latest.copyWith(cameraEnabled: next));
    } catch (e) {
      debugLog('切换摄像头失败: $e');
    } finally {
      _isTogglingCamera = false;
    }
  }

  /// 移动端快速切换前置/后置摄像头。
  Future<void> switchCamera() =>
      _runMediaOperation(_switchCamera, lane: CallMediaLane.camera);

  Future<void> _switchCamera() async {
    final currentState = _currentState;
    if (currentState == null || !currentState.cameraEnabled) return;
    try {
      final publication = currentState
          .room
          .localParticipant
          ?.videoTrackPublications
          .where((item) => !item.isScreenShare)
          .firstOrNull;
      final track = publication?.track;
      if (track is! LocalVideoTrack) return;
      final options = track.currentOptions;
      if (options is! CameraCaptureOptions) return;
      await track.setCameraPosition(options.cameraPosition.switched());
      _updateState((latest) => latest.copyWith());
    } catch (e) {
      debugLog('切换前后摄像头失败: $e');
    }
  }

  /// 开始屏幕共享
  ///
  /// 精细化管理轨道：单独发布屏幕共享轨道，不影响摄像头轨道。
  /// - 桌面端必须由 UI 层传入用户选中的屏幕源 [sourceId]；
  ///   未传（用户在系统弹窗里取消）时直接终止，不做任何副作用。
  /// - 移动端/Web 传空，由系统选择器接管。
  ///
  /// 已有活跃共享轨道时是空操作——切换到别的屏幕源请先 [stopScreenShare]，
  /// 避免同一房间出现两条屏幕共享轨道。
  Future<void> startScreenShare({String? sourceId}) => _runMediaOperation(
    () => _startScreenShare(sourceId: sourceId),
    lane: CallMediaLane.screen,
  );

  Future<void> _startScreenShare({String? sourceId}) async {
    final currentState = _currentState;
    if (currentState == null) return;
    // 已有活跃的共享轨道：不重复发布（防止双轨道 / 状态错乱）。
    // 注意这里看"轨道"而不是 state.screenSharing——后者可能因事件丢失而虚高，
    // 用状态字段判断会导致用户点了开始共享却毫无反应。
    if (_hasActiveScreenShare(currentState)) return;
    // 桌面端未提供屏幕源：用户取消了选择，直接终止
    if (DeviceUtil.isRealDesktop() && sourceId == null) return;
    if (_isTogglingScreen) return;

    _isTogglingScreen = true;
    try {
      final localParticipant = currentState.room.localParticipant;
      if (localParticipant == null) return;

      // 防御：清理可能残留的屏幕共享发布（例如系统侧已回收轨道、
      // 但 publication 尚未同步移除），避免同一房间出现两条共享轨道
      await _removeScreenSharePublications(localParticipant);

      /// Android 14+ 安全检查：如果用户拒绝或激活失败，直接阻断不往下走
      if (DeviceUtil.isAndroid()) {
        final isReady = await _safeActivateAndroidBackground();
        if (!isReady) return;
      }

      _mediaLifecycle?.ensureOpen();
      final session = CallScreenShare(localParticipant);
      _screenSession = session;
      final codec = selectVideoCodec(
        _preferences.screenCodec,
        _supportedVideoCodecs,
      );
      await session.start(
        _preferences
            .screenCaptureOptions(sourceId: sourceId)
            .copyWith(
              captureScreenAudio: DeviceUtil.isWeb && _preferences.shareAudio,
            ),
        _preferences.screenPublishOptions(codec),
        ensureOpen: () => _mediaLifecycle?.ensureOpen(),
      );
      _updateState(
        (latest) => latest.copyWith(
          screenSharing: true,
          screenShareTrack: session.video,
        ),
      );
      if (DeviceUtil.isWeb && _preferences.shareAudio && !session.hasAudio) {
        _notifyMediaFailure('call_share_audio_unavailable');
      }
      if (DeviceUtil.isIOS()) _notifyMediaFailure('call_share_ios_in_app');
    } catch (e) {
      debugLog('开始屏幕共享失败: $e');
      // 发布失败时轨道可能已创建但无人持有，必须显式停掉，
      // 否则底层屏幕采集会一直挂在后台
      // 兜底：把半成功的发布也一并撤销，避免留下僵尸轨道
      try {
        await _removeScreenSharePublications(
          currentState.room.localParticipant,
        );
      } catch (error, stack) {
        debugLog('共享失败清理异常', error, stack);
      } finally {
        await _releaseScreenShareKeepAlive();
        _updateParticipants();
        _notifyMediaFailure('call_share_failed');
      }
    } finally {
      _isTogglingScreen = false;
    }
  }

  /// 停止屏幕共享
  ///
  /// 幂等：即使当前状态已经是"未共享"，重复调用也不会报错。
  /// 会撤销本地全部屏幕共享发布（不止第一条），并归还 Android 前台保活服务。
  Future<void> stopScreenShare() =>
      _runMediaOperation(_stopScreenShare, lane: CallMediaLane.screen);

  Future<void> _stopScreenShare() async {
    if (_isTogglingScreen) return;
    _isTogglingScreen = true;
    try {
      final currentState = _currentState;
      if (currentState == null) return;
      await _removeScreenSharePublications(currentState.room.localParticipant);
      await _releaseScreenShareKeepAlive();

      /// 优化：无论是否找到轨道，都要把状态归零——
      /// 轨道可能已被系统（如 Windows 的"停止共享"按钮）抢先回收。
      _clearScreenShareState();
    } catch (e) {
      debugLog('停止屏幕共享失败: $e');
      _updateParticipants();
      _notifyMediaFailure('call_share_stop_failed');
    } finally {
      _isTogglingScreen = false;
    }
  }

  Future<void> replaceScreenShare({String? sourceId}) =>
      _runMediaOperation(() async {
        await _stopScreenShare();
        _mediaLifecycle?.ensureOpen();
        await _startScreenShare(sourceId: sourceId);
      }, lane: CallMediaLane.screen);

  /// 切换屏幕共享（移动端/Web 等无屏幕源选择场景的统一入口）
  ///
  /// 桌面端 UI 请直接调用 [startScreenShare] / [stopScreenShare]，
  /// 以便在"停止共享"时绕过屏幕源选择框。
  Future<void> toggleScreenShare({String? sourceId}) async {
    final currentState = _currentState;
    if (currentState == null) return;
    if (_hasActiveScreenShare(currentState)) {
      await stopScreenShare();
    } else {
      await startScreenShare(sourceId: sourceId);
    }
  }

  /// 本地是否真的存在活跃的屏幕共享发布（以轨道为准，而非状态字段）
  ///
  /// [RoomState.screenSharing] 由事件驱动更新，存在滞后/丢失的可能；
  /// 开关方向、重复发布防护一律以实际轨道为准。
  bool _hasActiveScreenShare(RoomState current) {
    final localParticipant = current.room.localParticipant;
    if (localParticipant == null) return false;
    return localParticipant.videoTrackPublications.any(
      (p) => p.isScreenShare && !p.muted,
    );
  }

  /// 撤销本地全部屏幕共享轨道
  ///
  /// `removePublishedTrack` 默认会顺带 `stop()` 底层轨道，释放采集设备。
  Future<void> _removeScreenSharePublications(
    LocalParticipant? participant,
  ) async {
    if (participant == null) return;
    final session = _screenSession ?? CallScreenShare(participant);
    _screenSession = null;
    try {
      await session.stop();
    } finally {
      await _releaseScreenShareKeepAlive();
    }
  }

  void _notifyMediaFailure(String key) {
    if (!ref.mounted || _isLeaving) return;
    ref
        .read(toastServiceProvider)
        .showNotificationNow(key.tr(), type: ToastType.warning);
  }

  /// 关闭共享时及时释放 Android 前台保活服务
  Future<void> _releaseScreenShareKeepAlive() async {
    if (!DeviceUtil.isAndroid()) return;
    try {
      if (rtc.FlutterBackground.isBackgroundExecutionEnabled) {
        await rtc.FlutterBackground.disableBackgroundExecution();
      }
    } catch (e) {
      debugLog('关闭 Android 后台服务失败: $e');
    }
  }

  /// 把屏幕共享相关状态归零（不改动轨道，纯状态收敛）
  void _clearScreenShareState() {
    final current = _currentState;
    if (current == null) return;
    if (!current.screenSharing && current.screenShareTrack == null) return;
    state = AsyncData(
      current.copyWith(screenSharing: false, clearScreenShareTrack: true),
    );
  }

  /// 安全激活 Android 14+ 的媒体投影前台服务
  /// 修改返回值：true 表示成功获取授权并激活，false 表示用户拒绝或失败
  Future<bool> _safeActivateAndroidBackground() async {
    try {
      // 1. 先初始化
      final androidConfig = rtc.FlutterBackgroundAndroidConfig(
        notificationTitle: 'call_in_progress'.tr(),
        notificationText: 'call_screen_share_background'.tr(),
        notificationImportance: rtc.AndroidNotificationImportance.normal,
        notificationIcon: const rtc.AndroidResource(
          name: 'ic_launcher',
          defType: 'mipmap',
        ),
      );

      final hasPermissions = await rtc.FlutterBackground.initialize(
        androidConfig: androidConfig,
      );
      if (!hasPermissions) {
        debugLog('flutter_background 权限不足');
        return false;
      }

      // 2. 启动前台服务（弹出电池优化对话框）
      if (!rtc.FlutterBackground.isBackgroundExecutionEnabled) {
        await rtc.FlutterBackground.enableBackgroundExecution();
      }

      // 3. 验证前台服务真的跑起来了
      if (!rtc.FlutterBackground.isBackgroundExecutionEnabled) {
        debugLog('用户拒绝了后台运行权限');
        return false;
      }

      // 4. 前台服务就绪后，再申请投屏权限
      final hasCapturePermission = await rtc.Helper.requestCapturePermission();
      if (!hasCapturePermission) {
        debugLog('用户拒绝了录屏权限');
        // 申请失败，关掉已启动的前台服务
        await rtc.FlutterBackground.disableBackgroundExecution();
        return false;
      }

      return true;
    } catch (e) {
      debugLog('Android 媒体投影前台服务激活失败: $e');
      return false;
    }
  }

  /// 切换扬声器/听筒（主要用于移动端）
  Future<void> toggleSpeaker() =>
      _runMediaOperation(_toggleSpeaker, lane: CallMediaLane.output);

  Future<void> _toggleSpeaker() async {
    final currentState = _currentState;
    if (currentState == null) return;
    try {
      final next = !currentState.speakerOn;
      await AudioManager.instance.setSpeakerOutputPreferred(next);
      _updateState((latest) => latest.copyWith(speakerOn: next));
    } catch (e) {
      debugLog('切换扬声器失败: $e');
    }
  }

  /// 切换音频输入设备（麦克风）
  /// 切换后重启音频轨道使新设备生效
  Future<void> switchAudioInput(MediaDevice device) => _runMediaOperation(
    () => _switchAudioInput(device),
    lane: CallMediaLane.microphone,
  );

  Future<void> _switchAudioInput(MediaDevice device) async {
    final currentState = _currentState;
    if (currentState == null) return;
    try {
      // Web 端 Hardware.selectAudioInput 不支持，
      // room.setAudioInputDevice 内部会按平台分发（Web 走 track.setDeviceId 并重启轨道）
      await currentState.room.setAudioInputDevice(device);
      // 原生端切换后手动重启轨道使新设备立即生效
      if (!DeviceUtil.isWeb) {
        final localParticipant = currentState.room.localParticipant;
        if (localParticipant != null &&
            localParticipant.audioTrackPublications.isNotEmpty) {
          final audioTrack =
              localParticipant.audioTrackPublications.first.track
                  as LocalAudioTrack;
          await audioTrack.restartTrack();
        }
      }
      _updateState((latest) => latest.copyWith(currentAudioInput: device));
    } catch (e) {
      debugLog('切换麦克风失败: $e');
    }
  }

  /// 切换视频输入设备（摄像头）
  Future<void> switchVideoInput(MediaDevice device) => _runMediaOperation(
    () => _switchVideoInput(device),
    lane: CallMediaLane.camera,
  );

  Future<void> _switchVideoInput(MediaDevice device) async {
    final currentState = _currentState;
    if (currentState == null) return;
    try {
      await currentState.room.setVideoInputDevice(device);
      _updateState((latest) => latest.copyWith(currentVideoInput: device));
    } catch (e) {
      debugLog('切换摄像头失败: $e');
    }
  }

  /// 切换音频输出设备（扬声器/耳机）
  Future<void> switchAudioOutput(MediaDevice device) => _runMediaOperation(
    () => _switchAudioOutput(device),
    lane: CallMediaLane.output,
  );

  Future<void> _switchAudioOutput(MediaDevice device) async {
    final currentState = _currentState;
    if (currentState == null) return;
    try {
      await Hardware.instance.selectAudioOutput(device);
      _updateState((latest) => latest.copyWith(currentAudioOutput: device));
    } catch (e) {
      debugLog('切换扬声器失败: $e');
    }
  }

  /// 离开房间（幂等，可被多处并发 await）
  ///
  /// 执行顺序：
  ///   1. 标记 _isLeaving 防止重入
  ///   2. 先释放 listener 和设备订阅，避免 disconnect 触发事件回调
  ///   3. 等待建连和设备操作结束，再 disconnect 房间
  ///   4. dispose 房间
  ///   5. 标记 token 阻止 invalidateSelf 重建时重新连接
  ///   6. invalidateSelf 触发 onDispose 兜底清理
  ///
  /// 首次调用真正执行断开；后续并发调用直接复用同一个 Future，因此
  /// 「挂断 → 关窗」这类路径可以 await 到媒体真正释放，而不是拿到一个
  /// 立即返回的空操作（那样会在断连尚未完成时就把窗口/引擎销毁掉）。
  Future<void> leave() {
    final pending = _leaveFuture;
    if (pending != null) return pending;
    _isLeaving = true;
    return _leaveFuture = _leave();
  }

  Future<void> _leave() async {
    // 无论是否成功连接过，都要先把 token 标记为已处理：
    // 连接失败（错误态）时 _currentState 为 null，若只标记成功路径，
    // 此时 leave() 后的 invalidateSelf 会重建并再次尝试连接。
    _disposedTokens.add(token);
    // Room 在 build 开始时已被生命周期对象持有，loading / error 也能等待清理。
    await _mediaLifecycle?.close();
    if (ref.mounted) ref.invalidateSelf();
  }

  /// 手动重连
  /// 通常不需要手动调用，SDK 会自动重连
  /// 仅在 SDK 放弃重连后（RoomDisconnectedEvent）才需要手动触发
  Future<void> reconnect() => _runMediaOperation(_reconnect);

  Future<void> _reconnect() async {
    final currentState = _currentState;
    if (currentState == null) return;
    await _connectRoom(currentState.room, currentState.token);
    _mediaLifecycle?.ensureOpen();
    // 完全断开后 SDK 已清理发布；恢复断线前的开关，不能把静音用户重新开麦。
    await _runMediaOperation(() async {
      final latest = _currentState;
      if (latest == null) return;
      await latest.room.localParticipant?.setMicrophoneEnabled(
        latest.micEnabled,
      );
    }, lane: CallMediaLane.microphone);
    _mediaLifecycle?.ensureOpen();
    await _runMediaOperation(() async {
      final latest = _currentState;
      if (latest == null) return;
      await _setCameraEnabled(latest.room, latest.cameraEnabled);
    }, lane: CallMediaLane.camera);
    _mediaLifecycle?.ensureOpen();
    if (currentState.room.connectionState != ConnectionState.connected) {
      throw StateError('恢复媒体期间连接已断开');
    }
    _updateParticipants();
    _updateState(
      (latest) => latest.copyWith(
        connectionState: ConnectionState.connected,
        isReconnecting: false,
        clearConnectionError: true,
      ),
    );
  }

  /// SDK 已耗尽自动重连后再做有限恢复；终止类原因不会重新加入。
  void _scheduleConnectionRecovery(DisconnectReason? reason) {
    _recoveryTimer?.cancel();
    final delay = _recoveryPolicy.nextDelay(reason, now: DateTime.now());
    if (delay == null || _currentState == null) return;
    _updateState((current) => current.copyWith(isReconnecting: true));
    _recoveryTimer = Timer(delay, () async {
      if (_currentState == null) return;
      _recoveringConnection = true;
      try {
        await reconnect();
      } catch (error, stack) {
        debugLog('通话有限恢复失败', error, stack);
        _updateState(
          (current) => current.copyWith(
            connectionState: ConnectionState.disconnected,
            isReconnecting: false,
            connectionError: reason?.name ?? 'unknown',
          ),
        );
        _scheduleConnectionRecovery(_lastDisconnectReason);
      } finally {
        _recoveringConnection = false;
      }
    });
  }

  // ================= 自定义数据通道 API =================

  /// 底层数据发送方法
  /// [topic] 消息类型标识，接收方通过 topic 区分消息类别
  /// [payload] 业务数据，会被包装成 {payload, timestamp} 格式
  ///
  /// 注意：publishData 不会回传给发送方自己，
  /// 需要本地状态更新的操作必须在调用此方法前先更新 state
  Future<bool> sendDataEvent({
    required String topic,
    Map<String, dynamic> payload = const {},
    List<String>? destinationIdentities,
  }) async {
    final currentState = _currentState;
    final local = currentState?.room.localParticipant;
    if (currentState == null || local == null) return false;
    try {
      final data = jsonEncode({
        'payload': payload,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      await local.publishData(
        utf8.encode(data),
        reliable: true,
        destinationIdentities: destinationIdentities,
        topic: topic,
      );
      return true;
    } catch (e) {
      debugLog('发送数据事件失败: $e');
      return false;
    }
  }

  /// 举手 / 放手
  /// [raised] true=举手，false=放手
  ///
  /// 因为 publishData 不回传给自己，所以：
  ///   1. 先更新本地 handRaiseMap
  ///   2. 再广播给房间内其他人
  Future<void> sendHandRaise(bool raised) async {
    final current = _currentState;
    if (current == null) return;
    final uid = current.room.localParticipant?.identity ?? '';
    if (uid.isEmpty) return;

    final meta = _parseParticipantMeta(current.room.localParticipant);

    // 先更新本地状态
    final map = Map<String, bool>.from(current.handRaiseMap ?? {});
    if (raised) {
      map[uid] = true;
    } else {
      map.remove(uid);
    }
    state = AsyncData(current.copyWith(handRaiseMap: map));

    // 广播给其他人（携带用户名）
    await sendDataEvent(
      topic: 'app-hand-raise',
      payload: {'raised': raised, 'uid': uid, 'name': meta.name},
    );
  }

  /// 发送表情 / 弹幕
  /// [message] 表情符号（如 '👍'）或弹幕文字
  ///
  /// 因为 publishData 不回传给自己，所以：
  ///   1. 先在本地添加 ReactionItem
  ///   2. 3 秒后按唯一 id 精确删除（避免同表情互相误删）
  ///   3. 再广播给房间内其他人
  Future<void> sendReaction(String message) async {
    final current = _currentState;
    final connected =
        current != null &&
        current.connectionState == ConnectionState.connected &&
        current.room.localParticipant != null;
    if (!connected || (current.room.localParticipant?.identity ?? '').isEmpty) {
      _notifyReactionFailed();
      return;
    }
    final uid = current.room.localParticipant!.identity;

    final meta = _parseParticipantMeta(current.room.localParticipant);
    final item = ReactionItem(
      message: message,
      uid: uid,
      name: meta.name,
      avatar: meta.avatar,
      createdAt: DateTime.now(),
    );

    final list = List<ReactionItem>.from(current.reactions ?? [])..add(item);
    state = AsyncData(current.copyWith(reactions: list));

    // 3 秒后自动移除该 ReactionItem
    _scheduleReactionRemoval(item.id);

    // 广播给其他人
    final sent = await sendDataEvent(
      topic: 'app-chat',
      payload: {
        'message': message,
        'uid': uid,
        'name': meta.name,
        'avatar': meta.avatar,
      },
    );
    if (!sent) {
      // 发送失败：立即移除本端刚乐观添加的 ReactionItem，避免残留 3 秒
      final afterFail = _currentState;
      if (afterFail != null) {
        final list = List<ReactionItem>.from(afterFail.reactions ?? [])
          ..removeWhere((r) => r.id == item.id);
        state = AsyncData(afterFail.copyWith(reactions: list));
      }
      _notifyReactionFailed();
    }
  }

  /// 表情/弹幕发送失败（房间未连接或数据通道异常）时的用户提示。
  void _notifyReactionFailed() {
    ref
        .read(toastServiceProvider)
        .showNotificationNow(
          'call_reaction_failed'.tr(),
          type: ToastType.warning,
        );
  }

  /// 定时移除 ReactionItem
  ///
  /// [itemId] ReactionItem 的唯一标识
  /// 3 秒后自动从 reactions 列表中移除对应项
  void _scheduleReactionRemoval(String itemId) {
    Timer(const Duration(seconds: 3), () {
      final current = _currentState;
      if (current == null) return;
      final list = List<ReactionItem>.from(current.reactions ?? [])
        ..removeWhere((r) => r.id == itemId);
      state = AsyncData(current.copyWith(reactions: list));
    });
  }

  /// 主持人静音指令
  /// [targetUid] 要被静音的参与者 identity（不是自己）
  /// [muted] true=静音，false=取消静音
  ///
  /// 接收方收到后会检查 targetUid 是否是自己，是则执行静音
  Future<void> sendMuteCommand(String targetUid, bool muted) {
    final current = _currentState;
    final meta = _parseParticipantMeta(current?.room.localParticipant);
    return sendDataEvent(
      topic: 'app-mute-command',
      payload: {'uid': targetUid, 'muted': muted, 'senderName': meta.name},
    );
  }

  Future<void> sendKickCommand(String targetUid) {
    final current = _currentState;
    final meta = _parseParticipantMeta(current?.room.localParticipant);
    return sendDataEvent(
      topic: 'app-kick-command',
      destinationIdentities: [targetUid],
      payload: {'uid': targetUid, 'senderName': meta.name},
    );
  }

  /// 踢出参与者（从通话房间移除）
  /// [identity] LiveKit 参与者 identity
  /// 对应后端接口 GET /call/participant/remove?roomId=&identity=
  Future<bool> kickParticipant(String identity) async {
    final current = _currentState;
    if (current == null) return false;
    try {
      final roomId = current.room.name;
      if (roomId == null || roomId.isEmpty) {
        debugLog('踢出失败: roomId 为空');
        return false;
      }
      await sendKickCommand(identity);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      final ok = await ref
          .read(callRepositoryProvider)
          .removeParticipant(roomId, identity);
      if (ok) {
        ref
            .read(toastServiceProvider)
            .showNotificationNow(
              'call_user_removed'.tr(),
              type: ToastType.success,
            );
        return true;
      } else {
        final msg = 'call_unknown_error'.tr();
        ref
            .read(toastServiceProvider)
            .showNotificationNow(
              'call_kick_error'.tr(args: [msg]),
              type: ToastType.error,
            );
        debugLog('踢出参与者 $identity 失败: $msg');
        return false;
      }
    } catch (e) {
      debugLog('踢出参与者失败: $e');
      ref
          .read(toastServiceProvider)
          .showNotificationNow('call_kick_retry'.tr(), type: ToastType.error);
      return false;
    }
  }

  /// 从参与者 metadata JSON 解析 name 和 avatar
  /// metadata 格式: {"name": "Alice", "avatar": "https://..."}
  ({String name, String? avatar}) _parseParticipantMeta(Participant? p) {
    if (p == null) return (name: '', avatar: null);
    try {
      final meta = jsonDecode(p.metadata ?? '{}') as Map<String, dynamic>;
      return (
        name: meta['nickName'] as String? ?? p.identity,
        avatar: meta['avatar'] as String?,
      );
    } catch (_) {
      return (name: p.identity, avatar: null);
    }
  }
}

// ================= roomToken Provider =================

/// 从服务端获取加入房间的 JWT Token
/// [roomId] 房间 ID
@riverpod
Future<String> roomToken(Ref ref, String roomId) async {
  try {
    final token = await ref.read(callRepositoryProvider).fetchCallToken(roomId);
    return token;
  } catch (e) {
    debugLog('获取房间 Token 失败: $e');
    rethrow;
  }
}
