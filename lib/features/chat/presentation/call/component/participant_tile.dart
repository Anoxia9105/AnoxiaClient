// participant_tile.dart

import 'dart:convert';
import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/common/widgets/BubbleDialog.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';

// local helper to convert quality/rtt to icon
Widget _buildSignalIconForParticipant(Participant p) {
  final quality = p.connectionQuality;

  Color color;
  int level;
  String qualityLabel;

  switch (quality) {
    case ConnectionQuality.lost:
      color = Colors.redAccent;
      level = 1;
      qualityLabel = 'call_quality_lost'.tr();
      break;
    case ConnectionQuality.poor:
      color = Colors.orange;
      level = 2;
      qualityLabel = 'call_quality_poor'.tr();
      break;
    case ConnectionQuality.good:
    case ConnectionQuality.excellent:
      color = Colors.green;
      level = 3;
      qualityLabel = quality == ConnectionQuality.excellent
          ? 'call_quality_excellent'.tr()
          : 'call_quality_good'.tr();
      break;
    default:
      color = Colors.grey;
      level = 0;
      qualityLabel = 'call_quality_unknown'.tr();
  }

  Widget bar(int idx) {
    final active = level >= idx;
    final double h = 4.0 + idx * 3.0;
    return Container(
      width: 2.5,
      height: h,
      margin: const EdgeInsets.symmetric(horizontal: 1.0),
      decoration: BoxDecoration(
        color: active ? color : Colors.white10,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  return Tooltip(
    message: qualityLabel,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [bar(1), bar(2), bar(3)],
      ),
    ),
  );
}

class ParticipantTile extends StatefulWidget {
  final Participant participant;
  final bool handRaised;

  /// 点击"静音"时触发，传入目标参与者 identity
  final void Function(String identity)? onMute;

  /// 点击"踢出"时触发，传入目标参与者 identity
  final void Function(String identity)? onKick;

  const ParticipantTile({
    super.key,
    required this.participant,
    this.handRaised = false,
    this.onMute,
    this.onKick,
  });

  @override
  State<ParticipantTile> createState() => _ParticipantTileState();
}

class _ParticipantTileState extends State<ParticipantTile> {
  // 当前应该显示的视频轨道
  VideoTrack? videoTrack;

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

  /// 计算当前应该显示哪个视频轨道 (屏幕共享 > 摄像头)
  VideoTrack? _getVisibleVideoTrack() {
    // 优先找屏幕共享
    final screenPub = widget.participant.videoTrackPublications
        .where((pub) => pub.isScreenShare && !pub.muted && pub.subscribed)
        .firstOrNull;

    if (screenPub?.track != null && screenPub?.track is VideoTrack) {
      return screenPub!.track as VideoTrack;
    }
    // 2. 其次找摄像头
    final cameraPub = widget.participant.videoTrackPublications
        .where((pub) => !pub.isScreenShare && !pub.muted && pub.subscribed)
        .firstOrNull;

    if (cameraPub?.track != null && cameraPub?.track is VideoTrack) {
      return cameraPub!.track as VideoTrack;
    }

    return null;
  }

  /// 弹出"更多"操作菜单（静音 / 踢出）
  void _showMoreMenu(BuildContext context, String identity) {
    Function? close;

    final items = [
      _MoreMenuItem(
        icon: HugeIcons.strokeRoundedMicOff01,
        iconColor: null,
        label: '静音',
        onTap: () {
          widget.onMute?.call(identity);
          close?.call();
        },
      ),
      _MoreMenuItem(
        icon: HugeIcons.strokeRoundedUserRemove01,
        iconColor: Colors.redAccent,
        label: '踢出',
        labelColor: Colors.redAccent,
        onTap: () {
          widget.onKick?.call(identity);
          close?.call();
        },
      ),
    ];

    close = Toast.showWidget(
      context,
      direction: PreferDirection.topCenter,
      child: Material(
        color: Colors.transparent,
        child: BubbleWidget(
          arrowDirection: AxisDirection.down,
          arrowOffset: 70,
          arrowLength: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          border: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
          contentBuilder: (ctx) => Container(
            constraints: const BoxConstraints(minWidth: 100),
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: items.map((item) {
                return InkWell(
                  onTap: item.onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: item.icon,
                          size: 15,
                          color:
                              item.iconColor ??
                              Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 13,
                            color: item.labelColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.participant;
    final track = _getVisibleVideoTrack();

    // 解析元数据 (头像/昵称)
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

    // 检查是否屏幕共享
    // final isScreenShare = p.videoTrackPublications.any(
    //   (pub) => pub.isScreenShare && !pub.muted && pub.subscribed,
    // );

    // 屏幕共享时显示特殊标签
    // final displayName = isScreenShare ? "$nickName's Screen" : nickName;
    final displayName = nickName;

    return Padding(
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
                      // 使用你的 AvatarWidget
                      AvatarWidget(size: 48, url: avatarUrl, name: nickName),
                    ],
                  ),
                ),
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
                      _buildSignalIconForParticipant(p),
                      if (!isCurrentUser)
                        Builder(
                          builder: (btnCtx) => IconButton(
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(2),
                            tooltip: "更多",
                            onPressed: () => _showMoreMenu(btnCtx, p.identity),
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
    );
  }
}

// ──────────────────────────────────────────
// 内部数据类
// ──────────────────────────────────────────

class _MoreMenuItem {
  final List<List<dynamic>> icon;
  final Color? iconColor;
  final String label;
  final Color? labelColor;
  final VoidCallback onTap;

  const _MoreMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });
}
