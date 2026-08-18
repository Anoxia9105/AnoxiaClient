/// 记事本 Delta → PDF 生成
///
/// 使用纯 Dart `pdf` 包渲染：解析 Quill Delta 为行块，按标题/列表/任务/
/// 引用/代码块/对齐输出布局，行内支持粗/斜/下划线/删除线/行内代码/链接；
/// 图片 embed 预拉取字节后嵌入（失败降级为 [图片] 占位）。
/// 嵌入 CJK 字体 assets/fonts/HarmonyOS.ttf，web/wasm 均可运行。
library;

// ignore_for_file: prefer_const_constructors

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;

/// 生成笔记 PDF 字节流
Future<Uint8List> buildNotePdf({
  required String title,
  required String deltaJson,
  String? updatedAtLabel,
  String untitled = '',
  String emptyContent = '',
}) async {
  final font = pw.Font.ttf(await rootBundle.load('assets/fonts/HarmonyOS.ttf'));
  final blocks = _extractBlocks(deltaJson);
  final images = await _fetchImages(blocks);

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: pw.PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 56),
      theme: pw.ThemeData.withFont(
        base: font,
        bold: font,
        italic: font,
        boldItalic: font,
      ),
      build: (_) => [
        pw.Text(
          title.trim().isEmpty ? untitled : title.trim(),
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
        if (updatedAtLabel != null && updatedAtLabel.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            updatedAtLabel,
            style: const pw.TextStyle(fontSize: 9, color: pw.PdfColors.grey600),
          ),
        ],
        pw.Divider(color: pw.PdfColors.grey400, height: 18),
        if (blocks.isEmpty)
          pw.Text(
            emptyContent,
            style: const pw.TextStyle(fontSize: 11, color: pw.PdfColors.grey500),
          )
        else
          ..._buildContent(blocks, images),
      ],
    ),
  );
  return doc.save();
}

// ===================== 解析 =====================

class _PdfLine {
  final List<_PdfRun> runs;
  final Map<String, dynamic>? attrs;

  const _PdfLine(this.runs, this.attrs);
}

class _PdfRun {
  final String text;
  final Map<String, dynamic>? attrs;

  const _PdfRun(this.text, this.attrs);
}

class _PdfImage {
  final String url;

  const _PdfImage(this.url);
}

List<Object> _extractBlocks(String deltaJson) {
  Document doc;
  try {
    final json = jsonDecode(deltaJson);
    doc = json is List ? Document.fromJson(json) : Document();
  } catch (_) {
    doc = Document();
  }

  final blocks = <Object>[];
  final runs = <_PdfRun>[];
  void flushLine(Map<String, dynamic>? attrs) {
    blocks.add(_PdfLine(List.of(runs), attrs));
    runs.clear();
  }

  for (final op in doc.toDelta().toList()) {
    final data = op.data;
    if (data is String) {
      final parts = data.split('\n');
      for (var i = 0; i < parts.length; i++) {
        final seg = parts[i];
        if (seg.isNotEmpty) runs.add(_PdfRun(seg, op.attributes));
        if (i < parts.length - 1) flushLine(op.attributes);
      }
    } else if (data is Map && data['image'] != null) {
      if (runs.isNotEmpty) flushLine(op.attributes);
      blocks.add(_PdfImage(data['image'].toString()));
    }
  }
  if (runs.isNotEmpty) blocks.add(_PdfLine(List.of(runs), null));
  return blocks;
}

Future<Map<String, Uint8List>> _fetchImages(List<Object> blocks) async {
  final urls = blocks
      .whereType<_PdfImage>()
      .map((b) => b.url)
      .where((u) => u.startsWith('http'))
      .toSet();
  final map = <String, Uint8List>{};
  for (final url in urls) {
    try {
      final resp = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
        map[url] = resp.bodyBytes;
      }
    } catch (_) {
      // 图片拉取失败降级为占位
    }
  }
  return map;
}

// ===================== 布局 =====================

