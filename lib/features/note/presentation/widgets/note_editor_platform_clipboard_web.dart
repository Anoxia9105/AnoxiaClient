import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

abstract interface class NotePlatformClipboardBinding {
  Future<bool> paste();

  void dispose();
}

NotePlatformClipboardBinding bindNotePlatformClipboard({
  required bool Function() isActive,
  required Future<void> Function(String html, String plainText) pasteHtml,
  required Future<void> Function(String plainText) pasteText,
  required Future<void> Function(Uint8List bytes) pasteImage,
}) => _WebNotePlatformClipboardBinding(
  isActive: isActive,
  pasteHtml: pasteHtml,
  pasteText: pasteText,
  pasteImage: pasteImage,
);

class _WebNotePlatformClipboardBinding implements NotePlatformClipboardBinding {
  _WebNotePlatformClipboardBinding({
    required this.isActive,
    required this.pasteHtml,
    required this.pasteText,
    required this.pasteImage,
  }) {
    _listener = _onPaste.toJS;
    document.addEventListener('paste', _listener);
  }

  final bool Function() isActive;
  final Future<void> Function(String html, String plainText) pasteHtml;
  final Future<void> Function(String plainText) pasteText;
  final Future<void> Function(Uint8List bytes) pasteImage;
  late final EventListener _listener;

  void _onPaste(Event event) {
    if (!isActive() || !event.isA<ClipboardEvent>()) return;
    final clipboardEvent = event as ClipboardEvent;
    final clipboardData = clipboardEvent.clipboardData;
    if (clipboardData == null) return;

    File? image;
    for (var index = 0; index < clipboardData.files.length; index++) {
      final file = clipboardData.files.item(index);
      if (file != null && file.type.startsWith('image/')) {
        image = file;
        break;
      }
    }

    final html = clipboardData.getData('text/html');
    final plainText = clipboardData.getData('text/plain');
    if (image == null && html.isEmpty && plainText.isEmpty) return;

    // 必须在同步 paste 事件中阻止浏览器回退为 text/plain。
    clipboardEvent.preventDefault();
    if (image != null) {
      unawaited(_pasteImageFile(image));
    } else if (html.isNotEmpty) {
      unawaited(pasteHtml(html, plainText));
    } else {
      unawaited(pasteText(plainText));
    }
  }

  Future<void> _pasteImageFile(File image) async {
    final buffer = await image.arrayBuffer().toDart;
    await pasteImage(buffer.toDart.asUint8List());
  }

  @override
  Future<bool> paste() async {
    try {
      final items = (await window.navigator.clipboard.read().toDart).toDart;
      Uint8List? imageBytes;
      var html = '';
      var plainText = '';

      for (final item in items) {
        for (final typeValue in item.types.toDart) {
          final type = typeValue.toDart;
          if (imageBytes == null && type.startsWith('image/')) {
            final blob = await item.getType(type).toDart;
            final buffer = await blob.arrayBuffer().toDart;
            imageBytes = buffer.toDart.asUint8List();
          } else if (html.isEmpty && type == 'text/html') {
            final blob = await item.getType(type).toDart;
            html = (await blob.text().toDart).toDart;
          } else if (plainText.isEmpty && type == 'text/plain') {
            final blob = await item.getType(type).toDart;
            plainText = (await blob.text().toDart).toDart;
          }
        }
      }

      if (imageBytes != null) {
        await pasteImage(imageBytes);
        return true;
      }
      if (html.isNotEmpty) {
        await pasteHtml(html, plainText);
        return true;
      }
      if (plainText.isNotEmpty) {
        await pasteText(plainText);
        return true;
      }
    } catch (_) {
      // 浏览器不开放 Clipboard API 时回退 Quill 默认粘贴路径。
    }
    return false;
  }

  @override
  void dispose() => document.removeEventListener('paste', _listener);
}
