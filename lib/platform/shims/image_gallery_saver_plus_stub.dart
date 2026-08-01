// Web 端 image_gallery_saver_plus 实现。
//
// 浏览器无法写入系统相册。原 dart:html 实现等价于“下载文件”，但该路径在 Web 上
// 不可达（唯一调用方 image_viewer._downloadImage 已被 isRealMobile 守卫提前返回），
// 故这里改为 no-op 以彻底移除 dart:html（dart:html 在 --wasm/dart2wasm 下无法编译）。
// 如后续需要在 Web 端支持下载，应改用 package:web + dart:js_interop 重新实现。
import 'dart:async';

class ImageGallerySaverPlus {
  static Future<dynamic> saveImage(
    List<int> imageBytes, {
    int? quality,
    String? name,
    String? albumName,
    bool? isReturnImagePathOfIOS,
  }) async {
    return <String, dynamic>{'isSuccess': false, 'filePath': ''};
  }

  static Future<dynamic> saveFile(
    String filePath, {
    String? name,
    String? albumName,
    bool? isReturnPathOfIOS,
  }) async {
    return <String, dynamic>{'isSuccess': false, 'filePath': ''};
  }
}
