import 'package:anoxia/common/utils/device_util.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/domain/room_state.dart';
import 'package:anoxia/framework/provider/chat/call/call_invitation_controller.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/chat/call/call_initial_media.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:anoxia/features/chat/presentation/call/component/call_invite_members_button.dart';
import 'package:anoxia/features/chat/presentation/call/component/meeting_timer.dart';
import 'package:anoxia/features/chat/presentation/call/component/device_menu.dart';
import 'package:anoxia/features/chat/presentation/call/component/call_control_buttons.dart';
import 'package:anoxia/features/chat/presentation/call/component/window_screen_select_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:anoxia/platform/shims/pip_shim.dart';
import 'package:anoxia/platform/shims/window_manager_shim.dart';
import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:anoxia/framework/logs/debug_log.dart';

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

    // 屏幕共享开关的真实方向：以本地实际发布的屏幕共享轨道为准。
    // `state.screenSharing` 由 LiveKit 事件驱动，在「刚发布」/「系统侧刚停止」
    // 的窗口期会滞后，直接用它会把「停止共享」误判成「开始共享」。
    final isSharingScreen = _isLocalScreenSharing(state);

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
                            context, ref, notifier, state,
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
                            context, ref, notifier, state,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 4),

                    // 扬声器按钮（仅真实移动/桌面端；Web 由系统输出设备决定，
                    // 无听筒/扬声器切换概念）
                    if (!DeviceUtil.isWeb)
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
                              context, ref, notifier, state,
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
                      icon: isSharingScreen
                          ? HugeIcons.strokeRoundedComputerRemove
                          : HugeIcons.strokeRoundedComputerScreenShare,
                      label: isSharingScreen
                          ? 'call_share_stop'.tr()
                          : 'call_share'.tr(),
                      active: isSharingScreen,
                      onTap: () => _toggleScreenShare(
                        context,
                        notifier,
                        sharing: isSharingScreen,
                      ),
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
          borderRadius: BorderRadius.circular(RadiusToken.lg),
        ),
        child: InkWell(
          onTap: () async {
            if (DeviceUtil.isRealDesktop()) {
              // 桌面端：CALL_END 统一由窗口关闭回调发出（onWindowClose
              // → on_call_window_close），避免与挂断后关窗重复发送。
              windowManager.close();
            } else {
              ref
                  .read(callInvitationControllerProvider.notifier)
                  .endRoom(state.room.name ?? '');
              try {
                await Pip().dispose();
              } catch (e) {
                debugLog('PiP dispose error: $e');
              }
              ref.read(mobileCallSessionControllerProvider.notifier).end();
            }

            notifier.leave();
          },
          borderRadius: BorderRadius.circular(RadiusToken.lg),
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
  ///
  /// 打开前先刷新设备列表，确保 Web 端拿到授权后的完整设备名称
  Future<void> _showAudioInputMenu(
    BuildContext context,
    WidgetRef ref,
    RoomController notifier,
    RoomState state,
  ) async {
    await notifier.refreshDevices();
    if (!context.mounted) return;
    final fresh =
        ref.read(roomControllerProvider(state.token)).value ?? state;
    showDeviceMenu(
      context: context,
      title: 'call_microphone'.tr(),
      icon: HugeIcons.strokeRoundedMic01,
      items: _buildDeviceItems(
        fresh.audioInputs,
        fresh.currentAudioInput,
        notifier.switchAudioInput,
      ),
      footer: fresh.room.localParticipant != null
          ? LocalVolumeFooter(localParticipant: fresh.room.localParticipant!)
          : null,
    );
  }

  /// 显示视频输入设备选择菜单
  Future<void> _showVideoInputMenu(
    BuildContext context,
    WidgetRef ref,
    RoomController notifier,
    RoomState state,
  ) async {
    await notifier.refreshDevices();
    if (!context.mounted) return;
    final fresh =
        ref.read(roomControllerProvider(state.token)).value ?? state;
    showDeviceMenu(
      context: context,
      title: 'call_camera'.tr(),
      icon: HugeIcons.strokeRoundedVideo01,
      items: _buildDeviceItems(
        fresh.videoInputs,
        fresh.currentVideoInput,
        notifier.switchVideoInput,
      ),
    );
  }

  /// 显示音频输出设备选择菜单
  Future<void> _showAudioOutputMenu(
    BuildContext context,
    WidgetRef ref,
    RoomController notifier,
    RoomState state,
  ) async {
    await notifier.refreshDevices();
    if (!context.mounted) return;
    final fresh =
        ref.read(roomControllerProvider(state.token)).value ?? state;
    showDeviceMenu(
      context: context,
      title: 'call_speaker'.tr(),
      icon: HugeIcons.strokeRoundedVolumeUp,
      items: _buildDeviceItems(
        fresh.audioOutputs,
        fresh.currentAudioOutput,
        notifier.switchAudioOutput,
      ),
    );
  }

  /// 构建设备菜单项列表
  ///
  /// 设备名称为空时（浏览器未授权）显示"设备 N"兜底文案
  List<DeviceMenuItem> _buildDeviceItems(
    List<MediaDevice> devices,
    MediaDevice? current,
    void Function(MediaDevice) onSelect,
  ) {
    return [
      for (var i = 0; i < devices.length; i++)
        DeviceMenuItem(
          label: devices[i].label.trim().isEmpty
              ? '${'call_device_label'.tr()} ${i + 1}'
              : devices[i].label,
          selected: current?.deviceId == devices[i].deviceId,
          onTap: () => onSelect(devices[i]),
        ),
    ];
  }
}

/// 本地是否正在共享屏幕（以实际发布的屏幕共享轨道为准）
///
/// 不看 `state.screenSharing` 单一字段：该字段由事件驱动更新，存在滞后窗口，
/// 会让「停止共享」误走「开始共享」分支。没有本地参与者时回退到状态字段。
bool _isLocalScreenSharing(RoomState state) {
  final localParticipant = state.room.localParticipant;
  if (localParticipant == null) return state.screenSharing;
  return localParticipant.videoTrackPublications.any(
    (publication) => publication.isScreenShare && !publication.muted,
  );
}

/// 切换屏幕共享
///
/// - 正在共享中（[sharing] 为 true）：直接停止，**不再弹出屏幕源选择框**。
///   历史 Bug：此处无脑弹框，用户点「取消共享」看到选择框、再点弹窗的
///   "取消"后 sourceId 为 null 直接 return，结果共享一直停不掉。
/// - 未共享：桌面端先弹出窗口/屏幕选择对话框，选中后传入屏幕源 ID；
///   用户取消选择时直接终止，不触发共享。
Future<void> _toggleScreenShare(
  BuildContext context,
  RoomController notifier, {
  required bool sharing,
}) async {
  if (sharing) {
    await notifier.stopScreenShare();
    return;
  }

  String? sourceId;
  if (DeviceUtil.isRealDesktop()) {
    if (!context.mounted) return;
    sourceId = await showDesktopScreenSourcePicker(context);
    // 用户在系统弹窗中取消选择：终止本次共享，不产生任何副作用
    if (sourceId == null) return;
  }
  await notifier.startScreenShare(sourceId: sourceId);
}