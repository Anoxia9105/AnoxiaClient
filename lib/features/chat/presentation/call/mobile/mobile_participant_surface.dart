// 移动端通话参与者画面组件，渲染单个参与者的视频/音频画面。
//
// 支持视频渲染、画面替代占位、麦克风静音指示、说话状态动画、连接质量指示等功能。
import 'dart:async';
import 'dart:convert';
import 'package:hugeicons/hugeicons.dart';

import 'package:anoxia/features/chat/presentation/call/component/participant_screen_share_badge.dart';
import 'package:anoxia/features/chat/presentation/call/component/remote_quality_estimator.dart';
import 'package:anoxia/features/chat/presentation/call/mobile/participant_placeholder.dart';
import 'package:anoxia/features/chat/presentation/call/mobile/participant_status_indicators.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:easy_localization/easy_localization.dart';

/// 移动端参与者画面
///
/// 根据参与者状态渲染视频轨道或头像占位，显示参与者名称、麦克风状态、
/// 说话状态动画和连接质量。使用 [AnimatedContainer] 和 [AnimatedBuilder] 实现平滑过渡。
class MobileParticipantSurface extends StatefulWidget {
  const MobileParticipantSurface({
    super.key,
    required this.participant,
    this.compact = false,
    this.showStatus = true,
    this.fit = VideoViewFit.cover,
    this.borderRadius = 18,
  });

  /// 参与者对象
  final Participant participant;

  /// 是否使用紧凑模式，适用于小窗口或网格布局
  final bool compact;

  /// 是否显示状态指示器（麦克风、连接质量等）
  final bool showStatus;

  /// 视频画面填充模式
  final VideoViewFit fit;

  /// 画面圆角半径
  final double borderRadius;

  @override
  State<MobileParticipantSurface> createState() =>
      _MobileParticipantSurfaceState();
}

