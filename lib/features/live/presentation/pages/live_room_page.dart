import 'dart:async';
import 'dart:convert';

import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/utils/app_permission.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/framework/domain/room_state.dart';
import 'package:anoxia/framework/network/dio_client.dart';
import 'package:anoxia/framework/provider/live/live_room_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:anoxia/platform/shims/window_manager_shim.dart';

part 'live_room_widgets.dart';
part 'live_room_models.dart';

/// 直播间页面
///
/// 提供直播房间的主功能，包括弹幕互动、连麦申请与处理、音视频控制、
/// 屏幕共享等完整的直播体验。

/// 直播可见性枚举
enum LiveVisibility {
  public,
  private;
}

/// 直播可见性扩展
extension LiveVisibilityX on LiveVisibility {
  /// 获取中文标签
  String get label => this == LiveVisibility.public ? '公开' : '私密';

  /// 获取国际化标签
  String trLabel() => this == LiveVisibility.public ? 'live_visibility_public'.tr() : 'live_visibility_private'.tr();
}

/// 直播可见性编解码扩展
extension LiveVisibilityCodec on LiveVisibility {
  /// 获取服务端对应的值
  String get serverValue {
    switch (this) {
      case LiveVisibility.public:
        return 'PUBLIC';
      case LiveVisibility.private:
        return 'PRIVATE';
    }
  }
}

/// 直播来源枚举
enum LiveSource {
  camera,
  screen;
}

/// 直播来源扩展
extension LiveSourceX on LiveSource {
  /// 获取中文标签
  String get label => this == LiveSource.camera ? '摄像头' : '屏幕共享';

  /// 获取国际化标签
  String trLabel() => this == LiveSource.camera ? 'live_source_camera'.tr() : 'live_source_screen'.tr();
}

/// 直播来源编解码扩展
extension LiveSourceCodec on LiveSource {
  /// 获取服务端对应的值
  String get serverValue {
    switch (this) {
      case LiveSource.camera:
        return 'CAMERA';
      case LiveSource.screen:
        return 'SCREEN';
    }
  }
}

/// 直播间页面组件
///
/// 封装了完整的直播房间 UI，包括视频画面、房间头部信息、弹幕聊天面板、
/// 设备控制按钮等，支持主播和观众两种角色。
class LiveRoomPage extends ConsumerStatefulWidget {
  /// 房间 ID
  final String roomId;

  /// 房间标题
  final String title;

  /// 是否为主播
  final bool isHost;

  /// 直播可见性
  final LiveVisibility visibility;

  /// 直播来源（摄像头或屏幕共享）
  final LiveSource source;

  /// 屏幕共享源 ID
  final String? screenSourceId;

  const LiveRoomPage({
    super.key,
    required this.roomId,
    this.title = '',
    required this.isHost,
    this.visibility = LiveVisibility.public,
    this.source = LiveSource.camera,
    this.screenSourceId,
  });

  @override
  ConsumerState<LiveRoomPage> createState() => _LiveRoomPageState();
}

/// 直播间页面状态
///
/// 管理直播间的完整生命周期，包括进入房间、弹幕收发、连麦申请与响应、
/// 音视频设备控制、桌面端侧边面板布局等。
class _LiveRoomPageState extends ConsumerState<LiveRoomPage> {
  /// 弹幕消息主题
  static const _danmakuTopic = 'live-danmaku';

  /// 连麦请求主题
  static const _cohostRequestTopic = 'live-cohost-request';

  /// 连麦响应主题
  static const _cohostResponseTopic = 'live-cohost-response';

  /// 最大消息数量
  static const int _maxMessageCount = 200;

  /// 单条消息字符数上限
  static const int _messageCharLimit = 300;

  /// 连麦请求超时时间
  static const Duration _cohostRequestTimeout = Duration(seconds: 20);

  /// 聊天输入控制器
  final TextEditingController _chatController = TextEditingController();

