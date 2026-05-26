import 'package:anoxia/features/chat/presentation/call/desktop/room_layout/layout_room_widget.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:floating/floating.dart'; // 💡 引入系统画中画
import 'package:flutter_floating/flutter_floating.dart'; // 💡 引入应用内悬浮窗
import 'package:livekit_client/livekit_client.dart';
import 'package:anoxia/framework/domain/RoomState.dart';

class CallMobileRoomBody extends ConsumerStatefulWidget {
  final RoomState roomState;
  final String token;

  const CallMobileRoomBody({
    super.key,
    required this.roomState,
    required this.token,
  });

  @override
  ConsumerState<CallMobileRoomBody> createState() => _CallMobileRoomBodyState();
}

class _CallMobileRoomBodyState extends ConsumerState<CallMobileRoomBody> {
  late final Floating _systemPip;

  @override
  void initState() {
    super.initState();
    _systemPip = Floating();
    _setupSystemPiP();
  }

  /// 💡 场景 1：手机触发系统 Home 键或返回手势切到手机桌面时，由系统自动激活 Android 原生 PiP
  Future<void> _setupSystemPiP() async {
    final canUsePiP = await _systemPip.isPipAvailable;
    if (canUsePiP) {
      // 当应用因为系统手势离开前台时，自动开启 9:16 的系统画中画
      await _systemPip.enable(const OnLeavePiP(aspectRatio: Rational(9, 16)));
    }
  }

  @override
  void dispose() {
    // 退出通话时，一定要取消切后台开启 PiP 的监听，防止内存泄漏和后续误触发
    _systemPip.cancelOnLeavePiP();
    super.dispose();
  }

  /// 💡 场景 2：用户在 App 内部点击“缩小”按钮，退出当前路由并激活应用内浮窗
  void _minimizeToInAppFloating() {
    const String floatingKey = 'call_min_window';
    
    // 1. 修改全局状态机为最小化状态
    ref.read(mobileCallSessionControllerProvider.notifier).minimize();

    // 2. 使用 flutter_floating 官方 API：检查并全局创建应用内悬浮窗
    if (!floatingManager.containsFloating(floatingKey)) {
      floatingManager.createFloating(
        floatingKey,
        FloatingOverlay(
          // 这里可以挂载你写好的极简小窗（如：InAppCallMinWindow）
          const Center(
            child: Icon(Icons.call, color: Colors.greenAccent, size: 32),
          ), 
          slideType: FloatingEdgeType.onRightAndTop,
          right: 16,
          top: 150,
        ),
      );
    }
    
    // 3. 打开并显示应用内小窗
    floatingManager.getFloating(floatingKey).open(context);

    // 4. 安全退出全屏通话页面
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final participants = <Participant>[
      if (widget.roomState.room.localParticipant != null)
        widget.roomState.room.localParticipant!,
      ...widget.roomState.remoteParticipants,
    ];

    // 💡 官方标准解法：使用 PiPSwitcher 自动在“全屏”与“系统小窗”间流转 UI
    return PiPSwitcher(
      // ─── 🎬 状况 A：当 Android 原生系统小窗【开启】时渲染的极简画面 ───
      childWhenEnabled: Scaffold(
        backgroundColor: Colors.black,
        body: participants.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : LayoutRoomWidget(
                participants: participants,
                handRaiseMap: const {},
              ),
      ),
      
      // ─── 📱 状况 B：当系统小窗【关闭】（即正常的 App 内全屏状态）渲染的完整 UI ───
      childWhenDisabled: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 1. 铺满全屏的音视频流渲染底层
            Positioned.fill(
              child: participants.isEmpty
                  ? const Center(
                      child: Text(
                        '等待加入...',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : LayoutRoomWidget(
                      participants: participants,
                      handRaiseMap: widget.roomState.handRaiseMap ?? {},
                    ),
            ),

            // 2. 左上角：点击触发 App 内部缩小的控制按钮
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 28),
                onPressed: _minimizeToInAppFloating, // 💡 触发应用内缩小
              ),
            ),

            // 3. 屏幕底部：通话功能常驻控制栏
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 挂断按钮
                  FloatingActionButton(
                    heroTag: 'mobile_hangup',
                    backgroundColor: Colors.red,
                    onPressed: () {
                      // 彻底挂断：断开 LiveKit 并在状态机中销毁 Session
                      ref.read(roomControllerProvider(widget.token).notifier).kickParticipant('');
                      ref.read(mobileCallSessionControllerProvider.notifier).end();
                      
                      // 确保应用内可能残留的悬浮窗被清理
                      if (floatingManager.containsFloating('call_min_window')) {
                        floatingManager.disposeFloating('call_min_window');
                      }
                      
                      Navigator.of(context).maybePop();
                    },
                    child: const Icon(Icons.call_end, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}