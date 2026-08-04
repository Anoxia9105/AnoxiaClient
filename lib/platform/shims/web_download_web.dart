// Web 端浏览器下载实现。
//
// 原生端下载可以写入本地文件系统并用原始文件名保存；浏览器没有文件系统，
// 直接打开 URL 时浏览器会按 URL 末尾的 UUID 文件名保存，与用户上传文件名
// 不一致。这里改用 fetch 拉取内容 + Blob URL + <a download="原始名"> 触发
// 带指定文件名的浏览器下载。
//
// 使用 package:web + dart:js_interop（JS/WASM 双兼容），不使用 dart:html
// （dart:html 在 --wasm(dart2wasm) 下无法编译）。
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

class WebDownload {
  /// 使用浏览器下载 URL 内容到本地，[fileName] 为保存文件名。
  ///
  /// 跨域(CORS)不允许 fetch 时返回 false，由调用方降级为直接打开 URL。
  static Future<bool> downloadUrl(String url, String fileName) async {
    try {
      final response = await web.window.fetch(url.toJS).toDart;
      if (!response.ok) return false;
      final buffer = await response.arrayBuffer().toDart;
      final bytes = Uint8List.view(buffer.toDart);
      final blob = web.Blob(
        [bytes.toJS].toJS,
        web.BlobPropertyBag(type: 'application/octet-stream'),
      );
      final objectUrl = web.URL.createObjectURL(blob);
      final anchor = web.HTMLAnchorElement()
        ..href = objectUrl
        ..download = fileName;
      web.document.body?.appendChild(anchor);
      anchor.click();
      anchor.remove();
      web.URL.revokeObjectURL(objectUrl);
      return true;
    } catch (_) {
      return false;
    }
  }
}