  /// 聊天消息列表
  final List<_LiveChatMessage> _messages = [
    const _LiveChatMessage(text: '欢迎进入直播间，开始互动吧', isHost: true, name: '系统'),
  ];

  /// 连麦请求映射表
  final Map<String, _CohostRequest> _cohostRequests = {};

  /// 房间事件监听器
  EventsListener<RoomEvent>? _roomListener;

  /// 当前监听中的房间
  Room? _listeningRoom;

  /// 是否已发起连麦请求
  bool _cohostRequested = false;

  /// 连麦是否激活
  bool _cohostActive = false;

  /// 是否已启动初始媒体
  bool _initialMediaStarted = false;

  /// 是否已发送进入消息
  bool _joinMessageSent = false;

  /// 是否已处理观众断连
  bool _handledAudienceDisconnected = false;

  /// 上次发送的文本
  String _lastSentText = '';

  /// 上次发送时间
  DateTime? _lastSentAt;

  /// 连麦请求超时计时器
  Timer? _cohostRequestTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enterRoom();
    });
  }

  @override
  void dispose() {
    _cohostRequestTimer?.cancel();
    _roomListener?.dispose();
    _chatController.dispose();
    if (widget.isHost) {
      unawaited(_endLive());
    }
    super.dispose();
  }

  /// 进入直播间
  ///
  /// 主播进入前需要检查摄像头/麦克风权限，观众进入后发送系统消息通知。
  Future<void> _enterRoom() async {
    if (widget.isHost) {
      final mic = await ensureAppPermission(
        context,
        Permission.microphone,
        permissionName: '麦克风',
      );
      if (!mounted) return;
      final camera = widget.source == LiveSource.camera
          ? await ensureAppPermission(
              context,
              Permission.camera,
              permissionName: '摄像头',
            )
          : null;
      if (!mic || camera == false) {
        if (!mounted) return;
        Toast.showNotificationNow(
          widget.source == LiveSource.camera ? '需要开启摄像头和麦克风权限' : '需要开启麦克风权限',
        );
        Navigator.of(context).pop();
        return;
      }
    }

    await ref.read(
      liveRoomControllerProvider(widget.roomId, widget.isHost).future,
    );

    if (!widget.isHost) {
      unawaited(_sendJoinMessage());
    }
  }

  /// 启动初始媒体设备
  ///
  /// 根据直播来源（摄像头或屏幕共享）自动开启对应的媒体设备。
  Future<void> _startInitialMedia() async {
    if (_initialMediaStarted || !widget.isHost) return;
    _initialMediaStarted = true;

    final controller = ref.read(
      liveRoomControllerProvider(widget.roomId, widget.isHost).notifier,
    );
    try {
      if (widget.source == LiveSource.screen) {
        await controller.toggleMic();
        if (mounted) {
          await controller.toggleScreenShare(
            context,
            sourceId: widget.screenSourceId,
          );
        }
      } else {
        await controller.toggleCamera();
        await controller.toggleMic();
      }
    } catch (e) {
      _initialMediaStarted = false;
      Toast.showNotificationNow('live_start_video_error'.tr(args: [e.toString()]));
    }
  }

  /// 结束直播
  ///
  /// 向服务端发送结束直播请求。
  Future<void> _endLive() async {
    try {
      await DioClient().post('/live/end', data: {'roomId': widget.roomId});
    } catch (_) {}
  }

  /// 离开房间
  ///
  /// 桌面端关闭窗口，移动端弹出页面。
  Future<void> _leaveRoom() async {
    if (DeviceUtil.isRealDesktop()) {
      await windowManager.close();
      return;
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  /// 绑定房间数据监听器
  ///
  /// 监听房间内的数据事件（弹幕、连麦请求/响应等）。
  /// [room] 要监听的房间对象。
  void _bindRoomDataListener(Room room) {
    if (identical(_listeningRoom, room)) {
      return;
    }

    _roomListener?.dispose();
    _listeningRoom = room;
    _roomListener = room.createListener()
      ..on<DataReceivedEvent>((event) {
        _handleDataEvent(event);
      });
  }

  /// 处理数据事件
  ///
  /// 根据消息主题分发处理弹幕消息、连麦请求和连麦响应。
  /// [event] 接收到的数据事件。
  void _handleDataEvent(DataReceivedEvent event) {
    try {
      final json = jsonDecode(utf8.decode(event.data)) as Map<String, dynamic>;
      final payload = json['payload'] as Map<String, dynamic>? ?? json;

      switch (event.topic) {
        case _danmakuTopic:
          _addMessage(
            _LiveChatMessage(
              text: payload['text']?.toString() ?? '',
              isHost: payload['isHost'] == true,
              name: payload['name']?.toString() ?? '观众',
            ),
          );
          break;
        case _cohostRequestTopic:
          if (!widget.isHost) return;
          final identity = payload['identity']?.toString() ?? '';
          if (identity.isEmpty) return;
          final action = payload['action']?.toString() ?? 'request';

          if (action == 'cancel') {
            final removed = _cohostRequests.remove(identity);
            if (removed != null && mounted) {
              setState(() {});
              Toast.showNotificationNow('live_cohost_request_cancelled'.tr(args: [removed.name]));
            }
            return;
          }

          final existed = _cohostRequests.containsKey(identity);
          setState(() {
            _cohostRequests[identity] = _CohostRequest(
              identity: identity,
              name: payload['name']?.toString() ?? identity,
            );
          });
          if (!existed) {
            Toast.showNotificationNow(
              '${_cohostRequests[identity]?.name ?? identity} 申请连麦',
            );
          }
          break;
        case _cohostResponseTopic:
          if (widget.isHost) return;
          final identity = payload['identity']?.toString();
          final localIdentity = _localIdentity;
          if (identity != localIdentity) return;
          final accepted = payload['accepted'] == true;
          final reason = payload['reason']?.toString();
          _clearCohostRequestState();
          setState(() {
            _cohostActive = accepted;
          });
          if (accepted) {
            Toast.showNotificationNow('live_cohost_request_accepted'.tr());
          } else {
            Toast.showNotificationNow(reason?.isNotEmpty == true ? reason! : 'live_cohost_request_rejected'.tr());
          }
          if (accepted) {
            unawaited(_enableAudienceMic());
          }
          break;
      }
    } catch (e) {
      Toast.showNotificationNow('live_interact_message_error'.tr(args: [e.toString()]));
    }
  }

  /// 获取本地参与者标识
  String get _localIdentity {
    final state = ref.read(
      liveRoomControllerProvider(widget.roomId, widget.isHost),
    );
    return state.value?.room.localParticipant?.identity ?? '';
  }

  /// 发布直播事件
  ///
  /// 向房间广播自定义数据消息。
  /// [topic] 消息主题。
  /// [payload] 消息负载。
  Future<void> _publishLiveEvent({
    required String topic,
    required Map<String, dynamic> payload,
  }) async {
    final current = ref.read(
      liveRoomControllerProvider(widget.roomId, widget.isHost),
    );
    final room = current.value?.room;
    final localParticipant = room?.localParticipant;
    if (localParticipant == null) return;

    await localParticipant.publishData(
      utf8.encode(
        jsonEncode({
          'payload': payload,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      ),
      reliable: true,
      topic: topic,
    );
  }

  /// 发送进入消息
  ///
  /// 观众进入房间时广播一条系统消息通知。
  Future<void> _sendJoinMessage() async {
    if (_joinMessageSent) return;
    _joinMessageSent = true;

    final current = ref.read(
      liveRoomControllerProvider(widget.roomId, widget.isHost),
    );
    final participant = current.value?.room.localParticipant;
    final name = _participantName(participant);
    final text = '$name 进入直播间';

    if (!mounted) return;
    _addMessage(_LiveChatMessage(text: text, isHost: false, name: '系统'));

    try {
      await _publishLiveEvent(
        topic: _danmakuTopic,
        payload: {'text': text, 'isHost': false, 'name': '系统', 'system': true},
      );
    } catch (e) {
      _joinMessageSent = false;
      Toast.showNotificationNow('live_enter_notify_error'.tr(args: [e.toString()]));
    }
  }

  /// 获取参与者的显示名称
  ///
  /// 优先从参与者元数据中获取昵称，否则使用身份标识。
  /// [participant] 参与者对象。
  String _participantName(Participant? participant) {
    if (participant == null) return '观众';
    try {
      final metadata =
          jsonDecode(participant.metadata ?? '{}') as Map<String, dynamic>;
      final nickName = metadata['nickName']?.toString();
      if (nickName != null && nickName.trim().isNotEmpty) {
        return nickName.trim();
      }
    } catch (_) {}
    return participant.identity;
  }

  /// 添加聊天消息
  ///
  /// 将消息添加到列表并限制最大数量，超出字符限制的消息会被截断。
  /// [message] 聊天消息对象。
  void _addMessage(_LiveChatMessage message) {
    final trimmed = message.text.trim();
    if (trimmed.isEmpty) return;
    final normalized = trimmed.length > _messageCharLimit
        ? '${trimmed.substring(0, _messageCharLimit)}...'
        : trimmed;

    setState(() {
      _messages.add(message.copyWith(text: normalized));
      if (_messages.length > _maxMessageCount) {
        _messages.removeRange(0, _messages.length - _maxMessageCount);
      }
    });
  }

  /// 发送弹幕消息
  ///
  /// 发送聊天消息到房间，包含防重复发送检查。
  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    if (_lastSentText == text &&
        _lastSentAt != null &&
        now.difference(_lastSentAt!) < const Duration(seconds: 2)) {
      Toast.showNotificationNow('live_send_too_fast'.tr());
      return;
    }
    _lastSentText = text;
    _lastSentAt = now;

    final message = _LiveChatMessage(
      text: text,
      isHost: widget.isHost,
      name: widget.isHost ? '主播' : '我',
    );
    _addMessage(message);
    _chatController.clear();

    try {
      await _publishLiveEvent(
        topic: _danmakuTopic,
        payload: {
          'text': text,
          'isHost': widget.isHost,
          'name': widget.isHost ? '主播' : '观众',
        },
      );
    } catch (e) {
      Toast.showNotificationNow('live_danmaku_send_error'.tr(args: [e.toString()]));
    }
  }

  /// 发起连麦请求
  ///
  /// 观众向主播发送连麦申请，包含超时计时器。
  Future<void> _requestCohost() async {
    if (_cohostRequested || _cohostActive) return;
    final identity = _localIdentity;
    if (identity.isEmpty) return;

    final current = ref.read(
      liveRoomControllerProvider(widget.roomId, widget.isHost),
    );
    if (current.value?.connectionState.name != 'connected') {
      Toast.showNotificationNow('live_not_ready_retry'.tr());
      return;
    }

    setState(() => _cohostRequested = true);
    _startCohostRequestTimer();
    try {
      final participant = current.value?.room.localParticipant;
      final name = _participantName(participant);
      await _publishLiveEvent(
        topic: _cohostRequestTopic,
        payload: {'identity': identity, 'name': name, 'action': 'request'},
      );
      Toast.showNotificationNow('live_cohost_request_sent'.tr());
    } catch (e) {
      _clearCohostRequestState();
      Toast.showNotificationNow('live_cohost_request_error'.tr(args: [e.toString()]));
    }
  }

  /// 取消连麦请求
  ///
  /// 观众取消已发出的连麦申请。
  Future<void> _cancelCohostRequest() async {
    if (!_cohostRequested || _cohostActive) return;
    final identity = _localIdentity;
    if (identity.isEmpty) {
      _clearCohostRequestState();
      return;
    }

    _clearCohostRequestState();
    try {
      await _publishLiveEvent(
        topic: _cohostRequestTopic,
        payload: {'identity': identity, 'action': 'cancel'},
      );
      Toast.showNotificationNow('live_cohost_request_cancelled_success'.tr());
    } catch (e) {
      Toast.showNotificationNow('live_cohost_request_cancel_error'.tr(args: [e.toString()]));
    }
  }

  /// 启动连麦请求超时计时器
  void _startCohostRequestTimer() {
    _cohostRequestTimer?.cancel();
    _cohostRequestTimer = Timer(_cohostRequestTimeout, () {
      if (!mounted || !_cohostRequested || _cohostActive) return;
      _clearCohostRequestState();
      Toast.showNotificationNow('live_cohost_request_timeout'.tr());
    });
  }

  /// 清除连麦请求状态
  void _clearCohostRequestState() {
    _cohostRequestTimer?.cancel();
    _cohostRequestTimer = null;
    if (mounted && _cohostRequested) {
      setState(() => _cohostRequested = false);
    } else {
      _cohostRequested = false;
    }
  }

  /// 响应连麦请求
  ///
  /// 主播同意或拒绝观众的连麦申请。
  /// [request] 连麦请求对象。
  /// [accepted] 是否接受。
  Future<void> _respondCohost(_CohostRequest request, bool accepted) async {
    setState(() {
      _cohostRequests.remove(request.identity);
    });

    try {
      final res = await DioClient().post(
        '/live/cohost/respond',
        data: {
          'roomId': widget.roomId,
          'identity': request.identity,
          'accepted': accepted,
        },
      );
      if (res.data?['code'] != 200) {
        throw Exception(res.data?['msg'] ?? res.data?['message'] ?? '处理失败');
      }
      await _publishLiveEvent(
        topic: _cohostResponseTopic,
        payload: {
          'identity': request.identity,
          'accepted': accepted,
          'reason': accepted ? '主播已同意连麦' : '主播拒绝了连麦申请',
        },
      );
    } catch (e) {
      Toast.showNotificationNow('live_cohost_request_process_error'.tr(args: [e.toString()]));
    }
  }

  /// 启用观众麦克风
  ///
  /// 连麦成功后为观众开启麦克风权限和设备。
  Future<void> _enableAudienceMic() async {
    final mic = await ensureAppPermission(
      context,
      Permission.microphone,
      permissionName: '麦克风',
    );
    if (!mic) {
      Toast.showNotificationNow('live_mic_permission_required_for_cohost'.tr());
      return;
    }
    await ref
        .read(liveRoomControllerProvider(widget.roomId, widget.isHost).notifier)
        .toggleMic();
  }

  /// 切换摄像头
  Future<void> _toggleCamera() {
    return ref
        .read(liveRoomControllerProvider(widget.roomId, widget.isHost).notifier)
        .toggleCamera();
  }

  /// 切换麦克风
  Future<void> _toggleMic() {
    return ref
        .read(liveRoomControllerProvider(widget.roomId, widget.isHost).notifier)
        .toggleMic();
  }

  /// 屏幕共享
  Future<void> _shareScreen() {
    return ref
        .read(liveRoomControllerProvider(widget.roomId, widget.isHost).notifier)
        .toggleScreenShare(context);
  }

  /// 同步观众断连状态
  ///
  /// 当观众检测到房间连接断开时，自动提示并离开。
  /// [roomState] 当前房间状态。
  void _syncAudienceDisconnectedState(RoomState roomState) {
    final disconnected = roomState.connectionState.name == 'disconnected';
    if (widget.isHost || !disconnected) {
      _handledAudienceDisconnected = false;
      return;
    }
    if (_handledAudienceDisconnected) return;

    _handledAudienceDisconnected = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Toast.showNotificationNow('live_ended_or_disconnected'.tr());
      unawaited(_leaveRoom());
    });
  }

  /// 构建应用栏
  ///
  /// 桌面端包含拖拽区域和最小化/关闭按钮，移动端显示返回按钮。
  /// [isDesktop] 是否为桌面端。
  AppBar _buildAppBar(bool isDesktop) {
    return AppBar(
      title: Text(widget.isHost ? '正在直播' : '直播间'),
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      centerTitle: DeviceUtil.isRealMobile(),
      leading: isDesktop
          ? null
          : IconButton(
              onPressed: _leaveRoom,
              icon: const Icon(Icons.arrow_back),
            ),
      automaticallyImplyLeading: !isDesktop,
      flexibleSpace: isDesktop
          ? const DragToMoveArea(child: SizedBox.expand())
          : null,
      actions: [
        if (isDesktop) ...[
          IconButton(
            tooltip: 'call_minimize_tooltip'.tr(),
            onPressed: () => windowManager.minimize(),
            icon: const Icon(Icons.minimize),
          ),
          IconButton(
            tooltip: 'call_close_tooltip'.tr(),
            onPressed: _leaveRoom,
            icon: const Icon(Icons.close),
          ),
        ],
      ],
    );
  }

  /// 构建状态内容区域
  ///
  /// 根据异步状态显示加载、错误或已连接内容。
  /// [state] 房间异步状态。
  Widget _buildStateBody(AsyncValue<RoomState> state) {
    return state.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '进入直播失败: $err',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
      data: _buildConnectedBody,
    );
  }

  /// 构建已连接状态内容
  ///
  /// 组装完整的直播间 UI 布局，包括视频画面、房间头部、侧边面板、
  /// 底部控制区域等。
  /// [roomState] 当前房间状态。
  Widget _buildConnectedBody(RoomState roomState) {
    _bindRoomDataListener(roomState.room);
    unawaited(_startInitialMedia());
    _syncAudienceDisconnectedState(roomState);

    final showDesktopSidePanel = DeviceUtil.isRealDesktop();
    final participants = <Participant>[
      if (roomState.room.localParticipant != null)
        roomState.room.localParticipant!,
      ...roomState.remoteParticipants,
    ];

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: Colors.black,
            child: participants.isEmpty
                ? const Center(
                    child: Icon(
                      Icons.live_tv,
                      size: 72,
                      color: Colors.white70,
                    ),
                  )
                : _LiveVideoSurface(
                    participant: participants.first,
                    label: widget.isHost ? '主播画面' : '当前画面',
                  ),
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          right: showDesktopSidePanel ? 364 : 12,
          child: _RoomHeader(
            isHost: widget.isHost,
            roomId: widget.roomId,
            title: widget.title,
            visibility: widget.visibility,
            source: widget.source,
            connectionState: roomState.connectionState.name,
            participantCount: participants.length,
          ),
        ),
        if (showDesktopSidePanel)
          Positioned(
            top: 88,
            right: 12,
            bottom: 12,
            width: 340,
            child: _LiveSidePanel(
              messages: _messages,
              chatController: _chatController,
              isHost: widget.isHost,
              onSend: _sendMessage,
            ),
          ),
        Positioned(
          bottom: 12,
          left: 12,
          right: showDesktopSidePanel ? 364 : 12,
          child: _BottomControlSection(
            isHost: widget.isHost,
            cohostRequests: _cohostRequests.values.toList(),
            cohostRequested: _cohostRequested,
            cohostActive: _cohostActive,
            showMobileChat: !widget.isHost && !showDesktopSidePanel,
            messages: _messages,
            chatController: _chatController,
            onSendMessage: _sendMessage,
            onAcceptCohost: (request) => _respondCohost(request, true),
            onRejectCohost: (request) => _respondCohost(request, false),
            onRequestCohost: _requestCohost,
            onCancelCohostRequest: _cancelCohostRequest,
            onToggleCamera: _toggleCamera,
            onToggleMic: _toggleMic,
            onShareScreen: _shareScreen,
            onLeave: _leaveRoom,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      liveRoomControllerProvider(widget.roomId, widget.isHost),
    );
    final isDesktop = DeviceUtil.isRealDesktop();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(isDesktop),
      body: _buildStateBody(state),
    );
  }
}