List<pw.Widget> _buildContent(
  List<Object> blocks,
  Map<String, Uint8List> images,
) {
  final widgets = <pw.Widget>[];
  final codeLines = <pw.Widget>[];

  void flushCodeBlock() {
    if (codeLines.isEmpty) return;
    widgets.add(
      pw.Container(
        margin: const pw.EdgeInsets.symmetric(vertical: 4),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: pw.PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: codeLines),
      ),
    );
    codeLines.clear();
  }

  var orderedCounter = 0;
  for (final block in blocks) {
    if (block is _PdfImage) {
      flushCodeBlock();
      orderedCounter = 0;
      widgets.add(_imageWidget(block.url, images));
      continue;
    }

    final line = block as _PdfLine;
    final attrs = line.attrs ?? const <String, dynamic>{};
    if (attrs['code-block'] == true) {
      codeLines.add(
        pw.Text(
          line.runs.map((r) => r.text).join(),
          style: const pw.TextStyle(fontSize: 10),
        ),
      );
      continue;
    }

    flushCodeBlock();
    orderedCounter = attrs['list'] == 'ordered' ? orderedCounter + 1 : 0;
    widgets.add(_lineWidget(line, orderedCounter));
  }
  flushCodeBlock();
  return widgets;
}

pw.Widget _lineWidget(_PdfLine line, int orderedCounter) {
  final attrs = line.attrs ?? const <String, dynamic>{};
  final header = attrs['header'];
  final list = attrs['list'];
  final blockquote = attrs['blockquote'] == true;
  final align = attrs['align'];

  final spans = line.runs.map((r) => _runToSpan(r)).toList();
  final baseStyle = const pw.TextStyle(fontSize: 11, color: pw.PdfColors.grey900);
  final textAlign = switch (align) {
    'center' => pw.TextAlign.center,
    'right' => pw.TextAlign.right,
    _ => pw.TextAlign.left,
  };

  pw.RichText rich([pw.TextStyle? style]) {
    return pw.RichText(
      text: pw.TextSpan(
        children: spans,
        style: baseStyle.merge(style ?? const pw.TextStyle()),
      ),
      textAlign: textAlign,
    );
  }

  pw.Widget? result;
  if (header == 1) {
    result = pw.Padding(
      padding: const pw.EdgeInsets.only(top: 6, bottom: 4),
      child: rich(pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
    );
  } else if (header == 2) {
    result = pw.Padding(
      padding: const pw.EdgeInsets.only(top: 5, bottom: 3),
      child: rich(pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
    );
  } else if (header == 3) {
    result = pw.Padding(
      padding: const pw.EdgeInsets.only(top: 4, bottom: 2),
      child: rich(pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
    );
  } else if (list != null) {
    final marker = switch (list) {
      'bullet' => '\u2022',
      'ordered' => '$orderedCounter.',
      'checked' => '\u2611',
      'unchecked' => '\u2610',
      _ => '\u2022',
    };
    result = pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 26, child: pw.Text(marker, style: baseStyle)),
          pw.Expanded(child: rich()),
        ],
      ),
    );
  } else if (blockquote) {
    result = pw.Container(
      padding: const pw.EdgeInsets.only(left: 8, top: 2, bottom: 2),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(color: pw.PdfColors.grey500, width: 3),
        ),
      ),
      child: rich(pw.TextStyle(fontStyle: pw.FontStyle.italic)),
    );
  } else {
    result = rich();
  }

  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 1),
    child: result,
  );
}

pw.TextSpan _runToSpan(_PdfRun run) {
  final attrs = run.attrs ?? const <String, dynamic>{};
  final link = attrs['link'];
  var style = pw.TextStyle();
  if (attrs['bold'] == true) {
    style = style.copyWith(fontWeight: pw.FontWeight.bold);
  }
  if (attrs['italic'] == true) {
    style = style.copyWith(fontStyle: pw.FontStyle.italic);
  }
  if (attrs['underline'] == true) {
    style = style.copyWith(decoration: pw.TextDecoration.underline);
  }
  if (attrs['strike'] == true) {
    style = style.copyWith(decoration: pw.TextDecoration.lineThrough);
  }
  if (attrs['code'] == true) {
    style = style.copyWith(
      color: pw.PdfColors.grey800,
      background: pw.BoxDecoration(
        color: pw.PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(2),
      ),
    );
  }
  if (link is String && link.isNotEmpty) {
    style = style.copyWith(color: pw.PdfColors.blue600);
  }
  return pw.TextSpan(text: run.text, style: style);
}

pw.Widget _imageWidget(String url, Map<String, Uint8List> images) {
  final bytes = images[url];
  if (bytes == null) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Text('[image]', style: const pw.TextStyle(fontSize: 10, color: pw.PdfColors.grey500)),
    );
  }
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Image(
      pw.MemoryImage(bytes),
      fit: pw.BoxFit.contain,
      width: 400,
    ),
  );
}
