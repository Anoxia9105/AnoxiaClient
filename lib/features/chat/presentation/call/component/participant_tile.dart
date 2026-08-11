import 'dart:convert';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/features/chat/presentation/call/component/participant_signal_icon.dart';
import 'package:anoxia/features/chat/presentation/call/component/participant_more_menu.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:easy_localization/easy_localization.dart';

/// 通话参与者磁贴组件
///
/// 显示单个通话参与者的视频画面和信息，包括：
/// - 视频画面（摄像头或屏幕共享）
/// - 参与者头像（无视频时显示）
/// - 参与者昵称
/// - 静音状态图标
/// - 网络信号强度
/// - 举手状态标识
/// - 操作菜单（静音他人、踢出参与者）
class ParticipantTile extends StatefulWidget {
  /// 参与者实例（本地或远端）
  final Participant participant;

  /// 是否举手
  final bool handRaised;

  /// 点击"静音"时触发，传入目标参与者 identity
  final void Function(String identity)? onMute;

  /// 点击"踢出"时触发，传入目标参与者 identity
  final void Function(String identity)? onKick;
  final VoidCallback? onTap;

  const ParticipantTile({
    super.key,
    required this.participant,
    this.handRaised = false,
    this.onMute,
    this.onKick,
    this.onTap,
  });

  @override
  State<ParticipantTile> createState() => _ParticipantTileState();
}

class _ParticipantTileState extends State<ParticipantTile> {
  /// 监听参与者事件，变化时触发 rebuild
  EventsListener<ParticipantEvent>? _participantListener;

  @override
  void initState() {
    super.initState();
    _subscribeParticipant(widget.participant);
  }

  @override
  void didUpdateWidget(covariant ParticipantTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.participant != widget.participant) {
      _participantListener?.dispose();
      _subscribeParticipant(widget.participant);
    }
  }

  /// 订阅参与者事件
  ///
  /// 监听说话状态、轨道静音/取消静音、轨道发布/取消发布等事件
  void _subscribeParticipant(Participant p) {
    _participantListener = p.createListener();
    _participantListener!
      ..on<SpeakingChangedEvent>((_) {
        if (mounted) setState(() {});
      })
      ..on<TrackMutedEvent>((_) {
        if (mounted) setState(() {});
      })
      ..on<TrackUnmutedEvent>((_) {
        if (mounted) setState(() {});
      })
      ..on<TrackPublishedEvent>((_) {
        if (mounted) setState(() {});
      })
      ..on<TrackUnpublishedEvent>((_) {
        if (mounted) setState(() {});
      })
      ..on<TrackSubscribedEvent>((_) {
        if (mounted) setState(() {});
      })
      ..on<TrackUnsubscribedEvent>((_) {
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _participantListener?.dispose();
    super.dispose();
  }

  /// 计算当前应该显示哪个视频轨道
  ///
  /// 优先级：屏幕共享 > 摄像头
  VideoTrack? _getVisibleVideoTrack() {
    final screenPub = widget.participant.videoTrackPublications
        .where((pub) => pub.isScreenShare && !pub.muted && pub.subscribed)
        .firstOrNull;

    if (screenPub?.track != null && screenPub?.track is VideoTrack) {
      return screenPub!.track as VideoTrack;
    }

    final cameraPub = widget.participant.videoTrackPublications
        .where((pub) => !pub.isScreenShare && !pub.muted && pub.subscribed)
        .firstOrNull;

    if (cameraPub?.track != null && cameraPub?.track is VideoTrack) {
      return cameraPub!.track as VideoTrack;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.participant;
    final track = _getVisibleVideoTrack();

    Map<String, dynamic> meta = {};
    try {
      if (p.metadata != null && p.metadata!.isNotEmpty) {
        meta = jsonDecode(p.metadata!);
      }
    } catch (_) {}

    final nickName = meta['nickName'] ?? p.identity ?? 'Unknown';
    final avatarUrl = meta['avatar'] ?? '';
    final isSpeaking = p.isSpeaking;
    final isCurrentUser = p is LocalParticipant;
    final isMuted = p.isMicrophoneEnabled() == false;

    final displayName = nickName;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSpeaking
                ? Colors.blueAccent
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.1),
            width: isSpeaking ? 2.0 : 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (track != null)
                VideoTrackRenderer(track, fit: VideoViewFit.contain)
              else
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AvatarWidget(size: 36, url: avatarUrl, name: nickName),
                    ],
                  ),
                ),

              /// 举手状态标识
              if (widget.handRaised)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('✋', style: TextStyle(fontSize: 20)),
                  ),
                ),

              /// 参与者信息和操作菜单（桌面端及 Web 端显示）
              if (DeviceUtil.isRealDesktop() || DeviceUtil.isWeb)
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isMuted)
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedMicOff01,
                            size: 16,
                            color: Colors.white,
                          )
                        else
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedMic01,
                            size: 16,
                            color: Colors.white,
                          ),
                        const SizedBox(width: 4),
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        buildParticipantSignalIcon(p),
                        if (!isCurrentUser)
                          Builder(
                            builder: (btnCtx) => IconButton(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(2),
                              tooltip: 'call_more_tooltip'.tr(),
                              onPressed: () => showParticipantMoreMenu(
                                btnCtx,
                                identity: p.identity,
                                onMute: widget.onMute ?? (_) {},
                                onKick: widget.onKick ?? (_) {},
                              ),
                              icon: const HugeIcon(
                                icon: HugeIcons.strokeRoundedMoreHorizontal,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}