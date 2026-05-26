import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mobile_call_session_provider.g.dart';

/// 移动端通话会话状态管理
class MobileCallSession {
  final String roomId;
  final String title;
  final bool minimized;
  final String? token;

  const MobileCallSession({
    required this.roomId,
    required this.title,
    this.minimized = false,
    this.token,
  });

  MobileCallSession copyWith({
    String? roomId,
    String? title,
    bool? minimized,
    String? token,
  }) {
    return MobileCallSession(
      roomId: roomId ?? this.roomId,
      title: title ?? this.title,
      minimized: minimized ?? this.minimized,
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

  void updateToken(String token) {
    if (state == null) return;
    state = state!.copyWith(token: token);
  }
}
