// Web 端跨标签页会话同步实现。
//
// 同一浏览器（同源）的多个标签页共享 localStorage（Token）与 IndexedDB
// （聊天缓存），但各自持有独立的内存状态（Riverpod Provider、TokenManager
// 缓存、WebSocket 连接）。一个标签页登录/登出切换账号时，其它标签页无法
// 感知，会出现「旧账号头像 + 新账号聊天列表」的错位。
//
// 机制（主 + 兜底双通道，均不会在改动来源标签页触发，天然防自触发）：
// 1. 主通道：登录/登出时把事件写入自控的 localStorage 哨兵键
//    （anoxia_session_state），其它标签页监听 storage 事件读取。
//    storage 事件是浏览器原生机制，跨标签页投递 100% 可靠，且不依赖
//    flutter_secure_storage 的内部键名格式（其 Web 实现带 publicKey
//    前缀，如 FlutterSecureStorage.ACCESS_TOKEN，无法精确匹配）。
// 2. 加速通道：BroadcastChannel 即时广播（现代浏览器均支持）。
// 3. 兜底：直接感知 Token 存储键（后缀 .ACCESS_TOKEN）的增删，
//    覆盖哨兵键未写入的异常路径。
//
// 使用 package:web + dart:js_interop（JS/WASM 双兼容），不使用 dart:html
// （dart:html 在 --wasm(dart2wasm) 下无法编译）。
import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'package:anoxia/framework/logs/debug_log.dart';

/// 跨标签页会话事件动作
enum CrossTabAuthAction { login, logout }

/// 跨标签页会话事件
class CrossTabAuthEvent {
  const CrossTabAuthEvent({required this.action, this.userId, this.issuedAt});

  final CrossTabAuthAction action;

  /// 变更后的用户 ID；storage 兜底路径可能无法读取到，为 null
  final int? userId;

  /// 事件产生时间戳（毫秒），用于去重
  final int? issuedAt;
}

/// 跨标签页会话同步器
class CrossTabSessionSync {
  CrossTabSessionSync._internal() {
    _channel = web.BroadcastChannel(_channelName);
    _channel.addEventListener('message', ((web.Event event) {
      _handlePayload((event as web.MessageEvent).data, source: 'BroadcastChannel');
    }).toJS);
    web.window.addEventListener('storage', ((web.Event event) {
      if (event.isA<web.StorageEvent>()) {
        _handleStorageEvent(event as web.StorageEvent);
      }
    }).toJS);
  }

  static final CrossTabSessionSync instance = CrossTabSessionSync._internal();

  static const String _channelName = 'anoxia_session';

  /// 自控哨兵键：登录/登出事件的主投递通道
  static const String _markerKey = 'anoxia_session_state';

  /// flutter_secure_storage Web 端的 Token 存储键后缀
  /// （实际键名为 `'<publicKey>.ACCESS_TOKEN'`，publicKey 默认 FlutterSecureStorage）
  static const String _tokenKeySuffix = '.ACCESS_TOKEN';

  late final web.BroadcastChannel _channel;
  final StreamController<CrossTabAuthEvent> _controller =
      StreamController<CrossTabAuthEvent>.broadcast();

  /// 最近一次已处理事件签名（action|userId|issuedAt），用于双通道去重
  String? _lastHandled;

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
    final issuedAt = DateTime.now().millisecondsSinceEpoch;
    final payload = jsonEncode({
      'action': action,
      'userId': userId,
      'ts': issuedAt,
    });
    // 1. 主通道：写入自控哨兵键，storage 事件跨标签页必达
    try {
      web.window.localStorage.setItem(_markerKey, payload);
    } catch (e) {
      debugLog('[CrossTabSync] 哨兵键写入失败: $e');
    }
    // 2. 加速通道：BroadcastChannel 即时广播
    try {
      _channel.postMessage(payload.toJS);
    } catch (e) {
      debugLog('[CrossTabSync] BroadcastChannel 广播失败: $e');
    }
  }

  /// storage 事件处理：
  /// - 哨兵键变化 → 解析事件（主通道）
  /// - Token 存储键（后缀 .ACCESS_TOKEN）增删 → 感知登出/登录（兜底）
  void _handleStorageEvent(web.StorageEvent event) {
    final key = event.key;
    if (key == null) return;
    if (key == _markerKey) {
      _handlePayloadFromMarker(event.newValue);
      return;
    }
    if (key.endsWith(_tokenKeySuffix)) {
      _handlePayload(
        jsonEncode({
          'action': event.newValue == null ? 'logout' : 'login',
          'userId': null,
        }).toJS,
        source: 'TokenStorageEvent',
      );
      return;
    }
    // 哨兵键被清除（localStorage.clear() 等）时兜底感知登出
    if (event.oldValue != null && event.newValue == null) {
      final oldRaw = event.oldValue!;
      if (oldRaw.startsWith('{') && oldRaw.contains('"action"')) {
        _handlePayload(oldRaw.toJS, source: 'MarkerRemoved');
      }
    }
  }

  /// 从哨兵键当前值解析事件（storage 事件只给 newValue，这里再读一次
  /// localStorage 确保拿到的是最新值）
  void _handlePayloadFromMarker(String? newValue) {
    try {
      final current = web.window.localStorage.getItem(_markerKey);
      final raw = (current == null || current.isEmpty) ? newValue : current;
      if (raw == null || raw.isEmpty) return;
      _handlePayload(raw.toJS, source: 'MarkerStorageEvent');
    } catch (_) {
      // 忽略解析失败
    }
  }

  void _handlePayload(JSAny? data, {required String source}) {
    try {
      if (!data.isA<JSString>()) return;
      final payload = jsonDecode((data as JSString).toDart);
      if (payload is Map) _emit(payload, source: source);
    } catch (_) {
      // 忽略无法解析的广播
    }
  }

  void _emit(Map<dynamic, dynamic> payload, {required String source}) {
    final actionRaw = payload['action'];
    final action = actionRaw == 'logout'
        ? CrossTabAuthAction.logout
        : actionRaw == 'login'
            ? CrossTabAuthAction.login
            : null;
    if (action == null) return;
    final userIdRaw = payload['userId'];
    final issuedAtRaw = payload['ts'];
    final userId = userIdRaw is int ? userIdRaw : null;
    final issuedAt = issuedAtRaw is int ? issuedAtRaw : null;

    // 双通道去重：同一 (action, userId, ts) 只处理一次
    final signature = '$action|$userId|$issuedAt';
    if (signature == _lastHandled) return;
    _lastHandled = signature;

    _controller.add(
      CrossTabAuthEvent(action: action, userId: userId, issuedAt: issuedAt),
    );
  }
}
