import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/framework/domain/room_state.dart';
import 'package:anoxia/framework/provider/chat/call/call_invitation_controller.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/chat/call/call_initial_media.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:anoxia/features/chat/presentation/call/component/call_invite_members_button.dart';
import 'package:anoxia/features/chat/presentation/call/component/meeting_timer.dart';
import 'package:anoxia/features/chat/presentation/call/component/device_menu.dart';
import 'package:anoxia/features/chat/presentation/call/component/call_control_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hugeicons/hugeicons.dart';
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
    final roomId = state.room.name ?? '';
    final isGroup = ref.watch(callIsGroupProvider(roomId));

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
                    // 麦克风按钮
                    Builder(
                      builder: (context) {
                        return buildSplitButton(
                          context: context,
                          icon: state.micEnabled
                              ? HugeIcons.strokeRoundedMic01
                              : HugeIcons.strokeRoundedMicOff01,
                          label: 'call_microphone'.tr(),
                          active: state.micEnabled,
                          onTap: () => notifier.toggleMic(),
                          onArrowTap: () => _showAudioInputMenu(
                            context, notifier, state,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 4),

                    // 摄像头按钮
                    Builder(
                      builder: (context) {
                        return buildSplitButton(
                          context: context,
                          icon: state.cameraEnabled
                              ? HugeIcons.strokeRoundedVideo01
                              : HugeIcons.strokeRoundedVideoOff,
                          label: 'call_camera'.tr(),
                          active: state.cameraEnabled,
                          onTap: () => notifier.toggleCamera(),
                          onArrowTap: () => _showVideoInputMenu(
                            context, notifier, state,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 4),

                    // 扬声器按钮
                    Builder(
                      builder: (context) {
                        return buildSplitButton(
                          context: context,
                          icon: state.speakerOn
                              ? HugeIcons.strokeRoundedVolumeUp
                              : HugeIcons.strokeRoundedVolumeOff,
                          label: state.speakerOn
                              ? 'call_speaker'.tr()
                              : 'call_earpiece'.tr(),
                          active: state.speakerOn,
                          onTap: () => notifier.toggleSpeaker(),
                          onArrowTap: () => _showAudioOutputMenu(
                            context, notifier, state,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),

                    // 举手按钮
                    buildSoloButton(
                      context: context,
                      icon: HugeIcons.strokeRoundedHold03,
                      label: 'call_hand_raise'.tr(),
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

                    // 表情按钮
                    Builder(
                      builder: (context) => buildSoloButton(
                        context: context,
                        icon: HugeIcons.strokeRoundedRubberDuck,
                        label: 'call_reaction'.tr(),
                        active: false,
                        onTap: () => showReactionPicker(
                          context,
                          (emoji) => notifier.sendReaction(emoji),
                        ),
                      ),
                    ),

                    const SizedBox(width: 2),

                    if (isGroup) ...[
                      CallInviteMembersButton(state: state),
                      const SizedBox(width: 2),
                    ],

                    // 屏幕共享按钮
                    buildSoloButton(
                      context: context,
                      icon: state.screenSharing
                          ? HugeIcons.strokeRoundedComputerRemove
                          : HugeIcons.strokeRoundedComputerScreenShare,
                      label: 'call_share'.tr(),
                      active: state.screenSharing,
                      onTap: () => notifier.toggleScreenShare(context),
                    ),
                    const SizedBox(width: 8),

                    // 挂断按钮
                    _buildHangupButton(context, ref, notifier, state),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建挂断按钮
  Widget _buildHangupButton(
    BuildContext context,
    WidgetRef ref,
    RoomController notifier,
    RoomState state,
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
            ref
                .read(callInvitationControllerProvider.notifier)
                .endRoom(state.room.name ?? '');
            if (DeviceUtil.isRealDesktop()) {
              windowManager.close();
            } else {
              try {
                await Pip().dispose();
              } catch (e) {
                debugPrint('PiP dispose error: $e');
              }
              ref.read(mobileCallSessionControllerProvider.notifier).end();
            }

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
    showDeviceMenu(
      context: context,
      items: state.audioInputs
          .map(
            (d) => DeviceMenuItem(
              label: d.label,
              selected: state.currentAudioInput?.deviceId == d.deviceId,
              onTap: () => notifier.switchAudioInput(d),
            ),
          )
          .toList(),
      footer: state.room.localParticipant != null
          ? LocalVolumeFooter(localParticipant: state.room.localParticipant!)
          : null,
    );
  }

  /// 显示视频输入设备选择菜单
  void _showVideoInputMenu(
    BuildContext context,
    RoomController notifier,
    RoomState state,
  ) {
    showDeviceMenu(
      context: context,
      items: state.videoInputs
          .map(
            (d) => DeviceMenuItem(
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
    showDeviceMenu(
      context: context,
      items: state.audioOutputs
          .map(
            (d) => DeviceMenuItem(
              label: d.label,
              selected: state.currentAudioOutput?.deviceId == d.deviceId,
              onTap: () => notifier.switchAudioOutput(d),
            ),
          )
          .toList(),
    );
  }
}