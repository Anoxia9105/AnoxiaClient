part of 'live_room_page.dart';

class _LiveChatMessage {
  final String name;
  final String text;
  final bool isHost;

  const _LiveChatMessage({
    required this.name,
    required this.text,
    required this.isHost,
  });

  _LiveChatMessage copyWith({String? name, String? text, bool? isHost}) {
    return _LiveChatMessage(
      name: name ?? this.name,
      text: text ?? this.text,
      isHost: isHost ?? this.isHost,
    );
  }
}

class _CohostRequest {
  final String identity;
  final String name;

  const _CohostRequest({required this.identity, required this.name});
}
