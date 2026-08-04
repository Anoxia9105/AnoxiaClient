/// 回归测试：WASM 富文本「测量宽度」与「渲染宽度」一致。
///
/// `SelectableText.rich` 会把 `DefaultTextStyle` 合并到 span 样式上
/// （详见 flutter `packages/flutter/lib/src/material/selectable_text.dart`），
/// 于是 span 中为 null 的属性会继承气泡默认样式（M3 bodyMedium 默认
/// `letterSpacing: 0.25`）。
///
/// 旧代码测量时用裸 span 样式（不含继承字距），渲染时却走合并 —— 测量值小于
/// 实际渲染宽度，最后一个字被挤到第二行。
///
/// 宿主环境下 `QuillMessageStrategy` 的 WASM 分支受 `dart.library.html`
/// 编译常量控制不会执行，因此本测试直接复刻该分支的「测量 → 渲染」流程，
/// 断言：用合并样式测出的宽度，能让渲染样式单行显示；用裸样式测出的宽度，
/// 会把最后一个字挤到第二行。
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const fontSize = 14.0;
  const letterSpacing = 0.25; // M3 bodyMargin 默认
  // 20 个等宽字幕刚好接近 280px，但又小于 400px maxWidth，便于做包界判断。
  const text = '这是一条单行消息最后一个字挨不起来啊。';
  const maxWidth = 400.0;

  /// 测量函数：模仿
  /// `quill_message_strategy.dart::_measureInlineContentWidth` 的策略
  /// （最长行宽 → ceil +2），支持传入任意样式。
  double measureWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(style: style, text: text),
      textDirection: ui.TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: maxWidth);

    var widest = 0.0;
    for (final line in painter.computeLineMetrics()) {
      if (line.width > widest) {
        widest = line.width;
      }
    }
    return widest.ceilToDouble() + 2;
  }

  /// 在给定宽度下，用指定渲染样式（模拟 SelectableText 合并后的样式）排版，
  /// 返回行数。行数 > 1 表示换行。
  int layoutLineCount(String text, TextStyle style, double width) {
    final painter = TextPainter(
      text: TextSpan(style: style, text: text),
      textDirection: ui.TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: width);
    return painter.computeLineMetrics().length;
  }

  test('继承 letterSpacing 使合并样式测出更宽（bug root cause）', () {
    const defaultStyle = TextStyle(fontSize: fontSize, letterSpacing: letterSpacing);
    const spanStyle = TextStyle(color: Colors.black, fontSize: fontSize);

    final bare = measureWidth(text, spanStyle);
    final merged = measureWidth(text, defaultStyle.merge(spanStyle));

    expect(merged, greaterThan(bare));
  });

  testWidgets('裸样式测宽度会挤换行，合并样式测宽度单行显示', (tester) async {
    // 模拟 SelectableText.rich 最终会合并的样式。
    const defaultStyle = TextStyle(fontSize: fontSize, letterSpacing: letterSpacing);
    const spanStyle = TextStyle(color: Colors.black, fontSize: fontSize, height: 1.4);
    final mergedStyle = defaultStyle.merge(spanStyle);

    final fixedBubbleWidth = measureWidth(text, mergedStyle);
    final buggyBubbleWidth = measureWidth(text, spanStyle);

    // 修复后：用合并样式测出的气泡宽度 → 渲染样式单行。
    expect(
      layoutLineCount(text, mergedStyle, fixedBubbleWidth),
      lessThan(2),
    );
    // 旧 bug：用裸样式测出的气泡宽度 → 渲染样式最后一个字换行。
    expect(
      layoutLineCount(text, mergedStyle, buggyBubbleWidth),
      greaterThanOrEqualTo(2),
    );
  });

  /// 模仿 `_wasmMentionSize`：返回含 margin 的胶囊完整宽（文本 + padding(4+4) + margin(2+2)）。
  double mentionPillWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
      textScaler: TextScaler.noScaling,
      maxLines: 1,
    )..layout();
    return painter.width + 12;
  }

  test('mention 裸样式测量窄于合并样式（mention bug root cause）', () {
    const defaultStyle = TextStyle(
      fontSize: fontSize,
      letterSpacing: letterSpacing,
    );
    const mentionStyle = TextStyle(
      color: Colors.red,
      fontWeight: FontWeight.bold,
      fontSize: fontSize,
      height: 1,
    );

    // 修复前：`_wasmMentionSize` 用裸样式测量；渲染时 Text 会继承
    // DefaultTextStyle 的 letterSpacing，实际宽度大于测量值，胶囊不够宽。
    expect(
      mentionPillWidth('@CC3', defaultStyle.merge(mentionStyle)),
      greaterThan(mentionPillWidth('@CC3', mentionStyle)),
    );
  });

  testWidgets('胶囊尺寸含 margin 时文本完整落于 padding 内', (tester) async {
    const text = '@CC3';
    const style = TextStyle(
      color: Colors.red,
      fontWeight: FontWeight.bold,
      fontSize: fontSize,
      height: 1,
    );
    const marginH = 2.0;
    const paddingH = 4.0;
    const paddingV = 2.0;

    final painter = TextPainter(
      text: const TextSpan(text: '@CC3', style: style),
      textDirection: ui.TextDirection.ltr,
      textScaler: TextScaler.noScaling,
      maxLines: 1,
    )..layout();
    final textWidth = painter.width;

    Widget pill(Size size) => SizedBox.fromSize(
          size: size,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: marginH),
            padding: const EdgeInsets.symmetric(
              horizontal: paddingH,
              vertical: paddingV,
            ),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '@CC3',
              maxLines: 1,
              softWrap: false,
              style: style,
            ),
          ),
        );

    // 修复后尺寸：宽 = 文本 + padding(8) + margin(4)，内容区内文本恰好完整。
    final fixedSize = Size(textWidth + 12, painter.height + 4);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: pill(fixedSize))));
    // 内容区宽度 == 文本自然宽度，整段文字完整放下，不会溢出。
    expect(
      tester.getSize(find.text(text)).width,
      closeTo(textWidth, 0.5),
    );

    // 旧尺寸：宽未计入 margin，紧约束下内容区窄 4px，文本盒小于自然宽度，
    // 最后一个字被溢出/裁掉（“没有显示全”）。
    final buggySize = Size(textWidth + 8, painter.height + 4);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: pill(buggySize))));
    expect(
      tester.getSize(find.text(text)).width,
      lessThan(textWidth - 1),
    );
  });
}