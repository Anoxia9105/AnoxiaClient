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
  final String? token;

  const MobileCallSession({
    required this.roomId,
    required this.title,
    this.minimized = false,
    this.isInPipMode = false,
    this.token,
  });

  MobileCallSession copyWith({
    String? roomId,
    String? title,
    bool? minimized,
    bool? isInPipMode,
    String? token,
  }) {
    return MobileCallSession(
      roomId: roomId ?? this.roomId,
      title: title ?? this.title,
      minimized: minimized ?? this.minimized,
      isInPipMode: isInPipMode ?? this.isInPipMode,
      token: token ?? this.token,
    );
  }
}

@Riverpod(keepAlive: true)
class MobileCallSessionController extends _$MobileCallSessionController {
  @override
  MobileCallSession? build() {
    return null;
  }

  void start({required String roomId, required String title}) {
    state = MobileCallSession(roomId: roomId, title: title, minimized: false);
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
    state = state!.copyWith(isInPipMode: inPip);
  }

  void updateToken(String token) {
    if (state == null) return;
    state = state!.copyWith(token: token);
  }
}
