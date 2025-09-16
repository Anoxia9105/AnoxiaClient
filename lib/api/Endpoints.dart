class Endpoints {
  final String login = '/auth/login';
  final String refresh = '/auth/refresh';
  final String profile = '/user/profile';

  // Chat
  final String sendMessage = '/chat/send';
  final String roomMessages = '/chat/rooms/{roomId}/messages';
}
