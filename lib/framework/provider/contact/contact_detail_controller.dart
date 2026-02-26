import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/framework/domain/ChatContactDetailVO.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../logs/talker.dart';

part 'contact_detail_controller.g.dart';

@Riverpod(keepAlive: true)
Future<ChatContactDetailVO> contactDetailData(Ref ref, int userId) async {
  // 调用你后端的接口
  final response = await DioClient().get(
    API.contactUserDetail,
    queryParameters: {'userId': userId},
  );

  log.info(response);
  return ChatContactDetailVO.fromJson(response.data["data"]);
}

// 发消息按钮 - 创建聊天室
@riverpod
class ContactChatLoading extends _$ContactChatLoading {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}
