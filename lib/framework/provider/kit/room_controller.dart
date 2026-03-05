import 'dart:async';

import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../pages/chat/call/component/WindowScreenSelectDialog.dart';
import '../../domain/RoomState.dart';
import '../../network/DioClient.dart';

part 'room_controller.g.dart';

@riverpod
class RoomController extends _$RoomController {
  EventsListener<RoomEvent>? _listener;
  Timer? _statsTimer;
  ConnectionState? _lastConnectionState; // 记录上一个连接状态，防止重复触发

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
        ..on<RoomConnectedEvent>((_) {
          log.info("✓ 房间已连接");
          // 清除之前的连接错误状态
          final current = state.value;
          if (current != null && current.connectionError != null) {
            state = AsyncData(current.copyWith(connectionError: null));
          }
        })
        ..on<RoomDisconnectedEvent>((e) {
          log.info("✗ 房间已断开 - 将启动自动重连流程");
          // 触发自动重连（在 connectionState 监听器中实现）
        })
        ..on<ParticipantConnectedEvent>((e) {
          log.info("➕ 参与者加入: ${e.participant.identity}");
          updateState(); // 有人加入，列表变了，必须刷新
        })
        ..on<ParticipantDisconnectedEvent>((e) {
          log.info("➖ 参与者离开: ${e.participant.identity}");
          updateState(); // 有人离开，列表变了，必须刷新
        })
        ..on<ActiveSpeakersChangedEvent>((e) {
          // 说话者变化。虽然 UI 组件自己会监听，但这里更新有助于排序
          log.info("🔊 活跃发言者变化 (${e.speakers.length} 人)");
          final current = state.value;
          if (current != null && e.speakers.isNotEmpty) {
            // 将第一个活跃说话者设为焦点参与者
            final focusedId = e.speakers.first.identity;
            state = AsyncData(
              current.copyWith(focusedParticipantId: focusedId),
            );
          }
          updateState();
        })
        ..on<RoomRecordingStatusChanged>((event) {
          // 📹 房间录音状态变化
          log.info('📹 房间录音状态变化: ${event.activeRecording}');
          final current = state.value;
          if (current != null) {
            state = AsyncData(
              current.copyWith(isRecording: event.activeRecording),
            );
          }
        })
        ..on<RoomMetadataChangedEvent>((event) {
          // 📝 房间元数据变化
          log.info('📝 房间元数据变化: ${event.metadata}');
          final current = state.value;
          if (current != null) {
            state = AsyncData(current.copyWith(roomMetadata: event.metadata));
          }
        });

      // 额外监听 Reconnecting 和 Reconnected 事件（某些 SDK 版本可能包含）
      try {
        listener..on<dynamic>((evt) {
          final typeName = evt.runtimeType.toString();
          if (typeName.contains('Reconnecting')) {
            log.warning('🔄 房间正在重新连接...');
            final current = state.value;
            if (current != null) {
              state = AsyncData(current.copyWith(isReconnecting: true));
            }
          } else if (typeName.contains('Reconnected')) {
            log.info('✅ 房间已重新连接');
            final current = state.value;
            if (current != null) {
              state = AsyncData(
                current.copyWith(isReconnecting: false, connectionError: null),
              );
            }
          }
        });
      } catch (_) {
        // 某些 SDK 版本可能不支持通用 dynamic 监听
      }

