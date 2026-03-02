import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 布局模式枚举
enum LayoutMode {
  grid,      // 网格布局 - 适合3-16个参与者的会议
  carousel,  // 轮播布局 - 适合演讲/直播
  focus,     // 焦点布局 - 适合1对1通话
}

/// 布局状态类
class LayoutState {
  final LayoutMode mode;
  final String? focusedParticipantSid;
  final bool showLocalParticipant;

  const LayoutState({
    this.mode = LayoutMode.grid,
    this.focusedParticipantSid,
    this.showLocalParticipant = true,
  });

  LayoutState copyWith({
    LayoutMode? mode,
    String? focusedParticipantSid,
    bool? showLocalParticipant,
  }) {
    return LayoutState(
      mode: mode ?? this.mode,
      focusedParticipantSid: focusedParticipantSid ?? this.focusedParticipantSid,
      showLocalParticipant: showLocalParticipant ?? this.showLocalParticipant,
    );
  }

  @override
  String toString() =>
      'LayoutState(mode: $mode, focused: $focusedParticipantSid, showLocal: $showLocalParticipant)';
}

/// 布局管理器类
class LayoutManager {
  LayoutState _state = const LayoutState();

  /// 获取当前状态
  LayoutState get state => _state;

  /// 切换布局模式
  void setLayoutMode(LayoutMode mode) {
    _state = _state.copyWith(mode: mode);
  }

  /// 设置焦点参与者
  void setFocusedParticipant(String? sid) {
    _state = _state.copyWith(focusedParticipantSid: sid);
  }

  /// 根据参与者数量自动选择布局
  void autoSelectLayout(int participantCount) {
    LayoutMode newMode;

    if (participantCount <= 1) {
      newMode = LayoutMode.focus;
    } else if (participantCount <= 3) {
      newMode = LayoutMode.carousel;
    } else {
      newMode = LayoutMode.grid;
    }

    if (newMode != _state.mode) {
      setLayoutMode(newMode);
    }
  }

  /// 重置布局状态
  void reset() {
    _state = const LayoutState();
  }
}

/// 布局状态 Riverpod Provider
final layoutProvider = Provider<LayoutManager>((ref) {
  return LayoutManager();
});
