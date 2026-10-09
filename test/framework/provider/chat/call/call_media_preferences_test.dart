import 'package:anoxia/framework/domain/call_media_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart';

void main() {
  test('共享采集与发布帧率保持一致，流畅档允许 30 FPS', () {
    for (final quality in ScreenShareQuality.values) {
      final settings = CallMediaPreferences(screenQuality: quality);
      expect(
        settings.screenCaptureOptions().maxFrameRate,
        settings.screenPublishOptions('vp8').screenShareEncoding!.maxFramerate,
      );
    }
    expect(
      const CallMediaPreferences(
        screenQuality: ScreenShareQuality.motion,
      ).screenCaptureOptions().maxFrameRate,
      30,
    );
  });

  test('文字保分辨率，视频演示保帧率', () {
    expect(
      const CallMediaPreferences()
          .screenPublishOptions('vp8')
          .degradationPreference,
      DegradationPreference.maintainResolution,
    );
    expect(
      const CallMediaPreferences(
        screenQuality: ScreenShareQuality.motion,
      ).screenPublishOptions('vp8').degradationPreference,
      DegradationPreference.maintainFramerate,
    );
  });

  test('未知或不支持的编码器回退到本机可用编码器', () {
    expect(selectVideoCodec(VideoCodecPreference.av1, {'vp8', 'h264'}), 'vp8');
    expect(selectVideoCodec(VideoCodecPreference.vp9, {'vp9', 'vp8'}), 'vp9');
    expect(selectVideoCodec(VideoCodecPreference.automatic, {'h264'}), 'h264');
    expect(
      selectVideoCodec(VideoCodecPreference.automatic, {
        'h264',
        'vp8',
      }, preferHardwareCodec: true),
      'h264',
    );
  });

  test('过期设置按兼容默认值恢复，设置可序列化', () {
    expect(
      CallMediaPreferences.fromJson({'screenQuality': 'old'}).screenQuality,
      ScreenShareQuality.detail,
    );
    const settings = CallMediaPreferences(
      screenQuality: ScreenShareQuality.motion,
      cameraQuality: CameraQuality.high,
      screenCodec: VideoCodecPreference.vp9,
      shareAudio: true,
    );
    final restored = CallMediaPreferences.fromJson(settings.toJson());
    expect(restored.toJson(), settings.toJson());
  });
}
