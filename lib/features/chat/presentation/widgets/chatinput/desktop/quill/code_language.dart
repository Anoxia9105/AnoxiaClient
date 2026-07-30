/// Quill 编辑器代码语言定义与检测工具。
///
/// 提供代码语言数据模型和基于正则的代码语言自动检测，
/// 不依赖 highlight.js 的 auto-detect 以避免安全风险。
import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';

/// 代码语言数据模型。
class CodeLanguage {
  /// 语言标识符，如 'dart'、'python'。
  final String id;

  /// 语言显示名称，如 'Dart'、'Python'。
  final String label;

  const CodeLanguage(this.id, this.label);
}

/// Safe code-language detection that never invokes highlight.js auto-detect.
abstract final class CodeLanguageDetector {
  /// 纯文本（默认语言）。
  static const plainText = CodeLanguage('plaintext', 'Plain Text');

  /// 支持的代码语言列表。
  static const supported = <CodeLanguage>[
    CodeLanguage('dart', 'Dart'),
    CodeLanguage('javascript', 'JavaScript'),
    CodeLanguage('typescript', 'TypeScript'),
    CodeLanguage('python', 'Python'),
    CodeLanguage('java', 'Java'),
    CodeLanguage('cpp', 'C/C++'),
    CodeLanguage('csharp', 'C#'),
    CodeLanguage('json', 'JSON'),
    CodeLanguage('xml', 'HTML/XML'),
    CodeLanguage('css', 'CSS'),
    CodeLanguage('sql', 'SQL'),
    CodeLanguage('bash', 'Shell'),
    CodeLanguage('yaml', 'YAML'),
    plainText,
  ];

  /// 根据 Quill 节点的属性解析代码语言。
  ///
  /// 优先读取节点上的 [Attribute.codeBlock] 属性，
  /// 未设置时对文本内容进行自动检测。
  static CodeLanguage resolveForLine(Node line) {
    final attribute = line.style.attributes[Attribute.codeBlock.key];
    final selected = attribute?.value;
    if (selected is String) {
      final language = fromId(selected);
      if (language != null) return language;
    }

    final block = line.parent;
    return detect(block?.toPlainText() ?? line.toPlainText());
  }

  /// 根据语言标识符查找对应的 [CodeLanguage]。
  ///
  /// [id] 语言标识符（不区分大小写），找不到时返回 `null`。
  static CodeLanguage? fromId(String id) {
    final normalized = id.toLowerCase();
    for (final language in supported) {
      if (language.id == normalized) return language;
    }
    return null;
  }

  /// 基于正则表达式自动检测源代码的语言类型。
  ///
  /// [source] 源代码文本，无法识别时返回 [plainText]。
  static CodeLanguage detect(String source) {
    final text = source.trim();
    if (text.isEmpty) return plainText;

    if ((text.startsWith('{') || text.startsWith('[')) && _isJson(text)) {
      return fromId('json')!;
    }
    if (RegExp(
      r'<!doctype\s+html|<html\b|</?[a-z][^>]*>',
      caseSensitive: false,
    ).hasMatch(text)) {
      return fromId('xml')!;
    }
    if (RegExp(r'^\s*#!.*\b(?:ba|z|fi)?sh\b', multiLine: true).hasMatch(text) ||
        RegExp(r'\b(?:echo|chmod|grep|sed|awk)\b|\$\([^)]+\)').hasMatch(text)) {
      return fromId('bash')!;
    }
    if (RegExp(
      r'\b(?:SELECT|INSERT|UPDATE|DELETE|CREATE|ALTER)\b',
      caseSensitive: false,
    ).hasMatch(text)) {
      return fromId('sql')!;
    }
    if (RegExp(
      r'\busing\s+System\b|\bnamespace\s+\w+|Console\.WriteLine',
    ).hasMatch(text)) {
      return fromId('csharp')!;
    }
    if (RegExp(r'#include\s*[<"]|std::|\b(?:cout|cin)\s*<<').hasMatch(text)) {
      return fromId('cpp')!;
    }
    if (RegExp(
      r'\bpackage\s+[\w.]+;|\bimport\s+java\.|System\.out\.println',
    ).hasMatch(text)) {
      return fromId('java')!;
    }
    if (RegExp(
      r'\binterface\s+\w+|:\s*(?:string|number|boolean)\b',
    ).hasMatch(text)) {
      return fromId('typescript')!;
    }
    if (RegExp(
      r'\bpackage:|@override\b|\bWidget\s+build\b|\blate\s+final\b|'
      r'\bvoid\s+main\s*\(|\b(?:Future|Stream)<[^>]+>\s+\w+\s*\(',
    ).hasMatch(text)) {
      return fromId('dart')!;
    }
    if (RegExp(
      r'^\s*(?:def|class)\s+\w+.*:\s*$|\bfrom\s+\w+\s+import\b',
      multiLine: true,
    ).hasMatch(text)) {
      return fromId('python')!;
    }
    if (RegExp(
      r'\b(?:const|let|var)\s+\w+|=>|\bfunction\s+\w+',
    ).hasMatch(text)) {
      return fromId('javascript')!;
    }
    if (RegExp(
          r'^[^{]+\{(?:[^{}]|\{[^{}]*\})*\}',
          multiLine: true,
        ).hasMatch(text) &&
        RegExp(r'[\w-]+\s*:\s*[^;{}]+;').hasMatch(text)) {
      return fromId('css')!;
    }
    if (RegExp(r'^\s*[\w.-]+\s*:\s*.+$', multiLine: true).hasMatch(text)) {
      return fromId('yaml')!;
    }
    return plainText;
  }

  static bool _isJson(String text) {
    try {
      jsonDecode(text);
      return true;
    } catch (_) {
      return false;
    }
  }
}
