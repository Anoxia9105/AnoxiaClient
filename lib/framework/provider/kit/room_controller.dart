import 'dart:async';

import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../pages/call_window/component/WindowScreenSelectDialog.dart';
import '../../domain/RoomState.dart';
import '../../network/DioClient.dart';

part 'room_controller.g.dart';

@riverpod
class RoomController extends _$RoomController {
  EventsListener<RoomEvent>? _listener;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  Timer? _statsTimer;

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
      // 清理内部资源（监听器/定时器等），不要在 dispose 中访问 provider state
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
      // 连接房间（带超时处理）
      await _connectRoom(room, token);

      // 绑定事件监听
      final listener = room.createListener();
      _listener = listener;

      listener
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

      // 注意：有些 LiveKit 事件类型并不在包的顶层导出，直接以类型化泛型注册可能会导致编译错误。
      // 为了兼容各种 SDK 版本，我们在 Room 的 events 流上注册一个动态监听器，
      // 在运行时通过 runtimeType 字符串判断事件类型并提取字段。
      // 该处理器主要用于捕获 connection-quality 更新并写回 RoomState，供 UI 显示网络质量。
        room.events.listen((dynamic evt) {
        try {
          final typeName = evt.runtimeType.toString();
          // 只关心 connection quality 相关事件
          if (!typeName.toLowerCase().contains('connectionquality') && !typeName.toLowerCase().contains('connection_quality') && !typeName.toLowerCase().contains('participantconnectionquality')) {
            return; // 忽略非质量相关事件
          }

          final current = state.value;
          if (current == null) return;

          // 复制当前映射以便修改后替换（不可变模式）
          final Map<String, String> qmap = Map.from(current.participantQuality ?? {});
          final Map<String, int> rmap = Map.from(current.participantRttMs ?? {});

          // 如果是 ParticipantConnectionQualityUpdatedEvent（常见于 livekit），优先用专门解析以提高可靠性
          if (typeName.toLowerCase().contains('participantconnectionquality')) {
            try {
              final dynEvt = evt as dynamic;
              String sid = '';
              try {
                sid = dynEvt.participant?.sid?.toString() ?? '';
              } catch (_) {
                sid = '';
              }
              if (sid.isNotEmpty) {
                String qualityLabel = 'unknown';
                try {
                  final qv = dynEvt.connectionQuality?.toString() ?? '';
                  if (qv.toLowerCase().contains('poor')) qualityLabel = 'poor';
                  else if (qv.toLowerCase().contains('fair')) qualityLabel = 'fair';
                  else if (qv.toLowerCase().contains('good') || qv.toLowerCase().contains('excellent')) qualityLabel = 'good';
                  else if (qv.isNotEmpty) qualityLabel = qv;
                } catch (_) {}

                final Map<String, String> qmap = Map.from(current.participantQuality ?? {});
                final Map<String, int> rmap = Map.from(current.participantRttMs ?? {});
                qmap[sid] = qualityLabel;
                state = AsyncData(current.copyWith(participantQuality: qmap, participantRttMs: rmap));
              }
            } catch (e) {
              log.error('专门解析 ParticipantConnectionQualityUpdatedEvent 失败: $e');
            }
            return;
          }

          // 尝试安全地取得更新项集合：有些事件带 updates 列表，有些事件本身就是单条更新
          Iterable<dynamic>? updates;
          try {
            // 有些实现会提供 updates 字段
            updates = (evt as dynamic).updates as Iterable<dynamic>?;
          } catch (noMethod) {
            // 访问 updates 抛出 NoSuchMethodError，说明 evt 可能就是单条更新项
            updates = null;
          }

          // 如果没有 updates，则把整个事件当作单条更新项处理
          final Iterable<dynamic> itemsToProcess = updates ?? [evt];

          // 记录事件类型与一个示例（仅作调试）
          try {
            log.info('收到 connection-quality 事件: $typeName, sample=${evt.toString()}');
          } catch (_) {}

          for (final update in itemsToProcess) {
            try {
              // 动态访问常见字段：participant 或 participantSid / participantIdentity / participantId
              String sid = '';
              try {
                final dyn = update as dynamic;
                // 某些事件会把 participant 嵌套在 update.participant 中
                if (dyn.participant != null) {
                  try {
                    sid = dyn.participant.sid?.toString() ?? '';
                  } catch (_) {
                    sid = '';
                  }
                }

                if (sid.isEmpty) {
                  sid = (dyn.participantSid ?? dyn.participantIdentity ?? dyn.participantId ?? '').toString();
                }
              } catch (_) {
                sid = '';
              }
              if (sid.isEmpty) continue;

              // 尝试读取 RTT（字段名在不同版本可能为 rttMs / rtt / roundTripTimeMs / roundTripTime）
              int? rttMs;
              try {
                final dyn = update as dynamic;
                if (dyn.rttMs != null && dyn.rttMs is int) rttMs = dyn.rttMs as int;
                if (rttMs == null && dyn.rtt != null && dyn.rtt is int) rttMs = dyn.rtt as int;
                if (rttMs == null && dyn.roundTripTimeMs != null && dyn.roundTripTimeMs is int) rttMs = dyn.roundTripTimeMs as int;
                if (rttMs == null && dyn.roundTripTime != null && dyn.roundTripTime is int) rttMs = dyn.roundTripTime as int;
                // 有些事件把 rtt 放在 connectionQualityInfo 中（暂不处理），保留扩展点
              } catch (_) {
                // ignore per-item rtt read errors
              }

              // 读取 quality 字段（可能是 enum 或整数或字符串）
              String qualityLabel = 'unknown';
              try {
                final dyn = update as dynamic;
                // 常见字段可能为 quality 或 connectionQuality
                var qvRaw;
                if (dyn.quality != null) qvRaw = dyn.quality;
                else if (dyn.connectionQuality != null) qvRaw = dyn.connectionQuality;
                else if (dyn.connection_quality != null) qvRaw = dyn.connection_quality;

                if (qvRaw != null) {
                  final qv = qvRaw.toString();
                  if (qv.toLowerCase().contains('poor')) {
                    qualityLabel = 'poor';
                  } else if (qv.toLowerCase().contains('fair')) {
                    qualityLabel = 'fair';
                  } else if (qv.toLowerCase().contains('good') || qv.toLowerCase().contains('excellent')) {
                    // 将 'excellent' 归为 good 以便 UI 简化
                    qualityLabel = 'good';
                  } else {
                    qualityLabel = qv;
                  }
                }
              } catch (_) {
                // ignore
              }

              if (rttMs != null) rmap[sid] = rttMs;
              qmap[sid] = qualityLabel;
            } catch (inner) {
              log.error('解析 connection quality 更新项失败: $inner');
            }
          }

          state = AsyncData(current.copyWith(participantQuality: qmap, participantRttMs: rmap));
        } catch (err) {
          log.error('处理 connection quality 事件失败: $err');
        }
      });

