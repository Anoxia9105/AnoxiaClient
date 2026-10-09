import 'dart:async';

import 'package:anoxia/framework/domain/rtp_interval.dart';
import 'package:anoxia/framework/domain/rtp_bitrate.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
// SDK 2.13.1 的统计查询返回这些类型，但入口库未导出。
// ignore: implementation_imports
import 'package:livekit_client/src/stats/stats.dart';

Future<void> showCallDiagnostics(
  BuildContext context,
  Room room,
  Duration? connectionDuration,
) => showDialog<void>(
  context: context,
  builder: (_) => _CallDiagnosticsDialog(
    room: room,
    connectionDuration: connectionDuration,
  ),
);

class _CallDiagnosticsDialog extends StatefulWidget {
  const _CallDiagnosticsDialog({required this.room, this.connectionDuration});
  final Room room;
  final Duration? connectionDuration;
  @override
  State<_CallDiagnosticsDialog> createState() => _CallDiagnosticsDialogState();
}

class _CallDiagnosticsDialogState extends State<_CallDiagnosticsDialog> {
  Timer? _timer;
  final _window = RtpSampleWindow();
  final _bitrates = RtpBitrateWindow(ticksPerSecond: kIsWeb ? 1000 : 1000000);
  final _senders = <String, List<VideoSenderStats>>{};
  final _receivers = <String, VideoReceiverStats>{};
  bool _sampling = false;
  @override
  void initState() {
    super.initState();
    unawaited(_sample());
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      unawaited(_sample());
    });
  }

  Future<void> _sample() async {
    if (_sampling || !mounted) return;
    _sampling = true;
    final senders = <String, List<VideoSenderStats>>{};
    final receivers = <String, VideoReceiverStats>{};
    try {
      final participants = <Participant>[
        if (widget.room.localParticipant != null) widget.room.localParticipant!,
        ...widget.room.remoteParticipants.values,
      ];
      await Future.wait(
        participants
            .expand((participant) => participant.videoTrackPublications)
            .map((publication) async {
              if (publication.muted) return;
              try {
                final track = publication.track;
                if (track is LocalVideoTrack) {
                  senders[publication.sid] = await track.getSenderStats();
                } else if (track is RemoteVideoTrack) {
                  final stats = await track.getReceiverStats();
                  if (stats != null) receivers[publication.sid] = stats;
                }
              } catch (error, stack) {
                debugLog('读取通话诊断统计失败', error, stack);
              }
            }),
      );
      if (!mounted) return;
      setState(() {
        _senders
          ..clear()
          ..addAll(senders);
        _receivers
          ..clear()
          ..addAll(receivers);
      });
    } finally {
      _sampling = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keys = <String>{};
    final bitrateKeys = <String>{};
    final rows = <Widget>[];
    final participants = <Participant>[
      if (widget.room.localParticipant != null) widget.room.localParticipant!,
      ...widget.room.remoteParticipants.values,
    ];
    for (final participant in participants) {
      for (final publication in participant.videoTrackPublications) {
        final track = publication.track;
        if (publication.muted || track == null) continue;
        final values = <String, String>{};
        if (track is LocalVideoTrack) {
          final layers = [...?_senders[publication.sid]];
          layers.sort(
            (a, b) => (b.frameWidth ?? 0).compareTo(a.frameWidth ?? 0),
          );
          values['call_diagnostic_codec'] = track.codec?.toUpperCase() ?? '—';
          double? totalBitrate;
          for (final stats in layers) {
            final key = '${publication.sid}:${stats.streamId}';
            bitrateKeys.add(key);
            final rate = _bitrates.observe(
              key,
              stats.timestamp,
              stats.bytesSent,
            );
            if (rate != null) totalBitrate = (totalBitrate ?? 0) + rate;
          }
          values['call_diagnostic_bitrate'] = _kbps(totalBitrate);
          if (layers.isNotEmpty) {
            final stats = layers.first;
            values['call_diagnostic_resolution'] =
                '${stats.frameWidth ?? '—'} × ${stats.frameHeight ?? '—'}';
            values['call_diagnostic_fps'] = _number(stats.framesPerSecond);
            values['call_diagnostic_rtt'] = stats.roundTripTime == null
                ? '—'
                : '${(stats.roundTripTime! * 1000).round()} ms';
            values['call_diagnostic_implementation'] =
                stats.encoderImplementation ?? '—';
            values['call_diagnostic_limitation'] =
                stats.qualityLimitationReason ?? '—';
          }
        } else if (track is RemoteVideoTrack) {
          final stats = _receivers[publication.sid];
          values['call_diagnostic_bitrate'] = _kbps(null);
          if (stats != null) {
            final key = '${publication.sid}:${stats.streamId}';
            keys.add(key);
            bitrateKeys.add(key);
            values['call_diagnostic_bitrate'] = _kbps(
              _bitrates.observe(key, stats.timestamp, stats.bytesReceived),
            );
            final interval = _window.observe(
              key,
              RtpCounters(
                timestamp: stats.timestamp,
                lost: stats.packetsLost,
                received: stats.packetsReceived,
                dropped: stats.framesDropped,
                decoded: stats.framesDecoded,
              ),
            );
            values['call_diagnostic_codec'] = stats.mimeType ?? '—';
            values['call_diagnostic_resolution'] =
                '${stats.frameWidth ?? '—'} × ${stats.frameHeight ?? '—'}';
            values['call_diagnostic_fps'] = _number(stats.framesPerSecond);
            values['call_diagnostic_loss'] = _percent(interval?.lossRate);
            values['call_diagnostic_drop'] = _percent(interval?.dropRate);
            values['call_diagnostic_implementation'] =
                stats.decoderImplementation ?? '—';
          }
        }
        rows.add(
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${participant.identity} · ${(participant is LocalParticipant ? 'call_diagnostic_send' : 'call_diagnostic_receive').tr()} · '
                    '${(publication.isScreenShare ? 'call_share' : 'call_camera').tr()}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...values.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Text(entry.key.tr())),
                          Expanded(
                            child: SelectableText(
                              entry.value,
                              textAlign: TextAlign.end,
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
    _window.retainOnly(keys);
    _bitrates.retainOnly(bitrateKeys);
    return AlertDialog(
      title: Text('call_diagnostics'.tr()),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'call_diagnostic_connect_time'.tr(
                  args: [
                    widget.connectionDuration?.inMilliseconds.toString() ?? '—',
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'call_diagnostic_hint'.tr(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              if (rows.isEmpty) Text('call_diagnostic_empty'.tr()),
              ...rows,
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('close'.tr()),
        ),
      ],
    );
  }

  static String _number(num? value) => value?.toStringAsFixed(1) ?? '—';
  static String _percent(double? value) =>
      value == null ? '—' : '${(value * 100).toStringAsFixed(1)}%';
  static String _kbps(num? value) => value == null
      ? 'call_diagnostic_sampling'.tr()
      : value >= 1000000
      ? '${(value / 1000000).toStringAsFixed(2)} Mbps'
      : '${(value / 1000).toStringAsFixed(1)} kbps';
}
