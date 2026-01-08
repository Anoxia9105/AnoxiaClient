import 'MessageEunm.dart';

abstract class RoomMessageData {
  final String? messageId;
  final int? senderId;
  final MessageState? state;
  final DeliveryStatus? status;
  final int? timestamp;

  RoomMessageData({this.messageId, this.senderId, this.state, this.status, this.timestamp});

  @override
  String toString() {
    return 'RoomMessageData{messageId: $messageId, senderId: $senderId, state: $state, status: $status, timestamp: $timestamp}';
  }


}