/// POST 方式消费后端 SSE 流（AI 聊天 / 笔记 AI）
///
/// 后端协议（AnoxiaServer AiChatController/NoteAiController）：
/// - 匿名事件：`data:<增量文本>`（多次，纯文本）
/// - 命名事件：`event:done` + `data:{json}`、`event:error` + `data:{json}`
///
/// EventSource 不支持 POST，因此基于 package:http 的流式请求手工解析。
///
/// ⚠️ 为什么不用 Dio？ Dio 的 `ResponseType.stream` 在 Web 与原生（Android/iOS/Windows）
/// 下都会**缓冲响应体**，SSE 增量不会实时到达；推理期长空窗会被误判为超时，导致
/// 「有回复仍报失败」。此前 Web 端已切到 http.Client() 修复该问题，原生端沿用同一套
/// 实现即可全平台一致。
///
/// - Web：http.Client() 为 BrowserClient，底层 fetch + ReadableStream，真流式。
/// - 原生：http.Client() 为 IOClient，底层 dart:io HttpClientResponse 字节流，逐块到达。
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:anoxia/common/constants/api.dart';
import 'package:anoxia/domain/ai_stream_event.dart';
import 'package:anoxia/framework/network/token_manager.dart';
import 'package:http/http.dart' as http;

/// 单条 SSE 帧
class SseFrame {
  SseFrame({this.event, required this.data});

  /// 事件名；匿名事件为 null
  final String? event;

  /// data 载荷原文
  final String data;

  bool get isNamed => event != null;
}

class SseClient {
  SseClient._();

  /// POST 并返回解析后的 SSE 帧流。
  ///
  /// 连接失败 / 非 2xx 抛 [AiException]（携带服务端或 HTTP 层具体文案）；
  /// HTTP 层成功但业务失败（如未登录）时，后端直接返回 JSON，此时没有合法 SSE 帧，
  /// 由调用方按「无 done 即失败」兜底处理。
  static Stream<SseFrame> post(String path, {Object? body}) async* {
    yield* _postHttp(path, body);
  }

  /// 全平台统一的真流式实现：基于 http.Client()。
  ///
  /// Web 与原生均逐块消费响应字节流，不会像 Dio 那样缓冲整段响应体，
  /// 因此 SSE 增量实时到达、长空窗不会被误判超时。
  static Stream<SseFrame> _postHttp(String path, Object? body) async* {
    final token = await TokenManager.instance.getToken();
    final url = Uri.parse('${API.httpBaseUrl}$path');
    final client = http.Client();
    try {
      final request = http.Request('POST', url);
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'text/event-stream';
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      if (body != null) {
        request.body = jsonEncode(body);
      }
      final streamed = await client.send(request);
      if (streamed.statusCode != 200) {
        String? errMsg;
        try {
          final bytes = await streamed.stream
              .fold<List<int>>(<int>[], (a, b) => a..addAll(b))
              .timeout(const Duration(seconds: 2));
          if (bytes.isNotEmpty) {
            final bodyStr = utf8.decode(bytes, allowMalformed: true);
            try {
              final j = jsonDecode(bodyStr);
              if (j is Map) {
                errMsg = (j['message'] ?? j['msg'] ?? j['error'])?.toString();
              }
              errMsg ??= bodyStr;
            } catch (_) {
              errMsg = bodyStr;
            }
          }
        } catch (_) {}
        throw AiException(errMsg ?? 'AI请求失败 请稍后在试');
      }
      yield* _parse(streamed.stream);
    } finally {
      client.close();
    }
  }

  @visibleForTesting
  static Stream<SseFrame> parseStream(Stream<List<int>> byteStream) =>
      _parse(byteStream);

  /// 字节流 → 行 → SSE 帧。
  ///
  /// 状态机：`event:` 暂存事件名；`data:` 追加载荷；空行派发一帧。
  /// 兼容：尾帧缺少空行时刷出、UTF-8 多字节跨 chunk、`:keepalive` 注释、多 data 行按规范以 \n 拼接。
  static Stream<SseFrame> _parse(Stream<List<int>> byteStream) async* {
    String? eventName;
    final dataBuf = StringBuffer();
    String pending = '';

    await for (final chunk in byteStream.transform(utf8.decoder)) {
      pending += chunk;
      while (true) {
        final idx = pending.indexOf('\n');
        if (idx < 0) break;
        var line = pending.substring(0, idx);
        pending = pending.substring(idx + 1);
        if (line.endsWith('\r')) line = line.substring(0, line.length - 1);

        if (line.isEmpty) {
          if (dataBuf.isEmpty) continue; // 心跳/空行
          final frame = SseFrame(event: eventName, data: dataBuf.toString());
          eventName = null;
          dataBuf.clear();
          yield frame;
          continue;
        }
        if (line.startsWith('event:')) {
          eventName = line.substring(6).trim();
        } else if (line.startsWith('data:')) {
          var payload = line.substring(5);
          if (payload.startsWith(' ')) payload = payload.substring(1);
          if (dataBuf.isNotEmpty) dataBuf.write('\n');
          dataBuf.write(payload);
        } else if (line.startsWith(':')) {
          continue;
        }
      }
    }
    if (pending.isNotEmpty) {
      // pending 可能含多行（如尾帧 event:done\ndata:json 缺末尾 \n），需逐行解析
      pending += '\n';
      while (true) {
        final idx = pending.indexOf('\n');
        if (idx < 0) break;
        var line = pending.substring(0, idx);
        pending = pending.substring(idx + 1);
        if (line.endsWith('\r')) line = line.substring(0, line.length - 1);
        if (line.isEmpty) {
          if (dataBuf.isEmpty) continue;
          final frame = SseFrame(event: eventName, data: dataBuf.toString());
          eventName = null;
          dataBuf.clear();
          yield frame;
          continue;
        }
        if (line.startsWith('event:')) {
          eventName = line.substring(6).trim();
        } else if (line.startsWith('data:')) {
          var payload = line.substring(5);
          if (payload.startsWith(' ')) payload = payload.substring(1);
          if (dataBuf.isNotEmpty) dataBuf.write('\n');
          dataBuf.write(payload);
        } else if (line.startsWith(':')) {
          continue;
        }
      }
    }
    if (dataBuf.isNotEmpty) {
      yield SseFrame(event: eventName, data: dataBuf.toString());
    }
  }
}
