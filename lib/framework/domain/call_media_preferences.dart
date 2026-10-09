import 'dart:convert';

import 'package:anoxia/common/constants/storage_keys.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ScreenShareQuality { detail, motion, lowBandwidth }

enum CameraQuality { balanced, high, lowBandwidth }

enum VideoCodecPreference { automatic, vp8, h264, vp9, av1 }

/// 自动模式先保证兼容；仅移动原生端优先请求 H.264。
/// 能力探测不能证明硬件加速，因此不自动选择 AV1/VP9。
String selectVideoCodec(
  VideoCodecPreference preference,
  Set<String> supported, {
  bool preferHardwareCodec = false,
}) {
  if (preference != VideoCodecPreference.automatic &&
      supported.contains(preference.name)) {
    return preference.name;
  }
  final fallback = preferHardwareCodec
      ? ['h264', 'vp8', 'vp9', 'av1']
      : ['vp8', 'h264', 'vp9', 'av1'];
  return fallback.firstWhere(supported.contains, orElse: () => 'vp8');
}

class CallMediaPreferences {
  const CallMediaPreferences({
    this.screenQuality = ScreenShareQuality.detail,
    this.cameraQuality = CameraQuality.balanced,
    this.cameraCodec = VideoCodecPreference.automatic,
    this.screenCodec = VideoCodecPreference.automatic,
    this.shareAudio = false,
  });

  final ScreenShareQuality screenQuality;
  final CameraQuality cameraQuality;
  final VideoCodecPreference cameraCodec;
  final VideoCodecPreference screenCodec;
  final bool shareAudio;

  VideoParameters get screenParameters => switch (screenQuality) {
    ScreenShareQuality.detail => VideoParametersPresets.screenShareH1080FPS15,
    ScreenShareQuality.motion => VideoParametersPresets.screenShareH1080FPS30,
    ScreenShareQuality.lowBandwidth =>
      VideoParametersPresets.screenShareH720FPS15,
  };

  VideoParameters get cameraParameters => switch (cameraQuality) {
    CameraQuality.balanced => VideoParametersPresets.h720_169,
    CameraQuality.high => VideoParametersPresets.h1080_169,
    CameraQuality.lowBandwidth => VideoParametersPresets.h360_169,
  };

  CameraCaptureOptions cameraCaptureOptions({String? deviceId}) =>
      CameraCaptureOptions(
        deviceId: deviceId,
        params: cameraParameters,
        maxFrameRate: cameraParameters.encoding!.maxFramerate.toDouble(),
      );

  ScreenShareCaptureOptions screenCaptureOptions({String? sourceId}) =>
      ScreenShareCaptureOptions(
        sourceId: sourceId,
        captureScreenAudio: shareAudio,
        selfBrowserSurface: 'exclude',
        maxFrameRate: screenParameters.encoding!.maxFramerate.toDouble(),
        params: screenParameters,
      );

  VideoPublishOptions cameraPublishOptions(String codec) => VideoPublishOptions(
    videoCodec: codec,
    videoEncoding: cameraParameters.encoding,
    degradationPreference: DegradationPreference.maintainFramerate,
  );

  VideoPublishOptions screenPublishOptions(String codec) => VideoPublishOptions(
    videoCodec: codec,
    screenShareEncoding: screenParameters.encoding,
    degradationPreference: screenQuality == ScreenShareQuality.motion
        ? DegradationPreference.maintainFramerate
        : DegradationPreference.maintainResolution,
  );

  Map<String, dynamic> toJson() => {
    'screenQuality': screenQuality.name,
    'cameraQuality': cameraQuality.name,
    'cameraCodec': cameraCodec.name,
    'screenCodec': screenCodec.name,
    'shareAudio': shareAudio,
  };

  factory CallMediaPreferences.fromJson(Map<String, dynamic> json) =>
      CallMediaPreferences(
        screenQuality: _readEnum(
          ScreenShareQuality.values,
          json['screenQuality'],
          ScreenShareQuality.detail,
        ),
        cameraQuality: _readEnum(
          CameraQuality.values,
          json['cameraQuality'],
          CameraQuality.balanced,
        ),
        cameraCodec: _readEnum(
          VideoCodecPreference.values,
          json['cameraCodec'],
          VideoCodecPreference.automatic,
        ),
        screenCodec: _readEnum(
          VideoCodecPreference.values,
          json['screenCodec'],
          VideoCodecPreference.automatic,
        ),
        shareAudio: json['shareAudio'] == true,
      );

  static T _readEnum<T extends Enum>(
    List<T> values,
    Object? value,
    T fallback,
  ) => values.firstWhere((item) => item.name == value, orElse: () => fallback);

  static Future<CallMediaPreferences> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // 桌面通话窗口是独立引擎，刷新缓存以读取另一个窗口保存的偏好。
      await prefs.reload();
      final value = prefs.getString(StorageKeys.callMediaPreferences);
      if (value != null) {
        return CallMediaPreferences.fromJson(
          jsonDecode(value) as Map<String, dynamic>,
        );
      }
    } catch (error, stack) {
      debugLog('读取通话偏好失败，使用兼容默认值', error, stack);
    }
    return const CallMediaPreferences();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(
      StorageKeys.callMediaPreferences,
      jsonEncode(toJson()),
    )) {
      throw StateError('保存通话偏好失败');
    }
  }
}
