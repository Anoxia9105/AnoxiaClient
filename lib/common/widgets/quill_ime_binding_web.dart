import 'dart:js_interop';

import 'package:flutter/painting.dart';
import 'package:web/web.dart' as web;

/// 补偿浏览器纯文本光标与 Quill 富文本光标之间的布局差。
/// 不重建输入连接，不改 value、selection 或 composing，也不覆盖引擎的 transform。
class QuillImeBinding {
  QuillImeBinding({
    required this.readCaret,
    required this.readText,
    required this.readViewSize,
  });

  final Rect? Function() readCaret;
  final String Function() readText;
  final Size Function() readViewSize;
  web.HTMLTextAreaElement? _input;
  web.HTMLDivElement? _mirror;
  web.HTMLSpanElement? _marker;
  web.HTMLElement? _view;
  String _viewOverflow = '';
  String _viewOverflowPriority = '';
  final Map<String, String> _original = {};
  Offset _translation = Offset.zero;
  Offset _textCaret = Offset.zero;
  (String, int, String)? _measurementKey;
  int? _frame;
  bool _running = false;

  void start() {
    if (_running) return;
    _running = true;
    _scheduleFrame();
  }

  void _scheduleFrame() {
    _frame = web.window.requestAnimationFrame(
      ((num _) {
        _frame = null;
        if (!_running) return;
        synchronize();
        _scheduleFrame();
      }).toJS,
    );
  }

  /// 只接管当前 Quill 焦点对应的 Flutter textarea。
  /// 每个浏览器帧读取最终布局，覆盖外层滚动及引擎异步几何更新。
  void synchronize() {
    final caret = readCaret();
    // 布局中的短暂 dirty 状态不能中断正在进行的组合输入定位。
    if (caret == null || !caret.isFinite) return;
    final active = web.document.activeElement;
    if (active == null || !active.isA<web.HTMLTextAreaElement>()) {
      _release();
      return;
    }
    final input = active as web.HTMLTextAreaElement;
    if (!input.classList.contains('flt-text-editing') ||
        input.closest('flt-text-editing-host') == null) {
      _release();
      return;
    }
    if (_input != input) {
      _release();
      if (input.value != readText()) return;
      _input = input;
      final view = input.closest('flutter-view');
      if (view != null && view.isA<web.HTMLElement>()) {
        _view = view as web.HTMLElement;
        _viewOverflow = _view!.style.getPropertyValue('overflow');
        _viewOverflowPriority = _view!.style.getPropertyPriority('overflow');
        // 移位后的整篇 textarea 不能扩大 body 的滚动范围。
        // hidden 仍是可程序化滚动的容器，clip 才能隔离聚焦时的滚动链。
        // https://developer.mozilla.org/en-US/docs/Web/CSS/overflow
        _view!.style.setProperty('overflow', 'clip');
      }
      for (final property in ['translate', 'pointer-events', 'line-height']) {
        _original[property] = input.style.getPropertyValue(property);
      }
      // 鼠标选区仍由 Flutter 处理，移位后的透明 textarea 不应拦截指针。
      input.style.pointerEvents = 'none';
    }

    final lineHeight = '${caret.height}px';
    if (input.style.lineHeight != lineHeight) {
      input.style.lineHeight = lineHeight;
    }
    final style = web.window.getComputedStyle(input);
    _measureTextCaret(input, style);
    final box = input.getBoundingClientRect();
    // 引擎的布局矩阵通常只平移；比例取自实际 DOM，兼容页面缩放。
    final scaleX = input.offsetWidth == 0 ? 1.0 : box.width / input.offsetWidth;
    final scaleY = input.offsetHeight == 0
        ? 1.0
        : box.height / input.offsetHeight;
    final nativeCaret = Offset(
      box.left + (_textCaret.dx - input.scrollLeft) * scaleX,
      box.top + (_textCaret.dy - input.scrollTop + caret.height) * scaleY,
    );
    var target = caret.bottomLeft;
    final view = input.closest('flutter-view');
    final viewSize = readViewSize();
    if (view != null && !viewSize.isEmpty) {
      final bounds = view.getBoundingClientRect();
      target = Offset(
        bounds.left + target.dx * bounds.width / viewSize.width,
        bounds.top + target.dy * bounds.height / viewSize.height,
      );
    }
    final delta = target - nativeCaret;
    if (delta.distance < 0.1) return;
    _translation += delta;
    // CSS translate 独立于 transform，避免与 Flutter 的几何同步互相覆盖。
    // https://developer.mozilla.org/en-US/docs/Web/CSS/translate
    input.style.setProperty(
      'translate',
      '${_translation.dx}px ${_translation.dy}px',
    );
  }

