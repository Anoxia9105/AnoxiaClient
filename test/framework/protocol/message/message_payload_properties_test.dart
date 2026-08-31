import 'package:anoxia/features/note/presentation/widgets/note_card_content.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CardPayload properties 兼容服务端 List[{key,value}] 格式', () {
    test('Map 格式（当前本地缓存序列化）', () {
      final card = CardPayload.fromJson({
        'cardType': 'note',
        'properties': {
          'content': '第一行\n第二行',
          'ownerId': '42',
        },
      });

      expect(card.properties['content'], '第一行\n第二行');
      expect(card.properties['ownerId'], '42');
    });

    test('List[{key,value}] 格式（REST 历史接口）', () {
      final card = CardPayload.fromJson({
        'cardType': 'note',
        'entityId': '7',
        'properties': [
          {'key': 'content', 'value': '第一行\n第二行'},
          {'key': 'ownerId', 'value': '42'},
        ],
      });

      expect(card.properties['content'], '第一行\n第二行');
      expect(card.properties['ownerId'], '42');
    });

    test('List 格式支持 k/v 短键名', () {
      final card = CardPayload.fromJson({
        'cardType': 'note',
        'properties': [
          {'k': 'noteId', 'v': '9'},
        ],
      });

      expect(card.properties['noteId'], '9');
    });

    test('未知格式返回空 Map', () {
      final card = CardPayload.fromJson({
        'cardType': 'note',
        'properties': 'not-a-map',
      });

      expect(card.properties, isEmpty);
    });
  });

  group('resolveNoteCardContent / unescapeEscapedNewlines', () {
    test('优先取 properties.content，保留真实换行', () {
      const card = CardPayload(
        cardType: 'note',
        summary: '单行摘要',
        properties: {'content': '第一行\n第二行\n第三行'},
      );

      expect(resolveNoteCardContent(card), '第一行\n第二行\n第三行');
    });

    test('字面 \\n 双编码内容被还原为多行', () {
      const card = CardPayload(
        cardType: 'note',
        summary: '单行摘要',
        properties: {'content': r'第一行\n第二行\n第三行'},
      );

      expect(resolveNoteCardContent(card), '第一行\n第二行\n第三行');
    });

    test('缺 content 时回退到摘要', () {
      const card = CardPayload(
        cardType: 'note',
        summary: '单行摘要',
        properties: {},
      );

      expect(resolveNoteCardContent(card), '单行摘要');
    });

    test('正常包含反斜杠的文本不被误替换', () {
      expect(
        unescapeEscapedNewlines(r'路径 C:\notes\a.txt'),
        r'路径 C:\notes\a.txt',
      );
      expect(unescapeEscapedNewlines(r'路径 C:\temp'), r'路径 C:\temp');
      expect(unescapeEscapedNewlines('已有真实\n换行'), '已有真实\n换行');
    });
  });
}