/// 移动端参与者画面状态
///
/// 监听参与者事件（说话状态、音视频轨道变更等），管理说话动画控制器，
/// 并实时更新参与者画面渲染。
class _MobileParticipantSurfaceState extends State<MobileParticipantSurface>
    with SingleTickerProviderStateMixin {
  EventsListener<ParticipantEvent>? _listener;
  late final AnimationController _speakingController;

  /// 服务端 unknown 时的本地下行估算兜底。
  ConnectionQuality? _estimatedQuality;
  Timer? _qualityTimer;
  bool _estimating = false;

  @override
  void initState() {
    super.initState();
    _speakingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    _subscribe(widget.participant);
    _maybeStartEstimator(immediate: true);
    _syncSpeakingAnimation();
  }

  @override
  void didUpdateWidget(covariant MobileParticipantSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.participant != widget.participant) {
      _listener?.dispose();
      _stopEstimator();
      _subscribe(widget.participant);
    }
    _maybeStartEstimator();
    _syncSpeakingAnimation();
  }

  void _subscribe(Participant participant) {
    _listener = participant.createListener()
      ..on<SpeakingChangedEvent>((_) => _refresh())
      ..on<ParticipantConnectionQualityUpdatedEvent>((_) => _onQualityChanged())
      ..on<TrackMutedEvent>((_) => _refresh())
      ..on<TrackUnmutedEvent>((_) => _refresh())
      ..on<TrackPublishedEvent>((_) => _refresh())
      ..on<TrackUnpublishedEvent>((_) => _refresh())
      ..on<TrackSubscribedEvent>((_) {
        _refresh();
        _maybeStartEstimator(immediate: true);
      })
      ..on<TrackUnsubscribedEvent>((_) {
        _refresh();
        _maybeStartEstimator(immediate: true);
      });
  }

  void _onQualityChanged() {
    if (!mounted) return;
    if (widget.participant.connectionQuality != ConnectionQuality.unknown) {
      _stopEstimator();
    } else {
      _maybeStartEstimator();
    }
    _refresh();
  }

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

  (ConnectionQuality quality, bool estimated) _effectiveQuality() {
    final ConnectionQuality server = widget.participant.connectionQuality;
    if (server != ConnectionQuality.unknown) return (server, false);
    final ConnectionQuality? e = _estimatedQuality;
    if (e != null && e != ConnectionQuality.unknown) return (e, true);
    return (ConnectionQuality.unknown, false);
  }

  void _refresh() {
    if (!mounted) return;
    _syncSpeakingAnimation();
    setState(() {});
  }

  void _syncSpeakingAnimation() {
    if (widget.participant.isSpeaking) {
      if (!_speakingController.isAnimating) {
        _speakingController.repeat(reverse: true);
      }
    } else {
      _speakingController.stop();
      _speakingController.value = 0;
    }
  }

  /// 正在共享屏幕的轨道（未静音），优先于摄像头显示。
  ///
  /// 与桌面端 [ParticipantTile] 一致：有人共享时就展示共享画面。
  /// 依赖 `track != null` 判断可用轨道：远端订阅成功才有 track，
  /// 本端（LocalParticipant）发布的轨道 track 恒存在，无需 `subscribed`。
  VideoTrack? _screenShareTrack() {
    return widget.participant.videoTrackPublications
        .where(
          (publication) =>
              publication.isScreenShare &&
              !publication.muted &&
              publication.track is VideoTrack,
        )
        .map((publication) => publication.track)
        .whereType<VideoTrack>()
        .firstOrNull;
  }

  /// 是否正在展示屏幕共享画面（用于顶部共享标签）。
  bool get _isScreenSharing => _screenShareTrack() != null;

  VideoTrack? _visibleTrack() {
    final screen = _screenShareTrack();
    if (screen != null) return screen;

    return widget.participant.videoTrackPublications
        .where(
          (publication) =>
              !publication.isScreenShare &&
              !publication.muted &&
              publication.track is VideoTrack,
        )
        .map((publication) => publication.track)
        .whereType<VideoTrack>()
        .firstOrNull;
  }

  ({String name, String? avatar}) _participantMeta() {
    try {
      final metadata = jsonDecode(widget.participant.metadata ?? '{}');
      if (metadata is Map<String, dynamic>) {
        return (
          name: metadata['nickName']?.toString() ?? widget.participant.identity,
          avatar: metadata['avatar']?.toString(),
        );
      }
    } catch (_) {}
    return (name: widget.participant.identity, avatar: null);
  }

  @override
  void dispose() {
    _listener?.dispose();
    _qualityTimer?.cancel();
    _speakingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final participant = widget.participant;
    final track = _visibleTrack();
    final meta = _participantMeta();
    final isMuted = !participant.isMicrophoneEnabled();
    final (ConnectionQuality signalQuality, bool signalEstimated) =
        _effectiveQuality();
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _speakingController,
      builder: (context, child) {
        final speakingStrength = participant.isSpeaking
            ? 0.45 + (_speakingController.value * 0.55)
            : 0.0;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            // 主题卡片底（跟随浅色/深色主题）
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: participant.isSpeaking
                  ? cs.primary
                  : cs.onSurface.withValues(alpha: 0.1),
              width: participant.isSpeaking ? 2.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: participant.isSpeaking
                    ? cs.primary.withValues(alpha: 0.18 * speakingStrength)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: participant.isSpeaking ? 18 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (track != null)
                VideoTrackRenderer(track, fit: widget.fit)
              else
                ParticipantPlaceholder(
                  name: meta.name,
                  avatar: meta.avatar,
                  compact: widget.compact,
                ),
              if (track != null)
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0x99000000)],
                      stops: [0.58, 1],
                    ),
                  ),
                ),
              if (widget.showStatus)
                Positioned(
                  top: widget.compact ? 6 : 10,
                  right: widget.compact ? 6 : 10,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusPill(
                        compact: widget.compact,
                        color: isMuted
                            ? const Color(0xFFE45B64)
                            : participant.isSpeaking
                            ? const Color(0xFF42D392)
                            : Colors.black54,
                        child: participant.isSpeaking && !isMuted
                            ? SpeakingWaves(
                                progress: _speakingController.value,
                                compact: widget.compact,
                              )
                            : HugeIcon(
                                icon: isMuted
                                    ? HugeIcons.strokeRoundedMicOff01
                                    : HugeIcons.strokeRoundedMic01,
                                size: widget.compact ? 12 : 15,
                                color: Colors.white,
                              ),
                      ),
                      SizedBox(width: widget.compact ? 4 : 6),
                      ConnectionQualityIcon(
                        quality: signalQuality,
                        compact: widget.compact,
                        estimated: signalEstimated,
                      ),
                    ],
                  ),
                ),
              // 屏幕共享标签：有人共享时在视频区域顶部标识共享者
              if (_isScreenSharing)
                Positioned(
                  top: widget.compact ? 6 : 10,
                  left: widget.compact ? 6 : 10,
                  child: ParticipantScreenShareBadge(
                    name: meta.name,
                    compact: widget.compact,
                  ),
                ),
              Positioned(
                left: widget.compact ? 8 : 12,
                right: 8,
                bottom: widget.compact ? 6 : 10,
                child: Text(
                  participant is LocalParticipant
                      ? '${meta.name}${'call_me_label'.tr()}'
                      : meta.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    // 视频上有黑色渐变压底，用白字；无视频（主题卡片底）用主题文字色
                    color: track != null ? Colors.white : cs.onSurface,
                    fontSize: widget.compact ? 10 : 13,
                    fontWeight: FontWeight.w600,
                    shadows: track != null
                        ? const [Shadow(color: Colors.black, blurRadius: 5)]
                        : null,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
