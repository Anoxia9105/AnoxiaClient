import 'package:anoxia/features/chat/presentation/call/component/call_disconnection_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('账号在另一端加入和房间结束有各自明确的恢复提示', () {
    expect(
      callDisconnectionMessageKey('duplicateIdentity'),
      'call_connection_other_device',
    );
    expect(callDisconnectionMessageKey('roomDeleted'), 'call_room_ended_hint');
    expect(callDisconnectionMessageKey('roomClosed'), 'call_room_ended_hint');
    expect(
      callDisconnectionMessageKey('reconnectAttemptsExceeded'),
      'call_reconnect_exhausted',
    );
    expect(callDisconnectionMessageKey(null), 'call_connection_lost');
  });
}
