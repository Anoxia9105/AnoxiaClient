import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/domain/official_room_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OfficialRoomConfig', () {
    test('does not classify a normal room by its display name', () {
      final room = ChatRoomVO(
        roomId: 'normal-room',
        roomName: 'Anoxia 官方',
        roomType: RoomType.groupChat.index,
      );

      expect(OfficialRoomConfig.usesReservedVirtualRoomId(room), isFalse);
    });

    test('recognizes only the reserved virtual room id', () {
      final room = ChatRoomVO(
        roomId: OfficialRoomConfig.virtualRoomId,
        roomType: RoomType.official.index,
      );

      expect(OfficialRoomConfig.usesReservedVirtualRoomId(room), isTrue);
    });
  });
}
