// Web 端 image_gallery_saver_plus 实现。
//
// 浏览器无法写入系统相册，因此“保存到相册”在 Web 上等价于“下载文件”。
// 调用方仍通过 isSuccess 判断结果，并在 UI 上提示“已保存/已下载”。
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

class ImageGallerySaverPlus {
  static Future<dynamic> saveImage(
    List<int> imageBytes, {
    int? quality,
    String? name,
    String? albumName,
    bool? isReturnImagePathOfIOS,
  }) async {
    if (!_canDownload) {
      return <String, dynamic>{'isSuccess': false, 'filePath': ''};
    }
    try {
      final bytes = Uint8List.fromList(imageBytes);
      final blob = html.Blob(<Object>[bytes], 'image/png');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final fileName = '${name ?? 'anoxia'}.png';
      _triggerDownload(url, fileName);
      // 立即回收 URL 可能导致部分浏览器取消正在进行的下载，延迟回收更稳妥。
      _revokeLater(url);
      return <String, dynamic>{'isSuccess': true, 'filePath': fileName};
    } catch (_) {
      return <String, dynamic>{'isSuccess': false, 'filePath': ''};
    }
  }

  static Future<dynamic> saveFile(
    String filePath, {
    String? name,
    String? albumName,
    bool? isReturnPathOfIOS,
  }) async {
    if (!_canDownload) {
      return <String, dynamic>{'isSuccess': false, 'filePath': ''};
    }
    try {
      final resp = await html.HttpRequest.request(
        filePath,
        responseType: 'blob',
      );
      final blob = resp.response as html.Blob?;
      if (blob == null) {
        return <String, dynamic>{'isSuccess': false, 'filePath': ''};
      }
      final url = html.Url.createObjectUrlFromBlob(blob);
      final fileName = name ?? filePath.split('/').last;
      _triggerDownload(url, fileName);
      _revokeLater(url);
      return <String, dynamic>{'isSuccess': true, 'filePath': fileName};
    } catch (_) {
      return <String, dynamic>{'isSuccess': false, 'filePath': ''};
    }
  }

  static bool get _canDownload =>
      html.document.body != null;

  static void _triggerDownload(String url, String fileName) {
    final anchor = html.AnchorElement(href: url)
      ..download = fileName
      ..style.display = 'none';
    html.document.body!.children.add(anchor);
    anchor.click();
    anchor.remove();
  }

  /// 延迟回收 Blob URL，确保浏览器已发起下载，避免立即回收导致下载被取消。
  static void _revokeLater(String url) {
    Future.delayed(const Duration(seconds: 1), () {
      try {
        html.Url.revokeObjectUrl(url);
      } catch (_) {
        // 已失效则忽略。
      }
    });
  }
}
