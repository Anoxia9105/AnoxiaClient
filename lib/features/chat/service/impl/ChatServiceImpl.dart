import 'package:notepadclient/core/constants/ApiBase.dart';
import 'package:notepadclient/core/domain/RoomSummary.dart';
import 'package:notepadclient/features/chat/service/IChatService.dart';

class ChatServiceImpl extends ApiBase implements IChatService {
  @override
  Future<List<RoomSummary>> getChatList(num? userId) {
    return handleResponse<List<RoomSummary>>(
      get(pathRoomList(), queryParameters: {"userId": userId}),
      parser: (data) => (data as List).map(RoomSummary.fromJson).toList(),
      defaultValue: [],
    );
  }

  @override
  Future<void> getRoomMessage(String roomId, num userId) async {
    final response = await get(
      pathRoomMessage(),
      queryParameters: {"roomId": roomId, "userId": userId},
    );
    print("================================");
    print(response);
  }
}
