import 'dart:ui';

import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/ChatRoomVO.dart';

part 'create_new_gropu_controller.g.dart';

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

@riverpod
class CreateGroupController extends _$CreateGroupController {
  @override
  FutureOr<ChatRoomVO?> build() => null; // 初始状态

  Future<void> createGroup({
    required String name,
    required List<int> userIds,
    required VoidCallback onSuccess,
  }) async {
    // 1. 进入加载状态
    state = const AsyncLoading();

    // 2. 使用 AsyncValue.guard 捕获异常
    state = await AsyncValue.guard(() async {
      final res = await DioClient().post(
        API.chatCreateGroup,
        data: {'name': name, 'ids': userIds},
      );

      // 根据你后端 AjaxResult 的结构解析
      if (res.data['code'] == 200) {
        final vo = ChatRoomVO.fromJson(res.data['data']);
        onSuccess(); // 成功回调
        return vo;
      } else {
        throw res.data['msg'] ?? "创建失败";
      }
    });
  }
}
