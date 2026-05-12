import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mobile_call_session_provider.g.dart';

class MobileCallSession {
  final String roomId;
  final String title;
  final bool minimized;

  const MobileCallSession({
    required this.roomId,
    required this.title,
    this.minimized = false,
  });

  MobileCallSession copyWith({
    String? roomId,
    String? title,
    bool? minimized,
  }) {
    return MobileCallSession(
      roomId: roomId ?? this.roomId,
      title: title ?? this.title,
      minimized: minimized ?? this.minimized,
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
}