  void _measureTextCaret(
    web.HTMLTextAreaElement input,
    web.CSSStyleDeclaration style,
  ) {
    final properties = <String, String>{
      for (final name in [
        'box-sizing',
        'width',
        'padding-top',
        'padding-right',
        'padding-bottom',
        'padding-left',
        'border-top-width',
        'border-right-width',
        'border-bottom-width',
        'border-left-width',
        'border-style',
        'font-family',
        'font-size',
        'font-weight',
        'font-style',
        'font-variant',
        'line-height',
        'letter-spacing',
        'word-spacing',
        'text-align',
        'text-indent',
        'text-transform',
        'direction',
        'tab-size',
        'white-space',
        'overflow-wrap',
        'word-break',
      ])
        name: style.getPropertyValue(name),
    };
    final position = input.selectionDirection == 'backward'
        ? input.selectionStart
        : input.selectionEnd;
    final key = (input.value, position, properties.values.join(';'));
    if (_measurementKey == key) return;
    _measurementKey = key;
    final mirror = _mirror ??= web.HTMLDivElement()
      ..setAttribute('data-quill-ime-mirror', '')
      ..setAttribute('aria-hidden', 'true');
    final marker = _marker ??= web.HTMLSpanElement();
    if (!mirror.isConnected) web.document.body!.appendChild(mirror);
    mirror.style.cssText =
        'position:fixed;left:0;top:0;visibility:hidden;'
        'pointer-events:none;height:0;contain:strict;overflow:clip;';
    for (final entry in properties.entries) {
      mirror.style.setProperty(entry.key, entry.value);
    }
    // span 的 offsetTop 包含字形相对行框的偏移；先测首行基线，
    // 避免把该偏移再次叠加到 textarea 原生光标的行高上。
    mirror.textContent = '';
    marker.textContent = '.';
    mirror.appendChild(marker);
    final firstLineTop = marker.offsetTop;
    // 用 textContent，文本永远不作为 HTML 解释；保留后缀以匹配自动换行。
    mirror.textContent = input.value.substring(0, position);
    marker.textContent = input.value.substring(position).isEmpty
        ? '.'
        : input.value.substring(position);
    mirror.appendChild(marker);
    _textCaret = Offset(
      marker.offsetLeft +
          (double.tryParse(style.borderLeftWidth.replaceAll('px', '')) ?? 0),
      marker.offsetTop -
          firstLineTop +
          (double.tryParse(style.paddingTop.replaceAll('px', '')) ?? 0) +
          (double.tryParse(style.borderTopWidth.replaceAll('px', '')) ?? 0),
    );
  }

  void _release() {
    final input = _input;
    if (input != null) {
      for (final entry in _original.entries) {
        if (entry.value.isEmpty) {
          input.style.removeProperty(entry.key);
        } else {
          input.style.setProperty(entry.key, entry.value);
        }
      }
    }
    final view = _view;
    if (view != null) {
      if (_viewOverflow.isEmpty) {
        view.style.removeProperty('overflow');
      } else {
        view.style.setProperty(
          'overflow',
          _viewOverflow,
          _viewOverflowPriority,
        );
      }
    }
    _view = null;
    _viewOverflow = '';
    _viewOverflowPriority = '';
    _input = null;
    _original.clear();
    _translation = Offset.zero;
    _measurementKey = null;
    _mirror?.remove();
    _mirror = null;
    _marker = null;
  }

  void stop() {
    _running = false;
    final frame = _frame;
    if (frame != null) web.window.cancelAnimationFrame(frame);
    _frame = null;
    _release();
  }

  void dispose() => stop();
}
