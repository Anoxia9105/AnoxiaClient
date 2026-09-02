import 'dart:typed_data';

abstract interface class NotePlatformClipboardBinding {
  Future<bool> paste();

  void dispose();
}

NotePlatformClipboardBinding bindNotePlatformClipboard({
  required bool Function() isActive,
  required Future<void> Function(String html, String plainText) pasteHtml,
  required Future<void> Function(String plainText) pasteText,
  required Future<void> Function(Uint8List bytes) pasteImage,
}) => const _NoopNotePlatformClipboardBinding();

class _NoopNotePlatformClipboardBinding
    implements NotePlatformClipboardBinding {
  const _NoopNotePlatformClipboardBinding();

  @override
  Future<bool> paste() async => false;

  @override
  void dispose() {}
}
