/// POST 方式消费后端 SSE 流（AI 聊天 / 笔记 AI）
///
/// 后端协议（AnoxiaServer AiChatController/NoteAiController）：
/// - 匿名事件：`data:<增量文本>`（多次，纯文本）
/// - 命名事件：`event:done` + `data:{json}`、`event:error` + `data:{json}`
///
/// EventSource 不支持 POST，因此基于 Dio 的 ResponseType.stream 手工解析。
library;

import 'dart:convert';

import 'package:anoxia/common/constants/api.dart';
import 'package:anoxia/framework/network/token_manager.dart';
import 'package:dio/dio.dart';

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

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: API.httpBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      // 整体时长由服务端 sse-timeout 兜底，这里不设 receiveTimeout
      responseType: ResponseType.stream,
      headers: {'Accept': 'text/event-stream'},
    ),
  );

  /// POST 并返回解析后的 SSE 帧流。
  ///
  /// 连接失败/5xx 抛 [DioException]；HTTP 层成功但业务失败（如未登录）时
  /// 后端直接返回 JSON，此时没有合法 SSE 帧，由调用方按「无 done 即失败」兜底处理。
  static Stream<SseFrame> post(String path, {Object? body}) async* {
    final token = await TokenManager.instance.getToken();
    final Response<ResponseBody> resp = await _dio.post<ResponseBody>(
      path,
      data: body,
      options: Options(
        headers: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
        validateStatus: (code) => code != null && code < 500,
      ),
    );

    if (resp.statusCode != 200 || resp.data == null) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        response: resp,
        type: DioExceptionType.badResponse,
        error: 'SSE HTTP ${resp.statusCode}',
      );
    }

    yield* _parse(resp.data!.stream);
  }

  /// 字节流 → 行 → SSE 帧。
  ///
  /// 状态机：`event:` 暂存事件名；`data:` 追加载荷；空行派发一帧。
  static Stream<SseFrame> _parse(Stream<List<int>> byteStream) async* {
    String? eventName;
    StringBuffer dataBuf = StringBuffer();
    String pending = '';

    await for (final chunk in byteStream) {
      pending += utf8.decode(chunk, allowMalformed: true);
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
          dataBuf = StringBuffer();
          yield frame;
          continue;
        }
        if (line.startsWith('event:')) {
          eventName = line.substring(6).trim();
        } else if (line.startsWith('data:')) {
          var payload = line.substring(5);
          if (payload.startsWith(' ')) payload = payload.substring(1);
          dataBuf.write(payload);
        }
      }
    }
  }
}
