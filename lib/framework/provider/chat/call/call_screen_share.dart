import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:livekit_client/livekit_client.dart';

/// 一次共享拥有视频与可选声音轨道，任何发布失败都回收整次采集。
class CallScreenShare {
  CallScreenShare(
    this.participant, {
    Future<List<LocalTrack>> Function(ScreenShareCaptureOptions)? capture,
  }) : _capture = capture ?? _captureTracks;

  final LocalParticipant participant;
  final Future<List<LocalTrack>> Function(ScreenShareCaptureOptions) _capture;
  List<LocalTrack> _tracks = [];

  LocalVideoTrack? get video =>
      _tracks.whereType<LocalVideoTrack>().firstOrNull;
  bool get hasAudio => _tracks.any((track) => track is LocalAudioTrack);

  static Future<List<LocalTrack>> _captureTracks(
    ScreenShareCaptureOptions options,
  ) async {
    if (options.captureScreenAudio) {
      return LocalVideoTrack.createScreenShareTracksWithAudio(options);
    }
    return [await LocalVideoTrack.createScreenShareTrack(options)];
  }

  Future<void> start(
    ScreenShareCaptureOptions captureOptions,
    VideoPublishOptions publishOptions, {
    void Function()? ensureOpen,
  }) async {
    if (_tracks.isNotEmpty) return;
    try {
      _tracks = await _capture(captureOptions);
      for (final track in _tracks) {
        ensureOpen?.call();
        if (track is LocalVideoTrack) {
          await participant.publishVideoTrack(
            track,
            publishOptions: publishOptions,
          );
        } else if (track is LocalAudioTrack) {
          await participant.publishAudioTrack(track);
        }
      }
      if (video == null) throw StateError('没有可共享的视频轨道');
    } catch (_) {
      try {
        await stop();
      } catch (error, stack) {
        debugLog('共享失败后的轨道清理失败', error, stack);
      }
      rethrow;
    }
  }

  /// 同时撤销共享画面和声音；清理单条失败也继续处理其余轨道。
  Future<void> stop() async {
    Object? failure;
    StackTrace? failureStack;
    final publications =
        [
              ...participant.videoTrackPublications,
              ...participant.audioTrackPublications,
            ]
            .where(
              (pub) =>
                  pub.source == TrackSource.screenShareVideo ||
                  pub.source == TrackSource.screenShareAudio,
            )
            .toList();
    for (final publication in publications) {
      try {
        await participant.removePublishedTrack(publication.sid);
      } catch (error, stack) {
        failure ??= error;
        failureStack ??= stack;
      }
    }
    final tracks = _tracks;
    _tracks = [];
    for (final track in tracks) {
      try {
        await track.dispose();
      } catch (error, stack) {
        failure ??= error;
        failureStack ??= stack;
      }
    }
    if (failure != null) Error.throwWithStackTrace(failure, failureStack!);
  }
}
