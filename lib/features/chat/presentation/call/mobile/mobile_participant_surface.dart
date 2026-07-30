import 'dart:convert';

import 'package:anoxia/features/chat/presentation/call/mobile/participant_placeholder.dart';
import 'package:anoxia/features/chat/presentation/call/mobile/participant_status_indicators.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:easy_localization/easy_localization.dart';

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
                ParticipantPlaceholder(
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
                            : Icon(
                                isMuted ? Icons.mic_off : Icons.mic,
                                size: widget.compact ? 12 : 15,
                                color: Colors.white,
                              ),
                      ),
                      SizedBox(width: widget.compact ? 4 : 6),
                      ConnectionQualityIcon(
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
                      ? '${meta.name}${'call_me_label'.tr()}'
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