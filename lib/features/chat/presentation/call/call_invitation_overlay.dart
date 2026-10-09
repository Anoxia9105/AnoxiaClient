// 通话邀请浮层组件，根据不同的通话邀请阶段显示对应的 UI。
//
// - 桌面端：来电显示居中卡片，并保留系统通知；呼出由独立窗口展示；
//   其余阶段（忙线/取消/被拒等）保留轻量提示。
// - 手机端：1:1 来电显示全屏来电页，呼出显示全屏振铃页；
//   群呼邀请是「通知式」卡片（可加入/忽略）。
// - Web 端：私聊来电显示居中卡片，群呼保留非阻塞邀请；呼出显示全屏页。
import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/framework/provider/chat/call/call_invitation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'call_invitation_pages.dart';
import 'call_invitation_widgets.dart';
import 'component/incoming_call_prompt.dart';

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
      CallInvitationPhase.incoming => _buildIncoming(context, invitation),
      CallInvitationPhase.outgoing =>
        (DeviceUtil.isRealDesktop() || invitation.isGroup)
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

  /// 来电阶段 UI 分流
  ///
  /// - 真实手机 1:1：全屏来电页；
  /// - 桌面/Web 私聊：标题栏下方居中卡片，窄窗口可滚动；
  /// - 群呼：顶部居中邀请卡片，不阻塞页面操作。
  Widget _buildIncoming(BuildContext context, CallInvitationState invitation) {
    if (DeviceUtil.isRealMobile() && !invitation.isGroup) {
      return IncomingCallPage(invitation: invitation);
    }
    return IncomingCallPrompt(invitation: invitation);
  }
}
