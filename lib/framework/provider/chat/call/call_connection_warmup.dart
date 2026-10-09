import 'dart:async';

import 'package:anoxia/common/constants/api.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'call_connection_warmup.g.dart';

/// 只预热 DNS/TLS，不加入房间或访问摄像头/麦克风。
class CallConnectionWarmup {
  CallConnectionWarmup(this._prepare);
  final Future<void> Function() _prepare;
  Future<void>? _pending;
  DateTime? _preparedAt;

  bool get isReady =>
      _preparedAt != null &&
      DateTime.now().difference(_preparedAt!) < const Duration(minutes: 1);

  void start() {
    if (_pending != null || isReady) return;
    _pending = _run();
  }

  Future<void> _run() async {
    try {
      await _prepare();
      _preparedAt = DateTime.now();
    } catch (error, stack) {
      debugLog('通话预热失败，正式建连仍可继续', error, stack);
    } finally {
      _pending = null;
    }
  }
}

@Riverpod(keepAlive: true)
CallConnectionWarmup callConnectionWarmup(Ref ref) =>
    CallConnectionWarmup(() async {
      final room = Room();
      try {
        await room.prepareConnection(API.wsRoomBaseUrl, null);
      } finally {
        await room.dispose();
      }
    });
