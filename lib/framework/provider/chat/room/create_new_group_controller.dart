import 'dart:ui';

import 'package:anoxia/framework/provider/core/group_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/chat_room_vo.dart';

part 'create_new_group_controller.g.dart';

/// 多选框选择用
@riverpod
class SelectedContactIds extends _$SelectedContactIds {
  @override
  Set<int> build() => {};

  void toggle(int userId) {
    final next = {...state};
    if (next.contains(userId)) {
      next.remove(userId);
    } else {
      next.add(userId);
    }
    state = next;
  }

  void remove(int userId) => state = {...state}..remove(userId);

  void clear() => state = {};
}

/// 创建群聊控制器
///
/// 负责发起创建群聊的请求和处理结果
@riverpod
class CreateGroupController extends _$CreateGroupController {
  @override
  FutureOr<ChatRoomVO?> build() => null; // 初始状态

  Future<void> createGroup({
    required String name,
    required List<int> userIds,
    required int joinPolicy,
    required VoidCallback onSuccess,
  }) async {
    // 1. 进入加载状态
    state = const AsyncLoading();

    // 2. 使用 AsyncValue.guard 捕获异常
    state = await AsyncValue.guard(() async {
      final vo = await ref.read(groupRepositoryProvider).createGroup(
            name: name,
            userIds: userIds,
            joinPolicy: joinPolicy,
          );
      onSuccess(); // 成功回调
      return vo;
    });
  }
}
