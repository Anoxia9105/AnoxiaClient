import 'dart:io';

import 'package:notepadclient/core/constants/ApiBase.dart';
import 'package:notepadclient/core/domain/RoomSummary.dart';
import 'package:notepadclient/features/chat/service/IChatService.dart';

import '../../../../core/network/DioClient.dart';

class ChatServiceImpl extends ApiBase implements IChatService {
  final DioClient client = DioClient();

  @override
  Future<RoomSummary?> getChatList(num? userId) async {
    final response = await client.get(
      pathRoomList(),
      queryParameters: {"userId": userId},
    );
    if (response.statusCode != HttpStatus.ok || response.data["code"] != HttpStatus.ok || response.data == null) {
      return null;
    }
    return RoomSummary.fromJson(response.data);
  }
}
