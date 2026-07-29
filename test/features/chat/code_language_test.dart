import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/code_language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detects common languages without parser auto detection', () {
    expect(
      CodeLanguageDetector.detect(
        'import "package:flutter/material.dart";\n'
        '@override\nWidget build(BuildContext context) => const SizedBox();',
      ).id,
      'dart',
    );
    expect(
      CodeLanguageDetector.detect('void main() {\n  print("hello");\n}').id,
      'dart',
    );
    expect(CodeLanguageDetector.detect('{"name":"anoxia"}').id, 'json');
    expect(
      CodeLanguageDetector.detect('def greet(name):\n  print(name)').id,
      'python',
    );
    expect(
      CodeLanguageDetector.detect('SELECT * FROM messages WHERE id = 1;').id,
      'sql',
    );
    expect(CodeLanguageDetector.detect('^=').id, 'plaintext');
  });
}
