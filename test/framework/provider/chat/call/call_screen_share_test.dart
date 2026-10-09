import 'package:anoxia/framework/provider/chat/call/call_screen_share.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart';

class _Video extends Fake implements LocalVideoTrack {
  bool stopped = false;
  @override
  Future<bool> stop() async {
    stopped = true;
    return true;
  }

  @override
  Future<bool> dispose() async {
    stopped = true;
    return true;
  }
}

class _Audio extends Fake implements LocalAudioTrack {
  bool stopped = false;
  @override
  Future<bool> stop() async {
    stopped = true;
    return true;
  }

  @override
  Future<bool> dispose() async {
    stopped = true;
    return true;
  }
}

class _VideoPublication extends Fake
    implements LocalTrackPublication<LocalVideoTrack> {
  @override
  String get sid => 'video';
  @override
  TrackSource get source => TrackSource.screenShareVideo;
}

class _AudioPublication extends Fake
    implements LocalTrackPublication<LocalAudioTrack> {
  @override
  String get sid => 'audio';
  @override
  TrackSource get source => TrackSource.screenShareAudio;
}

class _Participant extends Fake implements LocalParticipant {
  int videoCount = 0;
  int audioCount = 0;
  bool failAudio = false;
  final removed = <String>[];
  final videos = <LocalTrackPublication<LocalVideoTrack>>[];
  final audios = <LocalTrackPublication<LocalAudioTrack>>[];
  @override
  List<LocalTrackPublication<LocalVideoTrack>> get videoTrackPublications =>
      videos;
  @override
  List<LocalTrackPublication<LocalAudioTrack>> get audioTrackPublications =>
      audios;
  @override
  Future<void> removePublishedTrack(
    String trackSid, {
    bool notify = true,
  }) async {
    removed.add(trackSid);
    videos.removeWhere((pub) => pub.sid == trackSid);
    audios.removeWhere((pub) => pub.sid == trackSid);
  }

  @override
  Future<LocalTrackPublication<LocalVideoTrack>> publishVideoTrack(
    LocalVideoTrack track, {
    VideoPublishOptions? publishOptions,
  }) async {
    videoCount++;
    final publication = _VideoPublication();
    videos.add(publication);
    return publication;
  }

  @override
  Future<LocalTrackPublication<LocalAudioTrack>> publishAudioTrack(
    LocalAudioTrack track, {
    AudioPublishOptions? publishOptions,
  }) async {
    if (failAudio) throw StateError('音频发布失败');
    audioCount++;
    final publication = _AudioPublication();
    audios.add(publication);
    return publication;
  }
}

void main() {
  test('授权采集返回时通话已关闭，不发布并回收采集', () async {
    final video = _Video();
    final audio = _Audio();
    final participant = _Participant();
    final session = CallScreenShare(
      participant,
      capture: (_) async => [video, audio],
    );
    await expectLater(
      session.start(
        const ScreenShareCaptureOptions(captureScreenAudio: true),
        const VideoPublishOptions(),
        ensureOpen: () => throw StateError('通话已结束'),
      ),
      throwsStateError,
    );
    expect(participant.videoCount, 0);
    expect(participant.audioCount, 0);
    expect(video.stopped, isTrue);
    expect(audio.stopped, isTrue);
  });
  test('共享音视频都发布，重复停止也会释放全部采集', () async {
    final video = _Video();
    final audio = _Audio();
    final participant = _Participant();
    final session = CallScreenShare(
      participant,
      capture: (_) async => [video, audio],
    );
    await session.start(
      const ScreenShareCaptureOptions(captureScreenAudio: true),
      const VideoPublishOptions(),
    );
    expect(participant.videoCount, 1);
    expect(participant.audioCount, 1);
    await session.stop();
    await session.stop();
    expect(participant.removed, ['video', 'audio']);
    expect(video.stopped, isTrue);
    expect(audio.stopped, isTrue);
  });
  test('发布共享声音失败时回收已经创建的音视频', () async {
    final video = _Video();
    final audio = _Audio();
    final session = CallScreenShare(
      _Participant()..failAudio = true,
      capture: (_) async => [video, audio],
    );
    await expectLater(
      session.start(
        const ScreenShareCaptureOptions(captureScreenAudio: true),
        const VideoPublishOptions(),
      ),
      throwsStateError,
    );
    expect(video.stopped, isTrue);
    expect(audio.stopped, isTrue);
  });
}
