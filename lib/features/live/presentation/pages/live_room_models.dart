/// 直播房间数据模型
///
/// 定义直播间页面中使用的数据模型，包括聊天消息和连麦请求等。
part of 'live_room_page.dart';

/// 直播聊天消息
///
/// 表示直播间内的一条聊天消息，包含发送者名称、消息文本和是否为主播标识。
class _LiveChatMessage {
  /// 发送者显示名称
  final String name;
  /// 消息文本内容
  final String text;
  /// 是否为主播发送的消息
  final bool isHost;

  const _LiveChatMessage({
    required this.name,
    required this.text,
    required this.isHost,
  });

  /// 创建消息的副本，可选覆盖指定字段
  _LiveChatMessage copyWith({String? name, String? text, bool? isHost}) {
    return _LiveChatMessage(
      name: name ?? this.name,
      text: text ?? this.text,
      isHost: isHost ?? this.isHost,
    );
  }
}

/// 连麦请求
///
/// 表示观众向主播发起的连麦请求，包含请求者的身份标识和名称。
class _CohostRequest {
  /// 请求者的唯一身份标识
  final String identity;
  /// 请求者的显示名称
  final String name;

  const _CohostRequest({required this.identity, required this.name});
}
