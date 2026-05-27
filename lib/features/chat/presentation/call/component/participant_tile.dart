import 'dart:convert';
import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/common/widgets/BubbleDialog.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';

/// 根据参与者连接质量构建信号强度图标
///
/// 根据不同的连接质量显示不同颜色和信号条数量：
/// - 优秀/良好：绿色，3格信号
/// - 较差：橙色，2格信号
/// - 丢失：红色，1格信号
/// - 未知：灰色，0格信号
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
  /// 当前应该显示的视频轨道
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

  /// 弹出"更多"操作菜单
  ///
  /// 提供静音和踢出功能（仅对远端参与者显示）
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

              /// 参与者信息和操作菜单（仅桌面显示）
              if (DeviceUtil.isRealDesktop())
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
                              tooltip: '更多',
                              onPressed: () =>
                                  _showMoreMenu(btnCtx, p.identity),
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

/// 更多菜单项数据
class _MoreMenuItem {
  /// 图标
  final List<List<dynamic>> icon;

  /// 图标颜色
  final Color? iconColor;

  /// 标签文字
  final String label;

  /// 标签颜色
  final Color? labelColor;

  /// 点击回调
  final VoidCallback onTap;

  const _MoreMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });
}
