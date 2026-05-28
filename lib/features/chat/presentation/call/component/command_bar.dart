import 'package:anoxia/common/widgets/BubbleDialog.dart';
import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/framework/domain/RoomState.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:anoxia/features/chat/presentation/call/component/volume_indicator.dart';
import 'package:bot_toast/bot_toast.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:pip/pip.dart';
import 'package:window_manager/window_manager.dart';

/// 通话命令栏组件
///
/// 提供通话过程中的控制按钮，包括：
/// - 麦克风开关及设备选择
/// - 摄像头开关及设备选择
/// - 扬声器开关及设备选择
/// - 举手功能
/// - 表情反应
/// - 历史记录面板
/// - 屏幕共享
/// - 挂断按钮
class CommandBar extends ConsumerWidget {
  /// 房间状态
  final RoomState state;

  const CommandBar({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 只监听 isInPipMode 字段，减少重建
    final inPip = ref.watch(
      mobileCallSessionControllerProvider.select(
        (s) => s?.isInPipMode ?? false,
      ),
    );

    // PiP 模式下隐藏整个命令栏，避免被 PiP 捕获
    if (inPip) {
      return const SizedBox.shrink();
    }

    final notifier = ref.read(roomControllerProvider(state.token).notifier);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          MeetingTimer(joinedAt: state.joinedAt),

          const SizedBox(width: 8),

          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Builder(
                      builder: (context) {
                        return _splitButton(
                          context: context,
                          icon: state.micEnabled
                              ? HugeIcons.strokeRoundedMic01
                              : HugeIcons.strokeRoundedMicOff01,
                          label: 'call_microphone'.tr(),
                          active: state.micEnabled,
                          onTap: () => notifier.toggleMic(),
                          onArrowTap: () =>
                              _showAudioInputMenu(context, notifier, state),
                        );
                      },
                    ),
                    const SizedBox(width: 4),

                    Builder(
                      builder: (context) {
                        return _splitButton(
                          context: context,
                          icon: state.cameraEnabled
                              ? HugeIcons.strokeRoundedVideo01
                              : HugeIcons.strokeRoundedVideoOff,
                          label: 'call_camera'.tr(),
                          active: state.cameraEnabled,
                          onTap: () => notifier.toggleCamera(),
                          onArrowTap: () =>
                              _showVideoInputMenu(context, notifier, state),
                        );
                      },
                    ),
                    const SizedBox(width: 4),

                    Builder(
                      builder: (context) {
                        return _splitButton(
                          context: context,
                          icon: state.speakerOn
                              ? HugeIcons.strokeRoundedVolumeUp
                              : HugeIcons.strokeRoundedVolumeOff,
                          label: state.speakerOn
                              ? 'call_speaker'.tr()
                              : 'call_earpiece'.tr(),
                          active: state.speakerOn,
                          onTap: () => notifier.toggleSpeaker(),
                          onArrowTap: () =>
                              _showAudioOutputMenu(context, notifier, state),
                        );
                      },
                    ),
                    const SizedBox(width: 8),

                    _soloButton(
                      context: context,
                      icon: HugeIcons.strokeRoundedHold03,
                      label: '举手',
                      active:
                          state.handRaiseMap?[state
                              .room
                              .localParticipant
                              ?.identity] ==
                          true,
                      onTap: () {
                        final uid = state.room.localParticipant?.identity ?? '';
                        final isRaised = state.handRaiseMap?[uid] == true;
                        notifier.sendHandRaise(!isRaised);
                      },
                    ),
                    const SizedBox(width: 2),

                    Builder(
                      builder: (context) => _soloButton(
                        context: context,
                        icon: HugeIcons.strokeRoundedRubberDuck,
                        label: '表情',
                        active: false,
                        onTap: () =>
                            _showReactionPicker(context, notifier, state),
                      ),
                    ),

                    const SizedBox(width: 2),

                    _soloButton(
                      context: context,
                      icon: state.screenSharing
                          ? HugeIcons.strokeRoundedComputerRemove
                          : HugeIcons.strokeRoundedComputerScreenShare,
                      label: 'call_share'.tr(),
                      active: state.screenSharing,
                      onTap: () => notifier.toggleScreenShare(context),
                    ),
                    const SizedBox(width: 8),

                    _buildHangupButton(context, ref, notifier),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示表情选择器
  void _showReactionPicker(
    BuildContext context,
    RoomController notifier,
    RoomState state,
  ) {
    const emojis = ['👍', '❤️', '😂', '😮', '👏', '🎉', '🔥', '💯'];

    Function? close;
    close = Toast.showWidget(
      context,
      direction: PreferDirection.topRight,
      child: Material(
        color: Colors.transparent,
        child: BubbleWidget(
          arrowDirection: AxisDirection.up,
          arrowOffset: 410,
          backgroundColor: Theme.of(context).colorScheme.surface,
          border: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
          contentBuilder: (context) => Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              children: emojis.map((emoji) {
                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    notifier.sendReaction(emoji);
                    close?.call();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建分裂按钮（左侧功能按钮 + 右侧下拉箭头）
  ///
  /// 用于需要设备选择功能的控制按钮，如麦克风、摄像头、扬声器
  Widget _splitButton({
    required VoidCallback onTap,
    required VoidCallback onArrowTap,
    required List<List<dynamic>> icon,
    required String label,
    required BuildContext context,
    bool active = false,
  }) {
    final color = active ? Theme.of(context).colorScheme.primary : null;
    final dividerColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.15);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: dividerColor, width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: label,
                child: InkWell(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    child: HugeIcon(icon: icon, size: 18, color: color),
                  ),
                ),
              ),
              VerticalDivider(width: 1, thickness: 0.5, color: dividerColor),
              SizedBox(
                height: double.infinity,
                child: InkWell(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                  onTap: onArrowTap,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.keyboard_arrow_down_rounded, size: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建单体按钮（无下拉菜单）
  ///
  /// 用于简单的开关功能，如举手、表情、屏幕共享
  Widget _soloButton({
    required VoidCallback onTap,
    required List<List<dynamic>> icon,
    required String label,
    required BuildContext context,
    bool active = false,
  }) {
    final color = active ? Theme.of(context).colorScheme.primary : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.15),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Tooltip(
          message: label,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: HugeIcon(icon: icon, size: 18, color: color),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建挂断按钮
  ///
  /// 点击后离开房间，桌面端关闭窗口，移动端通过将全局状态机置空来销毁浮层
  Widget _buildHangupButton(
    BuildContext context,
    WidgetRef ref,
    RoomController notifier,
  ) {
    return Tooltip(
      message: 'call_hangup'.tr(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          onTap: () async {
            if (DeviceUtil.isRealDesktop()) {
              windowManager.close();
            } else {
              // ─── 🚀 大厂架构核心防御 ───
              try {
                // 1. 显式调用插件的释放方法，安全注销原生层的 Home 键拦截与资源占用
                await Pip().dispose();
              } catch (e) {
                debugPrint('PiP dispose error: $e');
              }
              ref.read(mobileCallSessionControllerProvider.notifier).end();
            }

            // 后台异步断开并清理当前 LiveKit 房间连接
            notifier.leave();
          },
          borderRadius: BorderRadius.circular(10),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedCallRinging03,
              size: 18,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  /// 显示音频输入设备选择菜单
  void _showAudioInputMenu(
    BuildContext context,
    RoomController notifier,
    RoomState state,
  ) {
    _showDeviceMenu(
      context: context,
      items: state.audioInputs
          .map(
            (d) => _DeviceMenuItem(
              label: d.label,
              selected: state.currentAudioInput?.deviceId == d.deviceId,
              onTap: () => notifier.switchAudioInput(d),
            ),
          )
          .toList(),
      footer: state.room.localParticipant != null
          ? _LocalVolumeFooter(localParticipant: state.room.localParticipant!)
          : null,
    );
  }

  /// 显示视频输入设备选择菜单
  void _showVideoInputMenu(
    BuildContext context,
    RoomController notifier,
    RoomState state,
  ) {
    _showDeviceMenu(
      context: context,
      items: state.videoInputs
          .map(
            (d) => _DeviceMenuItem(
              label: d.label,
              selected: state.currentVideoInput?.deviceId == d.deviceId,
              onTap: () => notifier.switchVideoInput(d),
            ),
          )
          .toList(),
    );
  }

  /// 显示音频输出设备选择菜单
  void _showAudioOutputMenu(
    BuildContext context,
    RoomController notifier,
    RoomState state,
  ) {
    _showDeviceMenu(
      context: context,
      items: state.audioOutputs
          .map(
            (d) => _DeviceMenuItem(
              label: d.label,
              selected: state.currentAudioOutput?.deviceId == d.deviceId,
              onTap: () => notifier.switchAudioOutput(d),
            ),
          )
          .toList(),
    );
  }

  /// 显示设备选择菜单
  ///
  /// [items] 设备列表项
  /// [footer] 底部附加组件（如麦克风音量指示器）
  void _showDeviceMenu({
    required BuildContext context,
    required List<_DeviceMenuItem> items,
    Widget? footer,
  }) {
    if (items.isEmpty) return;

    Function? close;
    close = Toast.showWidget(
      context,
      direction: PreferDirection.topRight,
      child: Material(
        color: Colors.transparent,
        child: BubbleWidget(
          arrowDirection: AxisDirection.up,
          arrowOffset: 280,
          backgroundColor: Theme.of(context).colorScheme.surface,
          border: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
          contentBuilder: (context) => SizedBox(
            width: 300,
            height: 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0; i < items.length; i++) ...[
                          ListTile(
                            dense: true,
                            onTap: () {
                              items[i].onTap();
                              close?.call();
                            },
                            selected: items[i].selected,
                            leading: Icon(
                              items[i].selected
                                  ? Icons.check
                                  : Icons.circle_outlined,
                              size: 16,
                              color: items[i].selected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                            ),
                            title: Text(
                              items[i].label,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 4,
                              style: TextStyle(
                                fontSize: 13,
                                color: items[i].selected
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                            ),
                          ),
                          if (i < items.length - 1) const Divider(height: 1),
                        ],
                      ],
                    ),
                  ),
                ),
                if (footer != null) ...[
                  Divider(
                    height: 1,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  footer,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 设备菜单项数据
class _DeviceMenuItem {
  /// 设备名称
  final String label;

  /// 是否选中
  final bool selected;

  /// 点击回调
  final VoidCallback onTap;

  const _DeviceMenuItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });
}

/// 本地音量指示器底部组件
///
/// 在麦克风设备选择菜单底部显示实时音量
class _LocalVolumeFooter extends StatefulWidget {
  /// 本地参与者实例
  final LocalParticipant localParticipant;

  const _LocalVolumeFooter({required this.localParticipant});

  @override
  State<_LocalVolumeFooter> createState() => _LocalVolumeFooterState();
}

class _LocalVolumeFooterState extends State<_LocalVolumeFooter> {
  Timer? _timer;
  double _volume = 0.0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      final v = widget.localParticipant.audioLevel;
      if ((v - _volume).abs() > 0.005) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _volume = v);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mic,
            size: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          VolumeIndicator(volume: _volume),
        ],
      ),
    );
  }
}

/// 会议计时器组件
///
/// 显示当前通话已持续的时间，从加入房间开始计时
class MeetingTimer extends StatefulWidget {
  /// 加入房间的时间
  final DateTime? joinedAt;

  const MeetingTimer({super.key, required this.joinedAt});

  @override
  State<MeetingTimer> createState() => _MeetingTimerState();
}

class _MeetingTimerState extends State<MeetingTimer> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.joinedAt != null) {
      _elapsed = DateTime.now().difference(widget.joinedAt!);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _elapsed = DateTime.now().difference(widget.joinedAt!);
        });
      });
    }
  }

  @override
  void didUpdateWidget(covariant MeetingTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.joinedAt != widget.joinedAt) {
      _timer?.cancel();
      if (widget.joinedAt != null) {
        _elapsed = DateTime.now().difference(widget.joinedAt!);
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          setState(() {
            _elapsed = DateTime.now().difference(widget.joinedAt!);
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 格式化时长显示
  ///
  /// 超过1小时显示 HH:MM:SS，否则显示 MM:SS
  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.joinedAt == null) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: HugeIcons.strokeRoundedTime01, size: 20),
          Text('--:--', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_fmt(_elapsed), style: const TextStyle(fontSize: 12)),
        Text('call_elapsed'.tr(), style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
