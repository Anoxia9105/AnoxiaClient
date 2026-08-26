import 'dart:convert';

import 'package:anoxia/framework/network/sse_client.dart';
import 'package:flutter_test/flutter_test.dart';

Stream<List<int>> chunks(List<String> parts) async* {
  for (final p in parts) {
    yield utf8.encode(p);
  }
}

Stream<List<int>> utf8SplitChunks(String text, int splitAt) async* {
  final bytes = utf8.encode(text);
  yield bytes.sublist(0, splitAt);
  yield bytes.sublist(splitAt);
}

void main() {
  group('SseClient 尾帧刷出回归', () {
    test('末尾缺少空行时仍应产出 done 帧', () async {
      const payload =
          'data:hello\n\n'
          'event:done\n'
          'data:{"text":"hello","conversationId":"c1"}\n'; // 无末尾空行
      final stream = Stream<List<int>>.value(utf8.encode(payload));
      final frames = await SseClient.parseStream(stream).toList();
      expect(frames.length, 2);
      expect(frames[0].event, isNull);
      expect(frames[0].data, 'hello');
      expect(frames[1].event, 'done');
      expect(frames[1].data.contains('hello'), isTrue);
    });

    test('中文多字节被切分时不应乱码', () async {
      const text = '你好，世界';
      final sse = 'data:$text\n\n';
      final bytes = utf8.encode(sse);
      final split = 7; // 故意落在多字节中间
      final stream = Stream<List<int>>.fromIterable([
        bytes.sublist(0, split),
        bytes.sublist(split),
      ]);
      final frames = await SseClient.parseStream(stream).toList();
      expect(frames.length, 1);
      expect(frames[0].data, text);
      expect(frames[0].data.contains('�'), isFalse);
    });

    test('多 data 行应以换行拼接', () async {
      const payload = 'data:hello\n'
          'data:world\n'
          '\n';
      final frames = await SseClient.parseStream(chunks([payload])).toList();
      expect(frames.length, 1);
      expect(frames[0].data, 'hello\nworld');
    });

    test('匿名增量跨 chunk 边界不应丢帧', () async {
      final frames = await SseClient.parseStream(chunks([
        'data:hel',
        'lo\n\n',
        'data: world\n\n',
      ])).toList();
      // 第二帧 data: world -> 去除冒号后单空格，得到 "world"
      expect(frames.map((f) => f.data).toList(), ['hello', 'world']);
    });

    test('思考与 done 混合流应完整解析', () async {
      const payload =
          'event:thinking\n'
          'data:思考中\n'
          '\n'
          'data:正文增量1\n'
          '\n'
          'data:正文增量2\n'
          '\n'
          'event:done\n'
          'data:{"text":"正文增量1正文增量2","conversationId":"c1"}\n'
          '\n';
      final frames = await SseClient.parseStream(chunks([
        payload.substring(0, 20),
        payload.substring(20, 50),
        payload.substring(50),
      ])).toList();
      expect(frames.length, 4);
      expect(frames[0].event, 'thinking');
      expect(frames[1].data, '正文增量1');
      expect(frames[2].data, '正文增量2');
      expect(frames[3].event, 'done');
    });

    test('仅有增量无 done 时尾帧应可被 onDone 兜底消费', () async {
      const payload = 'data:partial hello\n\n'
          'data:partial world\n'; // 无 done、无末尾空行，模拟提前断连
      final frames = await SseClient.parseStream(chunks([payload])).toList();
      expect(frames.length, 2);
      expect(frames[0].data, 'partial hello');
      expect(frames[1].data, 'partial world');
    });

    test('keepalive 注释行应被忽略', () async {
      const payload = ':keepalive\n\n'
          'data:hi\n\n';
      final frames = await SseClient.parseStream(chunks([payload])).toList();
      expect(frames.length, 1);
      expect(frames[0].data, 'hi');
    });
  });
}
