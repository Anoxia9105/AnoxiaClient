import 'dart:io';

import 'package:notepadclient/core/constants/ApiBase.dart';
import 'package:notepadclient/core/domain/RoomSummary.dart';
import 'package:notepadclient/features/chat/service/IChatService.dart';


class ChatServiceImpl extends ApiBase implements IChatService {

  @override
  Future<List<RoomSummary?>> getChatList(num? userId) async {
    final response = await get(
      pathRoomList(),
      queryParameters: {"userId": userId},
    );

    // 先判空
    final data = response.data;
    if (response.statusCode != HttpStatus.ok || data == null) {
      return [];
    }

    // 业务 code 校验
    if (data["code"] != HttpStatus.ok || data["data"] == null) {
      return [];
    }

    // 转换为对象列表
    final list = data["data"] as List;
    return list.map((e) => RoomSummary.fromJson(e)).toList();
  }

  @override
  Future<void> getRoomMessage(String roomId,num userId) async {
    final response = await  get(pathRoomMessage(),queryParameters: {
      "roomId": roomId,
      "userId":userId
    });
    print("================================");
    print(response);
  }
}
