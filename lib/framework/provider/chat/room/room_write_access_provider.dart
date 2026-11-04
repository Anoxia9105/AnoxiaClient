import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/contact/private_contact_access.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final roomWriteAccessProvider = Provider.autoDispose.family<bool, String>((
  ref,
  roomId,
) {
  final room = ref.watch(currentRoomProvider(roomId));
  if (room == null || room.roomStatus != 0 || room.isOfficial) return false;
  if (room.roomType != 0) return true;
  final peerId = room.peerId;
  if (peerId == null) return false;
  final access = ref.watch(privateContactAccessProvider(peerId));
  return !access.isLoading && !access.hasError && access.value == true;
});
