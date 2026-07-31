// Web 端 image_cropper 桩。cropImage 直接返回 null，调用方需对 null 做降级处理。
class ImageCompressFormat {
  const ImageCompressFormat._(this.name);
  final String name;
  static const jpg = ImageCompressFormat._('jpg');
  static const png = ImageCompressFormat._('png');
}

class CroppedFile {
  final String path;
  const CroppedFile(this.path);
}

class ImageCropper {
  Future<CroppedFile?> cropImage({
    String? sourcePath,
    dynamic aspectRatio,
    dynamic compressFormat,
    int? compressQuality,
    dynamic maxWidth,
    dynamic maxHeight,
    dynamic uiSettings,
    dynamic aspectRatioPresets,
  }) async =>
      null;
}

class CropAspectRatio {
  final double ratioX;
  final double ratioY;
  const CropAspectRatio({required this.ratioX, required this.ratioY});
}

class AndroidUiSettings {
  final String? toolbarTitle;
  final dynamic toolbarWidgetColor;
  final dynamic toolbarColor;
  final dynamic activeControlsWidgetColor;
  const AndroidUiSettings({
    this.toolbarTitle,
    this.toolbarWidgetColor,
    this.toolbarColor,
    this.activeControlsWidgetColor,
  });
}

class IOSUiSettings {
  final String? title;
  const IOSUiSettings({this.title});
}
