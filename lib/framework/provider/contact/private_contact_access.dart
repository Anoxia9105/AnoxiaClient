import 'dart:async';

import 'package:anoxia/framework/domain/chat_contact_vo.dart';
import 'package:anoxia/framework/network/dio_client.dart';
import 'package:anoxia/framework/provider/auth/token_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final privateContactAccessProvider = FutureProvider.autoDispose
    .family<bool, int>(
      (ref, peerId) => _cacheContactQuery(ref, () async {
        final response = await DioClient().get(
          '/contact/privateAccess',
          queryParameters: {'contactId': peerId},
        );
        return _data(response.data) == true;
      }),
      retry: _noContactQueryRetry,
    );

final blockedContactsProvider = FutureProvider.autoDispose<List<ChatContactVO>>(
  (ref) => _cacheContactQuery(ref, () async {
    final response = await DioClient().get('/contact/blocked');
    final data = _data(response.data) as List;
    return [
      for (final row in data)
        ChatContactVO.fromJson(Map<String, dynamic>.from(row as Map)),
    ];
  }),
  retry: _noContactQueryRetry,
);

Duration? _noContactQueryRetry(int retryCount, Object error) => null;

Future<T> _cacheContactQuery<T>(Ref ref, Future<T> Function() load) async {
  ref.watch(tokenCacheProvider);
  final link = ref.keepAlive();
  Timer? expiry;
  ref.onCancel(() => expiry = Timer(const Duration(minutes: 2), link.close));
  ref.onResume(() => expiry?.cancel());
  ref.onDispose(() => expiry?.cancel());
  try {
    return await load();
  } catch (_) {
    link.close();
    rethrow;
  }
}

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
