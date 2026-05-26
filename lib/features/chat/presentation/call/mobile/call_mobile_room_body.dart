import 'package:anoxia/features/chat/presentation/call/component/command_bar.dart'; // 💡 引入你的命令控制栏
import 'package:anoxia/features/chat/presentation/call/desktop/room_layout/layout_room_carousel_widget.dart';
import 'package:anoxia/features/chat/presentation/call/desktop/room_layout/layout_room_screen_widget.dart';
import 'package:anoxia/features/chat/presentation/call/desktop/room_layout/layout_room_widget.dart';
import 'package:anoxia/framework/provider/chat/call/LayoutMode.dart';
import 'package:anoxia/framework/provider/chat/call/history_panel_provider.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:floating/floating.dart'; // 💡 系统画中画
import 'package:flutter_floating/flutter_floating.dart'; // 💡 应用内悬浮窗
import 'package:hugeicons/hugeicons.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:anoxia/framework/domain/RoomState.dart';
import 'package:easy_localization/easy_localization.dart';

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

    // 💡 核心修复：必须等待第一帧渲染完成后，再向系统注册切后台自动开启画中画
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupSystemPiP();
    });
  }

  /// 💡 场景 1：手机触发系统 Home 键切到桌面时，由系统自动激活 Android 原生 PiP
  Future<void> _setupSystemPiP() async {
    try {
      final canUsePiP = await _systemPip.isPipAvailable;
      if (canUsePiP) {
        const rational = Rational(9, 16); // 竖屏 9:16
        final status = await _systemPip.enable(
          const OnLeavePiP(aspectRatio: rational),
        );
        debugPrint('--- [PiP 自动开启监听注册状态]: $status ---');
      }
    } catch (e) {
      debugPrint('--- [PiP 错误]: 无法启动画中画监听: $e ---');
    }
  }

  @override
  void dispose() {
    _systemPip.cancelOnLeavePiP();
    super.dispose();
  }

  /// 💡 场景 2：用户在 App 内部点击“缩小”按钮，退出全屏并激活应用内浮窗
  void _minimizeToInAppFloating() {
    const String floatingKey = 'call_min_window';
    ref.read(mobileCallSessionControllerProvider.notifier).minimize();

    if (!floatingManager.containsFloating(floatingKey)) {
      floatingManager.createFloating(
        floatingKey,
        FloatingOverlay(
          const Center(
            child: Icon(Icons.call, color: Colors.greenAccent, size: 32),
          ),
          slideType: FloatingEdgeType.onRightAndTop,
          right: 16,
          top: 150,
        ),
      );
    }

    floatingManager.getFloating(floatingKey).open(context);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // 1. 动态订阅布局模式和聊天记录面板
    final layoutMode = ref.watch(layoutModeProvider(widget.roomState));
    final showHistory = ref.watch(historyPanelProvider);

    // 2. 组装房间成员数据
    final participants = <Participant>[
      if (widget.roomState.room.localParticipant != null)
        widget.roomState.room.localParticipant!,
      ...widget.roomState.remoteParticipants,
    ];

    // 3. 检测是否有屏幕共享者
    final screenSharer = participants
        .where((p) => p.videoTrackPublications.any((pub) => pub.isScreenShare))
        .firstOrNull;

    // 4. 获取控制器方法引用
    final notifier = ref.read(roomControllerProvider(widget.token).notifier);
    void onMute(String identity) => notifier.sendMuteCommand(identity, true);
    void onKick(String identity) => notifier.kickParticipant(identity);

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

      // ─── 📱 状况 B：正常全屏状态（融合 CommandBar 控制功能） ───
      childWhenDisabled: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Column(
            children: [
              // 💡 顶部条：放置一个缩小返回按钮和房间状态
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedMinimizeScreen,
                        size: 22,
                      ),
                      onPressed: _minimizeToInAppFloating,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '通话房间',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              // 💡 中间核心区域：视频排版 + 侧边历史面板
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: participants.isEmpty
                          ? Center(child: Text('call_waiting_to_join'.tr()))
                          : _buildLayout(
                              mode: layoutMode,
                              participants: participants,
                              screenSharer: screenSharer,
                              handRaiseMap: widget.roomState.handRaiseMap ?? {},
                              onMute: onMute,
                              onKick: onKick,
                            ),
                    ),
                    // 历史面板
                    if (showHistory)
                      _HistoryPanel(history: widget.roomState.reactions ?? []),
                  ],
                ),
              ),

              // 💡 底部控制条：直接复用你在 win 写的成熟控制中心组件（里面包含了音视频开关、挂断、共享屏幕等所有功能）
              CommandBar(state: widget.roomState),
            ],
          ),
        ),
      ),
    );
  }

  /// 根据布局模式构建对应的布局组件（对齐你的 CallRoomPage 逻辑）
  Widget _buildLayout({
    required LayoutMode mode,
    required List<Participant> participants,
    required Participant? screenSharer,
    required Map<String, bool> handRaiseMap,
    void Function(String identity)? onMute,
    void Function(String identity)? onKick,
  }) {
    return switch (mode) {
      LayoutMode.grid => LayoutRoomWidget(
        participants: participants,
        handRaiseMap: handRaiseMap,
        onMute: onMute,
        onKick: onKick,
      ),
      LayoutMode.focus => LayoutRoomScreenWidget(
        screenParticipant: screenSharer!,
        otherParticipants: participants
            .where((p) => p.sid != screenSharer.sid)
            .toList(),
        handRaiseMap: handRaiseMap,
        onMute: onMute,
        onKick: onKick,
      ),
      LayoutMode.carousel => LayoutRoomCarouselWidget(
        participants: participants,
        handRaiseMap: handRaiseMap,
        onMute: onMute,
        onKick: onKick,
      ),
    };
  }
}

/// ─── 历史记录面板组件桥接 ───
class _HistoryPanel extends ConsumerWidget {
  final List<ReactionItem> history;
  const _HistoryPanel({required this.history});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      width: 240, // 移动端稍微收窄一点宽度
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          AppBar(
            title: const Text('聊天记录', style: TextStyle(fontSize: 14)),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () =>
                    ref.read(historyPanelProvider.notifier).close(),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                return ListTile(
                  dense: true,
                  title: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    item.message,
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
