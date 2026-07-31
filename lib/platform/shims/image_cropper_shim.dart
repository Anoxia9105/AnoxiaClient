// 条件导出：原生平台使用真实 image_cropper，Web 端使用本地桩。
export 'package:image_cropper/image_cropper.dart'
    if (dart.library.html) 'image_cropper_stub.dart';
