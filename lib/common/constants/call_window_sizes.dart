/// 通话悬浮窗尺寸常量
///
/// 供 UI 层（悬浮窗渲染）与 Provider 层（拖拽/吸边边界计算）共用，
/// 避免两处硬编码尺寸漂移导致悬浮窗被拖出屏幕。
class CallWindowSizes {
  CallWindowSizes._();

  /// 音频通话悬浮窗宽
  static const double audioWidth = 150;

  /// 音频通话悬浮窗高
  static const double audioHeight = 56;

  /// 视频通话悬浮窗宽
  static const double videoWidth = 100;

  /// 视频通话悬浮窗高
  static const double videoHeight = 150;

  /// 悬浮窗与屏幕边缘的间距
  static const double edgePadding = 16;
}
