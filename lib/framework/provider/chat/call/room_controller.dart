import 'dart:async';
import 'dart:convert';

import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:anoxia/features/chat/presentation/call/component/window_screen_select_dialog.dart';

import '../../../domain/RoomState.dart';
import '../../../network/DioClient.dart';

part 'room_controller.g.dart';

/// 房间控制器
/// 负责管理 LiveKit 房间的完整生命周期：
///   - 连接 / 断开 / 重连
///   - 本地媒体（麦克风、摄像头、屏幕共享）
///   - 设备切换
///   - 自定义数据通道（举手、表情、弹幕、主持人静音指令）
@Riverpod(keepAlive: true)
class RoomController extends _$RoomController {
  /// LiveKit 事件监听器，负责监听房间内所有事件
  EventsListener<RoomEvent>? _listener;

  /// 各操作的独立防抖锁，防止用户快速连续点击导致状态错乱
  bool _isTogglingMic = false;
  bool _isTogglingCamera = false;
  bool _isTogglingScreen = false;

  // ================= Riverpod build =================

  /// Provider 入口
  /// [token] 是加入房间用的 JWT Token，由服务端下发
  ///
  /// 执行顺序：
  ///   1. 创建 Room 实例
  ///   2. 注册 dispose 回调（最高优先级，确保资源一定被释放）
  ///   3. 连接房间
  ///   4. 绑定事件监听
  ///   5. 初始化设备列表 & 本地轨道
  ///   6. 返回初始 RoomState
  @override
  Future<RoomState> build(String token) async {
    final room = Room(
      roomOptions: const RoomOptions(
        adaptiveStream: true, // 自适应流：根据网络自动降码率
        dynacast: true, // 动态广播：只向订阅者发流，节省带宽
      ),
    );

    // 注册销毁回调（Provider 被销毁时自动执行）
    // 注意：onDispose 中不能访问 provider state，否则会触发 Riverpod 断言
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
      // 连接房间（串行：先预连接降低延迟，再正式连接）
      await _connectRoom(room, token);

      // 创建事件监听器并保存引用（用于 dispose）
      // 注意：用局部变量接收，避免 _listener 可空导致的 null check 问题
      final listener = room.createListener();
      _listener = listener;

      listener
        // ============ 房间级别事件 ============
        /// 房间连接成功
        /// 通常在 build 中 connect 之后就会触发，这里主要用于清除之前的错误状态
        ..on<RoomConnectedEvent>((event) {
          log.info("✓ 房间已连接: ${event.room.name}");
          final current = state.value;
          if (current != null && current.connectionError != null) {
            state = AsyncData(current.copyWith(connectionError: null));
          }
        })
        /// 房间断开连接
        /// SDK 会在网络中断或主动 disconnect 后触发
        /// 重连逻辑由 SDK 自动处理，不需要手动干预
        ..on<RoomDisconnectedEvent>((event) {
          log.info("✗ 房间已断开");
        })
        /// 房间正在重连中（网络抖动时触发）
        /// 更新 isReconnecting 状态，UI 层展示重连遮罩
        ..on<RoomReconnectingEvent>((event) {
          log.warning("🔄 房间正在重新连接...");
          final current = state.value;
          if (current != null) {
            state = AsyncData(current.copyWith(isReconnecting: true));
          }
        })
        /// 房间重连成功
        /// 清除重连状态和错误信息
        ..on<RoomReconnectedEvent>((event) {
          log.info("✅ 房间已重新连接");
          final current = state.value;
          if (current != null) {
            state = AsyncData(
              current.copyWith(isReconnecting: false, connectionError: null),
            );
          }
        })
        /// 房间元数据变化（服务端通过 Server API 更新的房间信息）
        ..on<RoomMetadataChangedEvent>((event) {
          log.info("📝 房间元数据变化: ${event.metadata}");
          final current = state.value;
          if (current != null) {
            state = AsyncData(current.copyWith(roomMetadata: event.metadata));
          }
        })
        /// 录制状态变化（服务端开启/停止录制时触发）
        ..on<RoomRecordingStatusChanged>((event) {
          log.info("📹 录制状态变化: ${event.activeRecording}");
          final current = state.value;
          if (current != null) {
            state = AsyncData(
              current.copyWith(isRecording: event.activeRecording),
            );
          }
        })
        // ============ 参与者事件 ============
        /// 新参与者加入房间
        ..on<ParticipantConnectedEvent>((e) {
          log.info("➕ 参与者加入: ${e.participant.identity}");
          _updateParticipants();
        })
        /// 参与者离开房间
        ..on<ParticipantDisconnectedEvent>((e) {
          log.info("➖ 参与者离开: ${e.participant.identity}");
          _updateParticipants();
        })
        /// 活跃发言者变化（SDK 根据音量实时检测）
        /// 将第一个发言者设为焦点，UI 层可以据此高亮或置顶
        ..on<ActiveSpeakersChangedEvent>((e) {
          log.info("🔊 活跃发言者变化 (${e.speakers.length} 人)");
          final current = state.value;
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
        // ============ Track（媒体轨道）事件 ============
        // 以下事件都需要刷新参与者列表，确保 UI 中摄像头/静音状态实时更新
        // 不监听这些事件的话，别人开关摄像头/静音你这边 UI 不会更新
        /// 远端参与者发布了新轨道（如开启摄像头）
        ..on<TrackPublishedEvent>((e) {
          log.info(
            "📡 远端轨道发布: ${e.participant.identity} - ${e.publication.sid}",
          );
          _updateParticipants();
        })
        /// 远端参与者撤销了轨道（如关闭摄像头）
        ..on<TrackUnpublishedEvent>((e) {
          log.info(
            "📡 远端轨道撤销: ${e.participant.identity} - ${e.publication.sid}",
          );
          _updateParticipants();
        })
        /// 本地轨道发布成功（自己开启摄像头/麦克风后触发）
        ..on<LocalTrackPublishedEvent>((e) {
          log.info("📡 本地轨道发布: ${e.publication.sid}");
          _updateParticipants();
        })
        /// 本地轨道撤销（自己关闭摄像头/麦克风后触发）
        ..on<LocalTrackUnpublishedEvent>((e) {
          log.info("📡 本地轨道撤销: ${e.publication.sid}");
          _updateParticipants();
        })
        /// 轨道被静音（任意参与者）
        ..on<TrackMutedEvent>((e) {
          log.info(
            "🔇 轨道已静音: ${e.participant.identity} - ${e.publication.sid}",
          );
          _updateParticipants();
        })
        /// 轨道取消静音（任意参与者）
        ..on<TrackUnmutedEvent>((e) {
          log.info(
            "🔈 轨道已取消静音: ${e.participant.identity} - ${e.publication.sid}",
          );
          _updateParticipants();
        })
        // ============ 自定义数据通道 ============
        /// 收到房间内任意参与者发送的自定义数据
        /// 注意：LiveKit publishData 不会回传给发送方自己，
        /// 所以发送方需要在发送时直接更新本地状态
        ..on<DataReceivedEvent>((e) {
          _handleDataEvent(e);
        });

      // 绑定设备热插拔监听（耳机插拔、摄像头连接等）
      _bindDeviceEvents();

      // 获取初始设备列表
      final devices = await _getInitialDevices();

      // 初始化本地轨道（默认关闭麦克风和摄像头，由用户手动开启）
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
        handRaiseMap: {},
        reactions: [],
      );
    } catch (e) {
      log.error("房间初始化失败: $e");
      await room.dispose();
      rethrow;
    }
  }

