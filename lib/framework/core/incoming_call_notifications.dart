/// 管理来电通知的异步显示，避免重复邀请或接听后迟到的通知。
class IncomingCallNotifications {
  final Map<String, Object> _active = {};

  Future<void> show({
    required String inviteId,
    required Future<bool> Function() prepare,
    required Future<void> Function() present,
    required Future<void> Function() dismiss,
  }) async {
    if (inviteId.isEmpty || _active.containsKey(inviteId)) return;
    final request = Object();
    _active[inviteId] = request;
    bool isCurrent() => identical(_active[inviteId], request);
    try {
      final allowed = await prepare();
      if (!isCurrent()) return;
      if (!allowed) {
        _active.remove(inviteId);
        return;
      }
      await present();
      // 原生 show 也可能尚未完成，取消操作先到时必须补一次清理。
      if (!isCurrent() && !_active.containsKey(inviteId)) await dismiss();
    } catch (_) {
      if (isCurrent()) _active.remove(inviteId);
      rethrow;
    }
  }

  Future<void> cancel(String inviteId, Future<void> Function() dismiss) async {
    // 必须在任何 await 之前失效，阻止权限/初始化等待中的 show。
    _active.remove(inviteId);
    await dismiss();
  }
}
