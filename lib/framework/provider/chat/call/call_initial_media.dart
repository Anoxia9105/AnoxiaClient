/// 通话初始媒体类型定义
///
/// 定义通话开始时选择的媒体类型（音频或视频），以及相关的 Riverpod Provider。
import 'package:flutter_riverpod/legacy.dart' show StateProvider;

/// 通话初始媒体类型枚举
enum CallInitialMedia {
  /// 音频通话
  audio('audio'),

  /// 视频通话
  video('video');

  /// 媒体类型值
  final String value;

  const CallInitialMedia(this.value);

  /// 从值创建枚举实例
  ///
  /// 默认返回音频通话类型。
  static CallInitialMedia fromValue(Object? value) {
    return switch (value?.toString()) {
      'video' => CallInitialMedia.video,
      _ => CallInitialMedia.audio,
    };
  }
}

/// 通话初始媒体类型 Provider
///
/// 按房间 ID 维护的通话初始媒体类型状态。
final callInitialMediaProvider = StateProvider.family<CallInitialMedia, String>(
  (ref, roomId) => CallInitialMedia.audio,
);

/// 通话是否为群组 Provider
///
/// 按房间 ID 维护的通话群组标识状态。
final callIsGroupProvider = StateProvider.family<bool, String>(
  (ref, roomId) => false,
);
