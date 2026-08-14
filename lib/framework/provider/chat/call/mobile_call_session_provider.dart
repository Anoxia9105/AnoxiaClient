import 'dart:ui';

import 'package:anoxia/common/constants/call_window_sizes.dart';
import 'package:anoxia/framework/provider/chat/call/call_initial_media.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mobile_call_session_provider.g.dart';

/// 移动端通话会话状态管理
class MobileCallSession {
  // 房间ID
  final String roomId;
  // 通话标题（通常是群聊名称或个人昵称）
  final String title;
  // 是否最小化到悬浮窗（仅应用内悬浮窗，系统 PiP 不受此控制）
  final bool minimized;
  // 是否处于系统画中画模式（由系统 PiP 状态回调更新）
  final bool isInPipMode;
  // 从小窗右上角定位改回统一的绝对坐标偏移（方便吸边计算）
  final Offset position;
  final String? token;
  final CallInitialMedia initialMedia;

  const MobileCallSession({
    required this.roomId,
    required this.title,
    this.minimized = false,
    this.isInPipMode = false,
    this.position = const Offset(16, 150),
    this.token,
    this.initialMedia = CallInitialMedia.audio,
  });

  MobileCallSession copyWith({
    String? roomId,
    String? title,
    bool? minimized,
    bool? isInPipMode,
    String? token,
    Offset? position,
    CallInitialMedia? initialMedia,
  }) {
    return MobileCallSession(
      roomId: roomId ?? this.roomId,
      title: title ?? this.title,
      minimized: minimized ?? this.minimized,
      isInPipMode: isInPipMode ?? this.isInPipMode,
      token: token ?? this.token,
      position: position ?? this.position,
      initialMedia: initialMedia ?? this.initialMedia,
    );
  }
}

@Riverpod(keepAlive: true)
class MobileCallSessionController extends _$MobileCallSessionController {
  @override
  MobileCallSession? build() {
    return null;
  }

  void start({
    required String roomId,
    required String title,
    CallInitialMedia initialMedia = CallInitialMedia.audio,
  }) {
    ref.read(callInitialMediaProvider(roomId).notifier).state = initialMedia;
    state = MobileCallSession(
      roomId: roomId,
      title: title,
      minimized: false,
      initialMedia: initialMedia,
    );
  }

  void minimize() {
    if (state == null) return;
    state = state!.copyWith(minimized: true);
  }

  void enterCallPage() {
    if (state == null) return;
    state = state!.copyWith(minimized: false);
  }

  void end() {
    state = null;
  }

  void setPipMode(bool inPip) {
    if (state == null) return;

    state = state!.copyWith(isInPipMode: inPip, minimized: false);
  }

  void updateToken(String token) {
    if (state == null) return;
    state = state!.copyWith(token: token);
  }

  // ─── 拖拽中实时更新坐标 ───
  void updatePosition(Offset delta, double screenWidth, double screenHeight) {
    if (state == null) return;

    final isAudio = state!.initialMedia == CallInitialMedia.audio;
    final widgetWidth = isAudio
        ? CallWindowSizes.audioWidth
        : CallWindowSizes.videoWidth;
    final widgetHeight = isAudio
        ? CallWindowSizes.audioHeight
        : CallWindowSizes.videoHeight;

    double newX = state!.position.dx + delta.dx;
    double newY = state!.position.dy + delta.dy;

    // 基础边界防御，防止完全拖出屏幕外
    newX = newX.clamp(
      0.0,
      (screenWidth - widgetWidth).clamp(0.0, double.infinity),
    );
    newY = newY.clamp(
      40.0,
      (screenHeight - widgetHeight - 40.0).clamp(40.0, double.infinity),
    );

    state = state!.copyWith(position: Offset(newX, newY));
  }

  // ─── 手势松开后自动吸边 ───
  void snapToEdge(double screenWidth) {
    if (state == null) return;

    final currentX = state!.position.dx;
    final currentY = state!.position.dy;
    final widgetWidth = state!.initialMedia == CallInitialMedia.audio
        ? CallWindowSizes.audioWidth
        : CallWindowSizes.videoWidth;
    const padding = CallWindowSizes.edgePadding; // 离屏幕边缘的间距

    // 计算中心点判断靠左还是靠右
    double targetX;
    if ((currentX + widgetWidth / 2) < screenWidth / 2) {
      targetX = padding; // 吸附到左边
    } else {
      targetX = screenWidth - widgetWidth - padding; // 吸附到右边
    }

    state = state!.copyWith(position: Offset(targetX, currentY));
  }

  void exitPipMode() {
    if (state == null) return;

    state = state!.copyWith(isInPipMode: false, minimized: false);
  }
}
