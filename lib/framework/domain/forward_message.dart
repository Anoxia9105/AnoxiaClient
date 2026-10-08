import 'chat_message.dart';

class ForwardRejectedException implements Exception {
  final int code;
  const ForwardRejectedException(this.code);
}

class ForwardRequest {
  final String requestId;
  final String sourceRoomId;
  final String targetRoomId;
  final List<String> messageIds;
  final String mode;
  const ForwardRequest({
    required this.requestId,
    required this.sourceRoomId,
    required this.targetRoomId,
    required this.messageIds,
    required this.mode,
  });
  Map<String, dynamic> toJson() => {
    'requestId': requestId,
    'sourceRoomId': sourceRoomId,
    'targetRoomId': targetRoomId,
    'messageIds': messageIds,
    'mode': mode,
  };
  factory ForwardRequest.fromJson(Map<String, dynamic> json) => ForwardRequest(
    requestId: json['requestId'] as String,
    sourceRoomId: json['sourceRoomId'] as String,
    targetRoomId: json['targetRoomId'] as String,
    messageIds: List<String>.from(json['messageIds'] as List),
    mode: json['mode'] as String,
  );
  bool matches(String source, String target, List<String> ids, String type) =>
      sourceRoomId == source &&
      targetRoomId == target &&
      mode == type &&
      messageIds.length == ids.length &&
      messageIds.toSet().containsAll(ids);
}

class ForwardResult {
  final String operationId;
  final String targetRoomId;
  final String status;
  final List<ForwardResultItem> items;
  const ForwardResult({
    required this.operationId,
    required this.targetRoomId,
    required this.status,
    required this.items,
  });
  bool get isSuccess =>
      status == 'SUCCEEDED' &&
      items.isNotEmpty &&
      items.every((i) => i.seq != null);
  factory ForwardResult.fromJson(Map<String, dynamic> json) => ForwardResult(
    operationId: json['operationId'] as String,
    targetRoomId: json['targetRoomId'] as String,
    status: json['status'] as String,
    items: (json['items'] as List)
        .map(
          (e) =>
              ForwardResultItem.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList(),
  );
}

class ForwardResultItem {
  final String messageId;
  final int? seq;
  final String status;
  const ForwardResultItem({
    required this.messageId,
    required this.seq,
    required this.status,
  });
  factory ForwardResultItem.fromJson(Map<String, dynamic> json) =>
      ForwardResultItem(
        messageId: json['messageId'] as String,
        seq: (json['seq'] as num?)?.toInt(),
        status: json['status'] as String,
      );
}

class ForwardRecordItem {
  final String authorName;
  final String? authorAvatar;
  final ChatMessage message;
  const ForwardRecordItem({
    required this.authorName,
    this.authorAvatar,
    required this.message,
  });
  factory ForwardRecordItem.fromJson(Map<String, dynamic> json) =>
      ForwardRecordItem(
        authorName: json['authorName']?.toString() ?? '',
        authorAvatar: json['authorAvatar']?.toString(),
        message: ChatMessage.fromJson(json),
      );
}

class ForwardRecordPage {
  final int total;
  final List<ForwardRecordItem> items;
  const ForwardRecordPage({required this.total, required this.items});
  factory ForwardRecordPage.fromJson(Map<String, dynamic> json) =>
      ForwardRecordPage(
        total: (json['total'] as num).toInt(),
        items: (json['items'] as List)
            .map(
              (e) => ForwardRecordItem.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList(),
      );
}
