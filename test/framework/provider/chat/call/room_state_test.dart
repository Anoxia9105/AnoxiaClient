import 'package:anoxia/framework/domain/room_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart';

class _Room extends Fake implements Room {}

void main() {
  test('重连成功显式清空旧错误，同时保留设备和媒体状态', () {
    final state = RoomState(
      room: _Room(),
      token: 'test',
      connectionState: ConnectionState.disconnected,
      connectionError: 'network',
      isReconnecting: true,
      micEnabled: true,
      cameraEnabled: false,
      screenSharing: false,
      speakerOn: true,
      audioInputs: const [],
      audioOutputs: const [],
      videoInputs: const [],
      remoteParticipants: const [],
    );
    final recovered = state.copyWith(
      connectionState: ConnectionState.connected,
      isReconnecting: false,
      clearConnectionError: true,
    );
    expect(recovered.connectionError, isNull);
    expect(recovered.connectionState, ConnectionState.connected);
    expect(recovered.isReconnecting, isFalse);
    expect(recovered.micEnabled, isTrue);
    expect(state.copyWith().connectionError, 'network');
  });
}
