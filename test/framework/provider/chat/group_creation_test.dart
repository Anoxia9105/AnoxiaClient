import 'package:anoxia/domain/repositories/group_repository.dart';
import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/provider/chat/room/create_new_group_controller.dart';
import 'package:anoxia/framework/provider/core/group_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Groups extends Fake implements GroupRepository {
  String? avatar;
  @override
  Future<ChatRoomVO> createGroup({
    required String name,
    required List<int> userIds,
    required int joinPolicy,
    String? avatarUrl,
  }) async {
    avatar = avatarUrl;
    return ChatRoomVO(
      roomId: 'new-group',
      roomName: name,
      roomAvatar: avatarUrl,
    );
  }
}

void main() {
  test('创建群聊保存头像，成功回调能立即读取创建结果', () async {
    final groups = _Groups();
    final container = ProviderContainer(
      overrides: [groupRepositoryProvider.overrideWithValue(groups)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      createGroupControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    await container.read(createGroupControllerProvider.future);
    ChatRoomVO? created;
    await container
        .read(createGroupControllerProvider.notifier)
        .createGroup(
          name: '业务沟通群',
          userIds: [2, 3],
          joinPolicy: 1,
          avatarUrl: 'https://cdn.example.com/group.jpg',
          onSuccess: (room) async {
            created = room;
            expect(
              container.read(createGroupControllerProvider).value?.roomId,
              'new-group',
            );
          },
        );
    expect(groups.avatar, 'https://cdn.example.com/group.jpg');
    expect(created?.roomAvatar, groups.avatar);
  });
}
