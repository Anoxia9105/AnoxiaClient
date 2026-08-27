// 通话邀请浮层组件，根据不同的通话邀请阶段显示对应的 UI。
//
// - 桌面端（真实桌面）：来电阶段不渲染应用内弹窗，改为系统通知（右上角），
//   用户通过通知的接听/拒绝动作处理；呼出振铃由独立通话窗口展示；
//   其余阶段（忙线/取消/被拒等）保留轻量提示。
// - 手机端：1:1 来电显示全屏来电页，呼出显示全屏振铃页；
//   群呼邀请是「通知式」卡片（可加入/忽略）。
// - Web 端：来电保留顶部非遮挡横条（可接听/拒绝），呼出显示全屏振铃页；
//   真实桌面端与 Web PC 宽屏模式来电为右上角卡片通知。
import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/framework/provider/chat/call/call_invitation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'call_invitation_pages.dart';
import 'call_invitation_widgets.dart';

/// 通话邀请浮层
///
/// 监听 [callInvitationControllerProvider] 获取当前邀请状态，
/// 根据 [CallInvitationPhase] 切换展示不同的 UI。
class CallInvitationOverlay extends ConsumerWidget {
  const CallInvitationOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitation = ref.watch(callInvitationControllerProvider);
    if (invitation == null) return const SizedBox.shrink();

    // 最小化态：只渲染可拖拽悬浮窗，不拦截整屏触摸；
    // 点击小窗恢复全屏邀请页。
    if (invitation.minimized) {
      return Stack(
        children: [
          Positioned(
            left: invitation.position.dx,
            top: invitation.position.dy,
            child: MinimizedInvitationBubble(invitation: invitation),
          ),
        ],
      );
    }

    return switch (invitation.phase) {
      CallInvitationPhase.incoming =>
        // 1:1 手机端全屏来电；真实桌面 + Web PC 宽屏用右上角卡片通知；
        // 真实手机 + Web 移动窄屏用顶部横条。桌面端另由 app.dart 触发系统来电通知，两者并存
        (DeviceUtil.isRealMobile() && !invitation.isGroup)
            ? IncomingCallPage(invitation: invitation)
            : IncomingCallBanner(
                invitation: invitation,
                alignTopRight:
                    DeviceUtil.supportsDesktopLayoutPreference(context),
              ),
      CallInvitationPhase.outgoing => (DeviceUtil.isRealDesktop() ||
              invitation.isGroup)
          ? const SizedBox.shrink()
          : OutgoingCallPage(invitation: invitation),
      CallInvitationPhase.acceptedElsewhere => const CallNoticeCard(
        text: 'call_answered_elsewhere',
      ),
      CallInvitationPhase.rejectedElsewhere => const CallNoticeCard(
        text: 'call_rejected_elsewhere',
      ),
      CallInvitationPhase.rejected => const CallNoticeCard(
        text: 'call_rejected_by_peer',
      ),
      CallInvitationPhase.canceled => const CallNoticeCard(
        text: 'call_invitation_cancelled',
      ),
      CallInvitationPhase.busy => const CallNoticeCard(text: 'call_peer_busy'),
      CallInvitationPhase.ended => const CallNoticeCard(text: 'call_ended'),
    };
  }
}