      room.addListener(updateState);

      _bindDeviceEvents();

      // 监控 connectionState，出现 disconnect / failed 时触发自动重连流程
      room.addListener(() {
        try {
          final cs = room.connectionState;
          // 如果连接不是 connected 或 connecting，则尝试重连（兼容不同 SDK 的枚举）
          try {
            if (cs != ConnectionState.connected && cs != ConnectionState.connecting) {
              _scheduleReconnect(room, token);
            }
          } catch (_) {
            // 若 SDK 中缺少某些枚举值，退回到字符串检查
            final csStr = cs.toString();
            if (csStr.toLowerCase().contains('dis') || csStr.toLowerCase().contains('fail')) {
              _scheduleReconnect(room, token);
            }
          }
        } catch (_) {}
      });

      // 启动周期性 stats 轮询（每 5s）用于采集 RTT（如果 SDK 支持）
      _statsTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        try {
          final current = state.value;
          if (current == null) return;

          dynamic stats;
          try {
            stats = await (room as dynamic).getStats();
          } catch (_) {
            try {
              stats = await (room.engine as dynamic).getStats();
            } catch (_) {
              stats = null;
            }
          }

          if (stats == null) return;

          final Map<String, int> rmap = Map.from(current.participantRttMs ?? {});
          try {
            if (stats is Iterable) {
              for (final entry in stats) {
                try {
                  final sid = (entry is Map) ? (entry['participantId'] ?? entry['participant'] ?? entry['sid']) : null;
                  final rtt = (entry is Map) ? (entry['roundTripTimeMs'] ?? entry['rttMs'] ?? entry['rtt']) : null;
                  if (sid != null && rtt != null) {
                    final sidStr = sid.toString();
                    rmap[sidStr] = (rtt is num) ? rtt.toInt() : int.tryParse(rtt.toString()) ?? 0;
                  }
                } catch (_) {}
              }
            } else if (stats is Map) {
              stats.forEach((k, v) {
                try {
                  if (v is Map) {
                    final rtt = v['roundTripTimeMs'] ?? v['rttMs'] ?? v['rtt'];
                    if (rtt != null) {
                      final sidStr = k.toString();
                      rmap[sidStr] = (rtt is num) ? rtt.toInt() : int.tryParse(rtt.toString()) ?? 0;
                    }
                  }
                } catch (_) {}
              });
            }
          } catch (_) {}

          state = AsyncData(current.copyWith(participantRttMs: rmap));
        } catch (_) {}
      });

      // 获取初始设备列表
      final devices = await _getInitialDevices();

      // 初始化本地轨道（麦克风/摄像头）
      await _initLocalTracks(room);

      // 返回初始状态
      // 这里把 joinedAt 记录为当前时间，表示本客户端加入房间的时间点（用于本地计时显示）
      final now = DateTime.now();
      // 初始化 participantQuality 与 participantRttMs 为空 map，后续会由事件更新
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
        joinedAt: now,
        participantQuality: {},
        participantRttMs: {},
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
    // 仅释放 listener 与其他本地资源。
    // 注意：不要在 dispose 回调中访问或修改 provider 的 state（会触发 Riverpod 的断言）。
    _listener?.dispose();
    _statsTimer?.cancel();
    _reconnectTimer?.cancel();
    log.info("资源已清理");
  }

  /// 安排自动短线重连（指数退避）
  void _scheduleReconnect(Room room, String token) {
    // 如果已经安排了重连则不重复安排
    if (_reconnectTimer != null && _reconnectTimer!.isActive) return;
    _reconnectAttempts = 0;
    // 标记为正在重连
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(isReconnecting: true));
    }

    _reconnectTimer = Timer(const Duration(seconds: 1), () async {
      try {
        // 指数退避，最多 6 次
        while (_reconnectAttempts < 6) {
          final delaySeconds = (1 << _reconnectAttempts).clamp(1, 30);
          log.info('尝试第 ${_reconnectAttempts + 1} 次重连，延迟 ${delaySeconds}s');
          await Future.delayed(Duration(seconds: delaySeconds));

          // 在每次尝试前，优先尝试刷新 room token（如果可用）以避免使用过期 token
          String currentToken = token;
          try {
            final roomId = room.name ?? '';
            if (roomId.isNotEmpty) {
              try {
                final fresh = await ref.read(roomTokenProvider(roomId).future);
                if (fresh.isNotEmpty) {
                  currentToken = fresh;
                }
              } catch (e) {
                log.info('尝试获取 fresh token 失败，继续使用旧 token: $e');
              }
            }
          } catch (_) {}

          try {
            await _connectRoom(room, currentToken);
            log.info('自动重连成功');
            _reconnectTimer?.cancel();
            _reconnectAttempts = 0;

            // 恢复 isReconnecting 状态
            final cur = state.value;
            if (cur != null) state = AsyncData(cur.copyWith(isReconnecting: false));
            return;
          } catch (e) {
            log.warning('自动重连失败: $e');
            // 如果是 token 过期导致的失败，停止无意义的重试并把错误暴露到 UI
            try {
              final err = e.toString().toLowerCase();
              if (err.contains('token') && (err.contains('exp') || err.contains('expired'))) {
                log.warning('检测到 token 过期，停止自动重连并通知 UI');
                // 尝试让 roomToken provider 被重新获取（前端可触发刷新）
                try {
                  final roomId = room.name ?? '';
                  if (roomId.isNotEmpty) {
                    ref.invalidate(roomTokenProvider(roomId));
                  }
                } catch (_) {}

                final cur = state.value;
                if (cur != null) {
                  state = AsyncData(cur.copyWith(connectionError: 'token_expired', isReconnecting: false));
                }
                _reconnectTimer?.cancel();
                return;
              }
            } catch (_) {}

            _reconnectAttempts++;
            continue;
          }
        }

        log.warning('自动重连尝试次数耗尽');
      } catch (_) {
      } finally {
        final cur = state.value;
        if (cur != null) state = AsyncData(cur.copyWith(isReconnecting: false));
      }
    });
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