      // 注意：有些 LiveKit 事件类型并不在包的顶层导出，直接以类型化泛型注册可能会导致编译错误。
      // 为了兼容各种 SDK 版本，我们在 Room 的 events 流上注册一个动态监听器，
      // 在运行时通过 runtimeType 字符串判断事件类型并提取字段。
      // 该处理器主要用于捕获 connection-quality 更新、debugging 日志等。
      room.events.listen((dynamic evt) {
        try {
          final typeName = evt.runtimeType.toString();

          // 调试：记录所有事件类型（仅在 debug 时输出，减少日志噪音）
          if (typeName.toLowerCase().contains('reconnect') ||
              typeName.toLowerCase().contains('disconnect') ||
              typeName.toLowerCase().contains('connectionquality') ||
              typeName.toLowerCase().contains('connection_state')) {
            log.info('📡 Room Event: $typeName');
          }

          // 只关心 connection quality 相关事件进行数据提取
          if (!typeName.toLowerCase().contains('connectionquality') &&
              !typeName.toLowerCase().contains('connection_quality') &&
              !typeName.toLowerCase().contains(
                'participantconnectionquality',
              )) {
            return; // 忽略非质量相关事件
          }

          final current = state.value;
          if (current == null) return;

          // 不再维护 participantQuality，改为由 ConnectionQuality 强类型直接在 ParticipantTile 获取

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
            log.info(
              '收到 connection-quality 事件: $typeName, sample=${evt.toString()}',
            );
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
                  sid =
                      (dyn.participantSid ??
                              dyn.participantIdentity ??
                              dyn.participantId ??
                              '')
                          .toString();
                }
              } catch (_) {
                sid = '';
              }
              if (sid.isEmpty) continue;

              // 尝试读取 RTT（字段名在不同版本可能为 rttMs / rtt / roundTripTimeMs / roundTripTime）
              int? rttMs;
              try {
                final dyn = update as dynamic;
                if (dyn.rttMs != null && dyn.rttMs is int)
                  rttMs = dyn.rttMs as int;
                if (rttMs == null && dyn.rtt != null && dyn.rtt is int)
                  rttMs = dyn.rtt as int;
                if (rttMs == null &&
                    dyn.roundTripTimeMs != null &&
                    dyn.roundTripTimeMs is int)
                  rttMs = dyn.roundTripTimeMs as int;
                if (rttMs == null &&
                    dyn.roundTripTime != null &&
                    dyn.roundTripTime is int)
                  rttMs = dyn.roundTripTime as int;
              } catch (_) {
                // ignore per-item rtt read errors
              }

              if (rttMs != null) {
                final Map<String, int> rmap = Map.from(
                  current.participantRttMs ?? {},
                );
                rmap[sid] = rttMs;
                state = AsyncData(current.copyWith(participantRttMs: rmap));
              }
            } catch (inner) {
              log.error('解析 RTT 信息失败: $inner');
            }
          }
        } catch (err) {
          log.error('处理 connection stats 事件失败: $err');
        }
      });

      room.addListener(updateState);

      _bindDeviceEvents();

      // 监控 connectionState 变化（仅用于日志，不干预重连逻辑）
      // SDK 会自动处理重连，通过 RoomReconnectingEvent 和 RoomReconnectedEvent
      room.addListener(() {
        try {
          final cs = room.connectionState;
          final csStr = cs.toString();

          // 防止重复触发：只在状态真正改变时才输出日志
          if (cs == _lastConnectionState) {
            return; // 状态未改变，忽略
          }
          _lastConnectionState = cs;

          log.info('📡 ConnectionState: $csStr');
        } catch (e) {
          log.error('监控连接状态时出错: $e');
        }
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

          final Map<String, int> rmap = Map.from(
            current.participantRttMs ?? {},
          );
          try {
            if (stats is Iterable) {
              for (final entry in stats) {
                try {
                  final sid = (entry is Map)
                      ? (entry['participantId'] ??
                            entry['participant'] ??
                            entry['sid'])
                      : null;
                  final rtt = (entry is Map)
                      ? (entry['roundTripTimeMs'] ??
                            entry['rttMs'] ??
                            entry['rtt'])
                      : null;
                  if (sid != null && rtt != null) {
                    final sidStr = sid.toString();
                    rmap[sidStr] = (rtt is num)
                        ? rtt.toInt()
                        : int.tryParse(rtt.toString()) ?? 0;
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
                      rmap[sidStr] = (rtt is num)
                          ? rtt.toInt()
                          : int.tryParse(rtt.toString()) ?? 0;
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
        participantRttMs: {},
        participantVolumes: {},
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
      API.callToken,
      queryParameters: {"roomId": roomId},
      options: Options(responseType: ResponseType.plain),
    );
    return res.data.toString();
  } catch (e) {
    log.error("获取房间Token失败: $e");
    rethrow;
  }
}
