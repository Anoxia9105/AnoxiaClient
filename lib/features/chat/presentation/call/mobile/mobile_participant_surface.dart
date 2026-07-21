import 'dart:convert';

import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

class MobileParticipantSurface extends StatefulWidget {
  const MobileParticipantSurface({
    super.key,
    required this.participant,
    this.compact = false,
    this.showStatus = true,
    this.fit = VideoViewFit.cover,
    this.borderRadius = 18,
  });

  final Participant participant;
  final bool compact;
  final bool showStatus;
  final VideoViewFit fit;
  final double borderRadius;

  @override
  State<MobileParticipantSurface> createState() =>
      _MobileParticipantSurfaceState();
}

class _MobileParticipantSurfaceState extends State<MobileParticipantSurface>
    with SingleTickerProviderStateMixin {
  EventsListener<ParticipantEvent>? _listener;
  late final AnimationController _speakingController;

  @override
  void initState() {
    super.initState();
    _speakingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    _subscribe(widget.participant);
    _syncSpeakingAnimation();
  }

  @override
  void didUpdateWidget(covariant MobileParticipantSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.participant != widget.participant) {
      _listener?.dispose();
      _subscribe(widget.participant);
    }
    _syncSpeakingAnimation();
  }

  void _subscribe(Participant participant) {
    _listener = participant.createListener()
      ..on<SpeakingChangedEvent>((_) => _refresh())
      ..on<TrackMutedEvent>((_) => _refresh())
      ..on<TrackUnmutedEvent>((_) => _refresh())
      ..on<TrackPublishedEvent>((_) => _refresh())
      ..on<TrackUnpublishedEvent>((_) => _refresh())
      ..on<TrackSubscribedEvent>((_) => _refresh())
      ..on<TrackUnsubscribedEvent>((_) => _refresh());
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

  VideoTrack? _visibleTrack() {
    final camera = widget.participant.videoTrackPublications
        .where((publication) => !publication.isScreenShare)
        .where((publication) => !publication.muted && publication.subscribed)
        .map((publication) => publication.track)
        .whereType<VideoTrack>()
        .firstOrNull;
    if (camera != null) return camera;

    return widget.participant.videoTrackPublications
        .where((publication) => publication.isScreenShare)
        .where((publication) => !publication.muted && publication.subscribed)
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
    _speakingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final participant = widget.participant;
    final track = _visibleTrack();
    final meta = _participantMeta();
    final isMuted = !participant.isMicrophoneEnabled();

    return AnimatedBuilder(
      animation: _speakingController,
      builder: (context, child) {
        final speakingStrength = participant.isSpeaking
            ? 0.45 + (_speakingController.value * 0.55)
            : 0.0;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: const Color(0xFF171A22),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: participant.isSpeaking
                  ? Color.lerp(
                      const Color(0xFF56E39F),
                      const Color(0xFFB7FFD9),
                      speakingStrength,
                    )!
                  : Colors.white.withValues(alpha: 0.08),
              width: participant.isSpeaking ? 2.4 : 1,
            ),
            boxShadow: participant.isSpeaking
                ? [
                    BoxShadow(
                      color: const Color(
                        0xFF56E39F,
                      ).withValues(alpha: 0.18 * speakingStrength),
                      blurRadius: 18,
                    ),
                  ]
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (track != null)
                VideoTrackRenderer(track, fit: widget.fit)
              else
                _ParticipantPlaceholder(
                  name: meta.name,
                  avatar: meta.avatar,
                  compact: widget.compact,
                ),
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
                      _StatusPill(
                        compact: widget.compact,
                        color: isMuted
                            ? const Color(0xFFE45B64)
                            : participant.isSpeaking
                            ? const Color(0xFF42D392)
                            : Colors.black54,
                        child: participant.isSpeaking && !isMuted
                            ? _SpeakingWaves(
                                progress: _speakingController.value,
                                compact: widget.compact,
                              )
                            : Icon(
                                isMuted ? Icons.mic_off : Icons.mic,
                                size: widget.compact ? 12 : 15,
                                color: Colors.white,
                              ),
                      ),
                      SizedBox(width: widget.compact ? 4 : 6),
                      _ConnectionQualityIcon(
                        quality: participant.connectionQuality,
                        compact: widget.compact,
                      ),
                    ],
                  ),
                ),
              Positioned(
                left: widget.compact ? 8 : 12,
                right: 8,
                bottom: widget.compact ? 6 : 10,
                child: Text(
                  participant is LocalParticipant
                      ? '${meta.name}（我）'
                      : meta.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: widget.compact ? 10 : 13,
                    fontWeight: FontWeight.w600,
                    shadows: const [Shadow(color: Colors.black, blurRadius: 5)],
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

class _ParticipantPlaceholder extends StatelessWidget {
  const _ParticipantPlaceholder({
    required this.name,
    required this.avatar,
    required this.compact,
  });

  final String name;
  final String? avatar;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF252A38), Color(0xFF11131A)],
        ),
      ),
      child: Center(
        child: AvatarWidget(
          url: avatar,
          name: name,
          size: compact ? 42 : 72,
          borderRadius: compact ? 21 : 36,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.child,
    required this.color,
    required this.compact,
  });

  final Widget child;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 23 : 28,
      height: compact ? 20 : 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: child,
    );
  }
}

class _SpeakingWaves extends StatelessWidget {
  const _SpeakingWaves({required this.progress, required this.compact});

  final double progress;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(3, (index) {
        final phase = (progress + index * 0.24) % 1.0;
        return Container(
          width: compact ? 2 : 2.5,
          height: (compact ? 5 : 7) + phase * (compact ? 5 : 7),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _ConnectionQualityIcon extends StatelessWidget {
  const _ConnectionQualityIcon({required this.quality, required this.compact});

  final ConnectionQuality quality;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (color, bars) = switch (quality) {
      ConnectionQuality.excellent => (const Color(0xFF42D392), 3),
      ConnectionQuality.good => (const Color(0xFF7BD88F), 3),
      ConnectionQuality.poor => (const Color(0xFFFFB454), 2),
      ConnectionQuality.lost => (const Color(0xFFE45B64), 1),
      _ => (Colors.white54, 1),
    };
    return Container(
      height: compact ? 20 : 24,
      padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 7),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(3, (index) {
          final level = index + 1;
          return Container(
            width: compact ? 2 : 2.5,
            height: (compact ? 4 : 5) + level * (compact ? 2 : 2.5),
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: level <= bars ? color : Colors.white24,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }
}
