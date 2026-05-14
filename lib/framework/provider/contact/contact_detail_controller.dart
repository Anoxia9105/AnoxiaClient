import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/framework/domain/ChatContactDetailVO.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../logs/talker.dart';

part 'contact_detail_controller.g.dart';

/// 获取联系人详情
///
/// 根据用户ID获取联系人的详细信息（来自 sys_user 和 chat_contact 表的聚合数据）
@Riverpod(keepAlive: true)
Future<ChatContactDetailVO> contactDetailData(Ref ref, int userId) async {
  final response = await DioClient().get(
    API.contactUserDetail,
    queryParameters: {'userId': userId},
  );

  log.info(response);
  return ChatContactDetailVO.fromJson(response.data["data"]);
}

/// 联系人聊天按钮加载状态
///
/// 控制"发消息"按钮的加载状态，防止重复点击
@riverpod
class ContactChatLoading extends _$ContactChatLoading {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}
