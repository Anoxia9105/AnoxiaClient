import 'package:anoxia/common/widgets/BubbleDialog.dart';
import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/framework/domain/RoomState.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/chat/call/history_panel_provider.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:anoxia/features/chat/presentation/call/component/volume_indicator.dart';
import 'package:bot_toast/bot_toast.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:window_manager/window_manager.dart';

class CommandBar extends ConsumerWidget {
  final RoomState state;

  const CommandBar({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(roomControllerProvider(state.token).notifier);
    final historyNotifier = ref.read(historyPanelProvider.notifier);
    final historyActive = ref.watch(historyPanelProvider);

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
                    // 麦克风：split button
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

                    // 摄像头：split button
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

                    // 扬声器：split button
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

                    // 握手：solo button
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

                    // 表情按钮（点击弹出表情选择）
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
                    //历史记录
                    Builder(
                      builder: (context) => _soloButton(
                        context: context,
                        icon: HugeIcons.strokeRoundedTransactionHistory,
                        label: '历史',
                        active: historyActive, // ← provider 状态
                        onTap: () => historyNotifier.toggle(), // ← 直接 toggle
                      ),
                    ),

                    const SizedBox(width: 2),
                    // 屏幕共享：solo button
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

                    // 挂断
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
  // ──────────────────────────────────────────
  // 组合分裂按钮
  // ──────────────────────────────────────────

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
              // 左半：功能
              Tooltip(
                message: label,
                child: InkWell(
                  borderRadius: BorderRadius.only(
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
              // 分割线
              VerticalDivider(width: 1, thickness: 0.5, color: dividerColor),
              // 右半：下拉
              SizedBox(
                height: double.infinity,
                child: InkWell(
                  borderRadius: BorderRadius.only(
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

  // ──────────────────────────────────────────
  // 单体按钮（无下拉）
  // ──────────────────────────────────────────

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

  // ──────────────────────────────────────────
  // 挂断按钮
  // ──────────────────────────────────────────

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
            await notifier.leave();
            if (context.mounted) {
              if (DeviceUtil.isRealDesktop()) {
                await windowManager.close();
              } else {
                ref.read(mobileCallSessionControllerProvider.notifier).end();
                Navigator.of(context).maybePop();
              }
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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

  // ──────────────────────────────────────────
  // 设备选择菜单（弹出式）
  // ──────────────────────────────────────────

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
            // 1. 最外层强制固定宽高
            width: 300,
            height: 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  // 2. 列表部分占满剩余空间，支持内部滚动
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
                  // 3. Footer 自然固定在底部
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

// ──────────────────────────────────────────
// 内部数据类
// ──────────────────────────────────────────

class _DeviceMenuItem {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DeviceMenuItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });
}

// ──────────────────────────────────────────
// 麦克风弹框底部实时音量指示器
// ──────────────────────────────────────────

class _LocalVolumeFooter extends StatefulWidget {
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

// ──────────────────────────────────────────
// 会议计时器（不变）
// ──────────────────────────────────────────

class MeetingTimer extends StatefulWidget {
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
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: HugeIcons.strokeRoundedTime01, size: 20),
          const Text(
            '--:--',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
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
