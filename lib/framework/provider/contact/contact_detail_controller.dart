import 'package:anoxia/framework/domain/ChatContactDetailVO.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../logs/talker.dart';

part 'contact_detail_controller.g.dart';

@Riverpod(keepAlive: true)
Future<ChatContactDetailVO> contactDetailData(Ref ref, int userId) async {
  // 调用你后端的 /userDetail 接口
  final response = await DioClient().get(
    '/contact/userDetail',
    queryParameters: {'userId': userId},
  );

  log.info(response);
  return ChatContactDetailVO.fromJson(response.data["data"]);
}
