import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';

class CodeLanguage {
  final String id;
  final String label;

  const CodeLanguage(this.id, this.label);
}

/// Safe code-language detection that never invokes highlight.js auto-detect.
abstract final class CodeLanguageDetector {
  static const plainText = CodeLanguage('plaintext', 'Plain Text');

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

  static CodeLanguage? fromId(String id) {
    final normalized = id.toLowerCase();
    for (final language in supported) {
      if (language.id == normalized) return language;
    }
    return null;
  }

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
      r'\bpackage:|@override\b|\bWidget\s+build\b|\blate\s+final\b',
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
