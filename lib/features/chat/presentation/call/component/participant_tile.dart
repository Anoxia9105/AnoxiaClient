import 'dart:async';
import 'dart:convert';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/features/chat/presentation/call/component/participant_screen_share_badge.dart';
import 'package:anoxia/features/chat/presentation/call/component/participant_signal_icon.dart';
import 'package:anoxia/features/chat/presentation/call/component/remote_quality_estimator.dart';
import 'package:anoxia/features/chat/presentation/call/component/participant_more_menu.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

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

  /// 视频画面填充模式，默认 contain（保持宽高比，可能有黑边）
  final VideoViewFit fit;

  /// 磁贴内容区底色，默认主题卡片色（surfaceContainerLow，跟随主题）。
  ///
  /// 屏幕共享主画面可传 [Colors.black]，让 contain 信箱边与视频黑底融合，
  /// 而外层布局仍跟随主题。
  final Color? backgroundColor;

  /// 磁贴圆角，默认 lg（12，卡片风格）；共享主画面内层等可用 md（8）。
  final double borderRadius;

  /// 是否移除外层 4px 边距，用于屏幕共享主画面等需要恰好填满容器的场景
  final bool removePadding;

  const ParticipantTile({
    super.key,
    required this.participant,
    this.handRaised = false,
    this.onMute,
    this.onKick,
    this.onTap,
    this.fit = VideoViewFit.contain,
    this.backgroundColor,
    this.borderRadius = RadiusToken.lg,
    this.removePadding = false,
  });

  @override
  State<ParticipantTile> createState() => _ParticipantTileState();
}

class _ParticipantTileState extends State<ParticipantTile> {
  /// 监听参与者事件，变化时触发 rebuild
  EventsListener<ParticipantEvent>? _participantListener;

  /// 服务端质量长期 unknown 时的本地下行估算值（下行视角兜底）。
  ConnectionQuality? _estimatedQuality;

  /// 估算轮询定时器，仅远端 + 服务端 unknown 时运行。
  Timer? _qualityTimer;
  bool _estimating = false;

  @override
  void initState() {
    super.initState();
    _subscribeParticipant(widget.participant);
    _maybeStartEstimator(immediate: true);
  }

  @override
  void didUpdateWidget(covariant ParticipantTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.participant != widget.participant) {
      _participantListener?.dispose();
      _stopEstimator();
      _subscribeParticipant(widget.participant);
    }
    _maybeStartEstimator();
  }

  /// 订阅参与者事件
  ///
  /// 监听说话状态、轨道静音/取消静音、轨道发布/取消发布等事件。
  /// 连接质量事件（服务端转发对方上行质量）必须监听，否则远端信号条
  /// 收不到更新会一直卡在 unknown（本地因更新频繁恰好能被父重建带上）。
  void _subscribeParticipant(Participant p) {
    _participantListener = p.createListener();
    _participantListener!
      ..on<SpeakingChangedEvent>((_) {
        if (mounted) setState(() {});
      })
      ..on<ParticipantConnectionQualityUpdatedEvent>((_) {
        _onQualityChanged();
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
        _maybeStartEstimator(immediate: true);
      })
      ..on<TrackUnsubscribedEvent>((_) {
        if (mounted) setState(() {});
        _maybeStartEstimator(immediate: true);
      });
  }

  void _onQualityChanged() {
    if (!mounted) return;
    // 服务端恢复已知：停掉估算，清除旧估算值。
    if (widget.participant.connectionQuality != ConnectionQuality.unknown) {
      _stopEstimator();
    } else {
      _maybeStartEstimator();
    }
    setState(() {});
  }

  /// 服务端 unknown 且为远端时启动下行估算轮询；服务端恢复已知时停掉。
  void _maybeStartEstimator({bool immediate = false}) {
    if (widget.participant is! RemoteParticipant ||
        widget.participant.connectionQuality != ConnectionQuality.unknown) {
      _stopEstimator();
      return;
    }
    _qualityTimer ??= Timer.periodic(
      const Duration(seconds: 3),
      (_) => _runEstimation(),
    );
    if (immediate) _runEstimation();
  }

  Future<void> _runEstimation() async {
    if (_estimating || !mounted) return;
    final Participant p = widget.participant;
    if (p is! RemoteParticipant) return;
    if (p.connectionQuality != ConnectionQuality.unknown) {
      _stopEstimator();
      return;
    }
    _estimating = true;
    try {
      final ConnectionQuality? q =
          await RemoteQualityEstimator.estimateRemoteDownlinkQuality(p);
      if (!mounted) return;
      if (q != _estimatedQuality) {
        setState(() => _estimatedQuality = q);
      }
    } finally {
      _estimating = false;
    }
  }

  void _stopEstimator() {
    _qualityTimer?.cancel();
    _qualityTimer = null;
    _estimatedQuality = null;
  }

  /// 服务端优先，unknown 时用本地估算兜底。
  (ConnectionQuality quality, bool estimated) _effectiveQuality() {
    final ConnectionQuality server = widget.participant.connectionQuality;
    if (server != ConnectionQuality.unknown) {
      return (server, false);
    }
    final ConnectionQuality? e = _estimatedQuality;
    if (e != null && e != ConnectionQuality.unknown) {
      return (e, true);
    }
    return (ConnectionQuality.unknown, false);
  }

  @override
  void dispose() {
    _participantListener?.dispose();
    _qualityTimer?.cancel();
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

  /// 是否正在展示屏幕共享画面（用于顶部「正在共享」标签）。
  bool _isSharingScreen() {
    final screenPub = widget.participant.videoTrackPublications
        .where((pub) => pub.isScreenShare && !pub.muted && pub.subscribed)
        .firstOrNull;
    return screenPub?.track is VideoTrack;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.participant;
    final track = _getVisibleVideoTrack();
    final isSharingScreen = _isSharingScreen();

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
    final (ConnectionQuality signalQuality, bool signalEstimated) =
        _effectiveQuality();

    final cs = Theme.of(context).colorScheme;
    final tileContent = Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: isSpeaking
              ? cs.primary
              : cs.onSurface.withValues(alpha: 0.1),
          width: isSpeaking ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (track != null)
              VideoTrackRenderer(track, fit: widget.fit)
            else
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AvatarWidget(size: 56, url: avatarUrl, name: nickName),
                      const SizedBox(height: 8),
                      Text(
                        displayName,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
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
                      borderRadius: BorderRadius.circular(RadiusToken.sm),
                    ),
                    child: const Text('✋', style: TextStyle(fontSize: 20)),
                  ),
                ),

              /// 屏幕共享标签：有人共享时在视频区域顶部标识共享者
              if (isSharingScreen)
                Positioned(
                  top: 8,
                  left: 8,
                  child: ParticipantScreenShareBadge(name: displayName),
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
                      borderRadius: BorderRadius.circular(RadiusToken.sm),
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
                        buildParticipantSignalIconFromQuality(
                          signalQuality,
                          estimated: signalEstimated,
                        ),
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
      );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // 纯头像（无可见视频轨道）不可点击：点击头像不切换视图，
      // 上层聚焦逻辑同样会忽略无画面的参与者，这里直接置空以去掉点击手势。
      onTap: track != null ? widget.onTap : null,
      child: widget.removePadding
          ? tileContent
          : Padding(padding: const EdgeInsets.all(4), child: tileContent),
    );
  }
}