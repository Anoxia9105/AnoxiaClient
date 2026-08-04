// 原生平台浏览器下载桩。
//
// 原生端下载走本地文件系统（DioClient.download + savePath），不需要浏览器
// 下载逻辑，此桩供调用点统一引用而不必区分平台。
class WebDownload {
  /// 使用浏览器下载 URL 内容到本地，[fileName] 为保存文件名。
  ///
  /// 原生平台不可用，始终返回 false。
  static Future<bool> downloadUrl(String url, String fileName) async => false;
}
