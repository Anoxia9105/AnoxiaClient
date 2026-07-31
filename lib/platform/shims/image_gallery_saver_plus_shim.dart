// 条件导出：原生平台使用真实 image_gallery_saver_plus，Web 端使用本地桩。
export 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart'
    if (dart.library.html) 'image_gallery_saver_plus_stub.dart';
