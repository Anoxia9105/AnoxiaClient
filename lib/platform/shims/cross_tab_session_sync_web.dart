// Web 端跨标签页会话同步实现。
//
// 同一浏览器（同源）的多个标签页共享 localStorage（Token）与 IndexedDB
// （聊天缓存），但各自持有独立的内存状态（Riverpod Provider、TokenManager
// 缓存、WebSocket 连接）。一个标签页登录/登出切换账号时，其它标签页无法
// 感知，会出现「旧账号头像 + 新账号聊天列表」的错位。
//
// 这里在登录/登出时通过 BroadcastChannel 广播事件，其它标签页订阅后清空
// 共享缓存并重载页面，从共享存储重新冷启动，保证「一个浏览器一个账号」。
// storage 事件作为 BroadcastChannel 不可用时的兜底（storage 事件不会在
// 改动来源标签页触发，天然防自触发）。
//
// 使用 package:web + dart:js_interop（JS/WASM 双兼容），不使用 dart:html
// （dart:html 在 --wasm(dart2wasm) 下无法编译）。
import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// 跨标签页会话事件动作
enum CrossTabAuthAction { login, logout }

/// 跨标签页会话事件
class CrossTabAuthEvent {
  const CrossTabAuthEvent({required this.action, this.userId});

  final CrossTabAuthAction action;

  /// 变更后的用户 ID；storage 兜底路径可能无法读取到，为 null
  final int? userId;
}

/// 跨标签页会话同步器
class CrossTabSessionSync {
  CrossTabSessionSync._internal() {
    _channel = web.BroadcastChannel(_channelName);
    _channel.addEventListener('message', ((web.Event event) {
      _handleChannelMessage((event as web.MessageEvent).data);
    }).toJS);
    web.window.addEventListener('storage', ((web.Event event) {
      if (event.isA<web.StorageEvent>()) {
        _handleStorageEvent(event as web.StorageEvent);
      }
    }).toJS);
  }

  static final CrossTabSessionSync instance = CrossTabSessionSync._internal();

  static const String _channelName = 'anoxia_session';
  static const String _tokenStorageKey = 'ACCESS_TOKEN';

  late final web.BroadcastChannel _channel;
  final StreamController<CrossTabAuthEvent> _controller =
      StreamController<CrossTabAuthEvent>.broadcast();

  /// 其它标签页登录/登出事件流
  Stream<CrossTabAuthEvent> get events => _controller.stream;

  /// 广播登录事件（登录成功后调用）
  void broadcastLogin(int? userId) => _post(action: 'login', userId: userId);

  /// 广播登出事件（登出完成后调用）
  void broadcastLogout(int? userId) => _post(action: 'logout', userId: userId);

  /// 重载当前页面（其它标签页账号变更后，本页的完整重置入口）
  void reload() {
    try {
      web.window.location.reload();
    } catch (_) {
      // 重载失败忽略（页面即将关闭等场景）
    }
  }

  void _post({required String action, int? userId}) {
    try {
      _channel.postMessage(
        jsonEncode({'action': action, 'userId': userId}).toJS,
      );
    } catch (_) {
      // 广播失败（如页面即将关闭）不影响主流程
    }
  }

  void _handleChannelMessage(JSAny? data) {
    try {
      if (!data.isA<JSString>()) return;
      final payload = jsonDecode((data as JSString).toDart);
      if (payload is Map) _emit(payload);
    } catch (_) {
      // 忽略无法解析的广播
    }
  }

  /// storage 事件兜底：通过 Token 键变化感知会话变更。
  ///
  /// 登录路径中 Token 写入先于 LAST_LOGIN_USER_ID 落盘，此处无法可靠读到
  /// 新用户 ID，统一传 null，由订阅方按「未知用户」处理（触发重载）。
  void _handleStorageEvent(web.StorageEvent event) {
    if (event.key != _tokenStorageKey) return;
    _emit({
      'action': event.newValue == null ? 'logout' : 'login',
      'userId': null,
    });
  }

  void _emit(Map<dynamic, dynamic> payload) {
    final actionRaw = payload['action'];
    final action = actionRaw == 'logout'
        ? CrossTabAuthAction.logout
        : actionRaw == 'login'
            ? CrossTabAuthAction.login
            : null;
    if (action == null) return;
    final userIdRaw = payload['userId'];
    _controller.add(
      CrossTabAuthEvent(
        action: action,
        userId: userIdRaw is int ? userIdRaw : null,
      ),
    );
  }
}
