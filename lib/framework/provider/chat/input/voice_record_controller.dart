import 'package:anoxia/features/chat/presentation/widgets/chatinput/mobile/chat_voice_overlay.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:flutter/material.dart';

class VoiceRecordController extends ChangeNotifier {
  static const double _cancelThreshold = 60.0;
  OverlayEntry? _overlayEntry;

  bool isRecording = false;
  bool willCancel = false;
  double _startY = 0.0;

  void showOverlay(BuildContext context) {
    if (_overlayEntry != null) return;
    _overlayEntry = OverlayEntry(
      builder: (_) => ChatVoiceOverlay(controller: this),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void onStart(LongPressStartDetails d) {
    isRecording = true;
    willCancel = false;
    _startY = d.globalPosition.dy;
    notifyListeners();
  }

  void onUpdate(LongPressMoveUpdateDetails d) {
    if (!isRecording) return;
    final drag = _startY - d.globalPosition.dy;
    final should = drag > _cancelThreshold;
    if (willCancel != should) {
      willCancel = should;
      notifyListeners();
    }
  }

  void onEnd(LongPressEndDetails d) {
    if (!isRecording) return;
    final cancelled = willCancel;
    isRecording = false;
    willCancel = false;
    notifyListeners();
    if (cancelled) {
      log.info('Voice recording cancelled');
      // TODO: cancelRecording();
    } else {
      log.info('Voice recording finished, sending message');
      // TODO: stopAndSendRecording();
    }
  }

  @override
  void dispose() {
    hideOverlay();
    super.dispose();
  }
}