  // ================= 核心私有方法 =================

  /// 连接房间
  /// 串行执行：先 prepareConnection 预热 TCP 连接，再正式 connect
  /// 设置 10 秒超时，超时抛出 TimeoutException
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

  /// 枚举系统可用媒体设备
  Future<List<MediaDevice>> _getInitialDevices() async {
    try {
      return await Hardware.instance.enumerateDevices();
    } catch (e) {
      log.error("获取设备列表失败: $e");
      return [];
    }
  }

  /// 初始化本地轨道
  /// 默认关闭麦克风和摄像头，避免进入房间就开播
  Future<void> _initLocalTracks(Room room) async {
    final localParticipant = room.localParticipant;
    if (localParticipant == null) return;
    try {
      localParticipant.setCameraEnabled(false);
      localParticipant.setMicrophoneEnabled(false);
      log.info(
        "本地轨道初始化 → mic: ${localParticipant.isMicrophoneEnabled()}, "
        "video: ${localParticipant.isCameraEnabled()}",
      );
    } catch (e) {
      log.error("初始化本地硬件失败，可能设备被占用或无权限: $e");
    }
  }

  /// 刷新远端参与者列表
  /// 在任何参与者/轨道变化事件中调用，确保 UI 同步最新状态
  void _updateParticipants() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        remoteParticipants: current.room.remoteParticipants.values.toList(),
      ),
    );
  }

  /// 处理自定义数据通道事件
  /// LiveKit 的 publishData 不会回传给发送方，
  /// 所以这里只处理其他人发来的消息
  void _handleDataEvent(DataReceivedEvent e) {
    try {
      final json = jsonDecode(utf8.decode(e.data)) as Map<String, dynamic>;
      // payload 是业务数据，timestamp 是发送时间戳（可用于排序或去重）
      final payload = json['payload'] as Map<String, dynamic>? ?? {};
      log.info("📨 收到数据事件: topic=${e.topic} 来自: ${e.participant?.identity}");

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
      }
    } catch (err) {
      log.error("解析数据事件失败: $err");
    }
  }

  /// 处理远端举手/放手消息
  /// raised=true 加入 map，raised=false 从 map 移除
  void _onHandRaise(Map<String, dynamic> payload) {
    final uid = payload['uid'] as String?;
    final raised = payload['raised'] as bool? ?? false;
    final name = payload['name'] as String? ?? uid ?? '';
    if (uid == null) return;

    final current = state.value;
    if (current == null) return;

    final map = Map<String, bool>.from(current.handRaiseMap ?? {});
    if (raised) {
      map[uid] = true;
    } else {
      map.remove(uid);
    }
    state = AsyncData(current.copyWith(handRaiseMap: map));
    log.info("✋ $uid ${raised ? '举手' : '放手'}");

    // Toast 提示
    Toast.showNotificationNow(raised ? '$name 举手了 ✋' : '$name 放手了');
  }

  /// 处理远端表情/弹幕消息
  void _onChat(Map<String, dynamic> payload) {
    final message = payload['message'] as String?;
    final uid = payload['uid'] as String?;
    final name = payload['name'] as String? ?? uid ?? '';
    final avatar = payload['avatar'] as String?;
    if (message == null || uid == null) return;

    final current = state.value;
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
    log.info("💬 收到消息: $message 来自: $uid");
  }

  /// 处理主持人静音指令
  /// 收到指令后检查目标是否是自己，是则执行静音/取消静音
  void _onMuteCommand(Map<String, dynamic> payload) {
    final targetUid = payload['uid'] as String?;
    final muted = payload['muted'] as bool? ?? true;
    final senderName = payload['senderName'] as String? ?? '主持人';
    final current = state.value;
    if (current == null) return;

    // 只处理发给自己的指令
    final localIdentity = current.room.localParticipant?.identity;
    if (targetUid != localIdentity) return;

    current.room.localParticipant?.setMicrophoneEnabled(!muted);
    state = AsyncData(current.copyWith(micEnabled: !muted));
    log.info("📢 收到主持人指令: ${muted ? '静音' : '取消静音'}");

    // Toast 提示
    Toast.showNotificationNow(
      muted ? '$senderName 将您静音 🔇' : '$senderName 取消了您的静音 🔈',
    );
  }

  /// 绑定设备热插拔监听
  /// 当用户插拔耳机、摄像头等设备时自动刷新设备列表
  void _bindDeviceEvents() {
    final sub = Hardware.instance.onDeviceChange.stream.listen((_) async {
      await _loadDeviceList();
    });
    // Provider 销毁时自动取消订阅
    ref.onDispose(() => sub.cancel());
  }

  /// 刷新设备列表
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
  /// 只释放 listener 等本地资源，不访问 provider state
  void _disposeResources() {
    _listener?.dispose();
    log.info("资源已清理");
  }

  // ================= 公开功能 API =================

  /// 切换麦克风开关
  /// 使用独立防抖锁 _isTogglingMic，避免快速连点
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

  /// 切换摄像头开关
  /// 使用独立防抖锁 _isTogglingCamera，避免快速连点
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

  /// 切换屏幕共享
  /// 精细化管理轨道，单独发布屏幕共享轨道，不影响摄像头轨道
  /// 桌面端需要用户选择共享窗口/屏幕
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
        // 桌面端弹出窗口/屏幕选择对话框
        String? sourceId;
        if (lkPlatformIsDesktop()) {
          final source = await showDialog<rtc.DesktopCapturerSource?>(
            context: context,
            builder: (context) => WindowScreenSelectDialog(),
          );
          // 用户取消选择，不继续
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
        // 找到屏幕共享轨道并撤销发布
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
      // 出错时恢复到关闭状态，避免 UI 状态与实际不符
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

  /// 切换扬声器/听筒（主要用于移动端）
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
  /// 切换后重启音频轨道使新设备生效
  Future<void> switchAudioInput(MediaDevice device) async {
    final currentState = state.value;
    if (currentState == null) return;
    try {
      await Hardware.instance.selectAudioInput(device);
      // 重启轨道使新设备立即生效
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
      try {
        await currentState.room.disconnect().timeout(
          const Duration(seconds: 2),
        );
        log.info("已离开房间");
      } on TimeoutException {
        log.warning("离开房间超时，转为后台清理");
      } catch (e) {
        log.warning("离开房间异常（忽略并继续退出）: $e");
      }
    }
    ref.invalidateSelf();
  }

  /// 手动重连
  /// 通常不需要手动调用，SDK 会自动重连
  /// 仅在 SDK 放弃重连后（RoomDisconnectedEvent）才需要手动触发
  Future<void> reconnect() async {
    final currentState = state.value;
    if (currentState == null) return;
    await _connectRoom(currentState.room, currentState.token);
  }

  // ================= 自定义数据通道 API =================

  /// 底层数据发送方法
  /// [topic] 消息类型标识，接收方通过 topic 区分消息类别
  /// [payload] 业务数据，会被包装成 {payload, timestamp} 格式
  ///
  /// 注意：publishData 不会回传给发送方自己，
  /// 需要本地状态更新的操作必须在调用此方法前先更新 state
  Future<void> sendDataEvent({
    required String topic,
    Map<String, dynamic> payload = const {},
  }) async {
    final currentState = state.value;
    if (currentState == null) return;
    try {
      final data = jsonEncode({
        'payload': payload,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      await currentState.room.localParticipant?.publishData(
        utf8.encode(data),
        topic: topic,
      );
    } catch (e) {
      log.error("发送数据事件失败: $e");
    }
  }

  /// 举手 / 放手
  /// [raised] true=举手，false=放手
  ///
  /// 因为 publishData 不回传给自己，所以：
  ///   1. 先更新本地 handRaiseMap
  ///   2. 再广播给房间内其他人
  Future<void> sendHandRaise(bool raised) async {
    final current = state.value;
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

    log.info("✋ 本地${raised ? '举手' : '放手'}");
  }

  /// 发送表情 / 弹幕
  /// [message] 表情符号（如 '👍'）或弹幕文字
  ///
  /// 因为 publishData 不回传给自己，所以：
  ///   1. 先在本地添加 ReactionItem
  ///   2. 3 秒后按唯一 id 精确删除（避免同表情互相误删）
  ///   3. 再广播给房间内其他人
  Future<void> sendReaction(String message) async {
    final current = state.value;
    if (current == null) return;
    final uid = current.room.localParticipant?.identity ?? '';
    if (uid.isEmpty) return;

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
    // 广播给其他人
    await sendDataEvent(
      topic: 'app-chat',
      payload: {'message': message, 'uid': uid},
    );
  }

  /// 主持人静音指令
  /// [targetUid] 要被静音的参与者 identity（不是自己）
  /// [muted] true=静音，false=取消静音
  ///
  /// 接收方收到后会检查 targetUid 是否是自己，是则执行静音
  Future<void> sendMuteCommand(String targetUid, bool muted) {
    final current = state.value;
    final meta = _parseParticipantMeta(current?.room.localParticipant);
    return sendDataEvent(
      topic: 'app-mute-command',
      payload: {'uid': targetUid, 'muted': muted, 'senderName': meta.name},
    );
  }

  /// 踢出参与者（从通话房间移除）
  /// [identity] LiveKit 参与者 identity
  /// 对应后端接口 GET /call/participant/remove?roomId=&identity=
  Future<bool> kickParticipant(String identity) async {
    final current = state.value;
    if (current == null) return false;
    try {
      final roomId = current.room.name;
      if (roomId == null || roomId.isEmpty) {
        log.warning("踢出失败: roomId 为空");
        return false;
      }
      final res = await DioClient().get(
        API.callRemoveParticipant,
        queryParameters: {'roomId': roomId, 'identity': identity},
      );
      final code = res.data?['code'];
      if (code == 200) {
        Toast.showNotificationNow('已将该用户移出通话');
        log.info("✅ 踢出参与者 $identity 成功");
        return true;
      } else {
        final msg = res.data?['msg'] ?? '未知错误';
        Toast.showNotificationNow('踢出失败: $msg');
        log.warning("踢出参与者 $identity 失败: $msg");
        return false;
      }
    } catch (e) {
      log.error("踢出参与者失败: $e");
      Toast.showNotificationNow('踢出失败，请重试');
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
