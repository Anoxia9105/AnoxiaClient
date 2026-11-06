@TestOn('browser')
library;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;

import 'package:anoxia/common/widgets/quill_ime_binding_web.dart';

void main() {
  test('长文档输入元素不能使页面外层滚动露出空白', () {
    final body = web.document.body!;
    final root = web.document.documentElement! as web.HTMLElement;
    final originalStyle = body.style.cssText;
    final originalRootStyle = root.style.cssText;
    root.style.cssText = 'height:100%;overflow:hidden';
    body.style.cssText =
        'position:fixed;inset:0;height:200px;overflow:hidden;margin:0';
    final view = web.document.createElement('flutter-view') as web.HTMLElement;
    view.style.cssText = 'position:absolute;inset:0;display:block';
    final host = web.document.createElement('flt-text-editing-host');
    final input = web.HTMLTextAreaElement()
      ..className = 'flt-text-editing'
      ..value = 'Title\nBody\n'
      ..style.cssText =
          'position:absolute;left:0;top:0;width:300px;'
          'height:4000px;padding:0;border:0;font:16px/20px monospace';
    body.appendChild(view);
    view.appendChild(host);
    host.appendChild(input);
    input.focus();
    input.setSelectionRange(6, 6);
    final binding = QuillImeBinding(
      readCaret: () => const Rect.fromLTWH(40, 120, 2, 20),
      readText: () => input.value,
      readViewSize: () => Size.zero,
    );
    addTearDown(() {
      binding.dispose();
      view.remove();
      body.style.cssText = originalStyle;
      root.style.cssText = originalRootStyle;
      body.scrollTop = 0;
      root.scrollTop = 0;
    });
    binding.synchronize();
    // overflow:hidden 仍允许浏览器为聚焦光标进行程序化滚动。
    // 使用同一滚动通道验证：隐藏输入元素不能给外层增加可滚动空间。
    body.scrollTop = 500;
    root.scrollTop = 500;
    view.scrollTop = 500;
    expect(body.scrollTop, 0);
    expect(root.scrollTop, 0);
    expect(view.scrollTop, 0);
    expect(input.getBoundingClientRect().top + 40, closeTo(140, 1));
    for (var i = 0; i < 50; i++) {
      input.value += '\n';
      input.setSelectionRange(input.value.length, input.value.length);
      binding.synchronize();
      body.scrollTop = 500;
      root.scrollTop = 500;
      expect(body.scrollTop, 0, reason: '连续换行 ${i + 1} 次');
      expect(root.scrollTop, 0);
    }
    binding.stop();
    expect(view.style.overflow, isEmpty);
  });

  test('富文本定位补偿不修改输入内容，并在失焦后恢复元素', () {
    final view = web.document.createElement('flutter-view');
    final host = web.document.createElement('flt-text-editing-host');
    final input = web.HTMLTextAreaElement()
      ..className = 'flt-text-editing'
      ..value = 'Title\nBody\n'
      ..style.cssText =
          'position:fixed;left:20px;top:30px;'
          'width:300px;height:100px;font:16px/20px monospace;'
          'padding:0;border:0;transform:translate(0px, 0px)';
    web.document.body!.appendChild(view);
    view.appendChild(host);
    host.appendChild(input);
    input.focus();
    input.setSelectionRange(6, 6);
    var caret = const Rect.fromLTWH(200, 150, 2, 20);
    final binding = QuillImeBinding(
      readCaret: () => caret,
      readText: () => input.value,
      readViewSize: () => Size.zero,
    );
    addTearDown(() {
      binding.dispose();
      view.remove();
    });

    binding.synchronize();
    expect(input.style.getPropertyValue('translate'), isNotEmpty);
    expect(input.getBoundingClientRect().left, closeTo(200, 1));
    expect(input.getBoundingClientRect().top + 40, closeTo(170, 1));
    expect(input.value, 'Title\nBody\n');
    expect(input.selectionStart, 6);
    expect(input.selectionEnd, 6);
    final translation = input.style.getPropertyValue('translate');
    binding.synchronize();
    expect(input.style.getPropertyValue('translate'), translation);

    // 引擎更新 transform 后，补偿仍须对齐；不能和引擎争抢 transform。
    input.style.transform = 'translate(0px, -40px)';
    binding.synchronize();
    expect(input.style.transform, 'translate(0px, -40px)');
    expect(input.getBoundingClientRect().top + 40, closeTo(170, 1));
    expect(input.style.getPropertyValue('translate'), isNot(translation));
    // 同一份纯文本的标题高度变化，DOM 光标也应跟随实际富文本布局。
    caret = caret.translate(0, 35);
    binding.synchronize();
    expect(input.getBoundingClientRect().top + 40, closeTo(205, 1));
    input.value = '${List.filled(120, 'a').join()}\nBody\n';
    input.setSelectionRange(121, 121);
    binding.synchronize();
    // 300px 宽、16px 等宽字体：120 字符自动折为四行，再进入 Body 行。
    expect(input.getBoundingClientRect().top + 100, closeTo(205, 1));
    input.value = 'Title\nBody\n';
    input.setSelectionRange(6, 6);
    binding.synchronize();
    binding.stop();
    expect(input.style.getPropertyValue('translate'), isEmpty);
    expect(input.style.pointerEvents, isEmpty);
    expect(input.value, 'Title\nBody\n');
  });

  test('不接管普通输入框或其他 Flutter 输入连接', () {
    final host = web.document.createElement('flt-text-editing-host');
    final input = web.HTMLTextAreaElement()
      ..className = 'flt-text-editing'
      ..value = 'ordinary';
    web.document.body!.appendChild(host);
    host.appendChild(input);
    input.focus();
    final binding = QuillImeBinding(
      readCaret: () => const Rect.fromLTWH(200, 150, 2, 20),
      readText: () => 'quill',
      readViewSize: () => Size.zero,
    );
    addTearDown(() {
      binding.dispose();
      host.remove();
    });
    binding.synchronize();
    expect(input.style.getPropertyValue('translate'), isEmpty);
    expect(web.document.querySelector('[data-quill-ime-mirror]'), isNull);
  });
}
