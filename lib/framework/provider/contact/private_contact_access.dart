import 'package:anoxia/framework/domain/chat_contact_vo.dart';
import 'package:anoxia/framework/network/dio_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final privateContactAccessProvider = FutureProvider.autoDispose
    .family<bool, int>((ref, peerId) async {
      final response = await DioClient().get(
        '/contact/privateAccess',
        queryParameters: {'contactId': peerId},
      );
      return _data(response.data) == true;
    });

final blockedContactsProvider = FutureProvider.autoDispose<List<ChatContactVO>>(
  (ref) async {
    final response = await DioClient().get('/contact/blocked');
    final data = _data(response.data) as List;
    return [
      for (final row in data)
        ChatContactVO.fromJson(Map<String, dynamic>.from(row as Map)),
    ];
  },
);

Future<void> setContactBlocked(int contactId, {required bool blocked}) async {
  final path = '/contact/blocked?contactId=$contactId';
  final response = await (blocked
      ? DioClient().put(path)
      : DioClient().delete(path));
  _data(response.data);
}

dynamic _data(dynamic body) {
  if (body is! Map || body['code'] != 200) {
    throw StateError('Contact request failed');
  }
  return body['data'];
}
