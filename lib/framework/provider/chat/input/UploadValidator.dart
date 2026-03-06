import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/framework/provider/chat/input/DeltaProcessor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_quill/flutter_quill.dart';

class UploadValidator {
  // 配置常量
  static const int maxTotalCount = 10; // 总附件数限制
  static const int maxTotalSize = 100 * 1024 * 1024; // 总大小限制 100MB
  static const int maxSingleFileSize = 50 * 1024 * 1024; // 单个文件限制 50MB

  /// 检查是否允许插入新选的文件
  /// [controller] 用于获取当前富文本框内容
  /// [newFiles] 本次新选择的文件列表
  static bool validate(
    QuillController controller,
    List<PlatformFile> newFiles,
  ) {
    // 1. 利用已有的 DeltaProcessor 统计框内现状
    final processor = DeltaProcessor(controller.document.toDelta(), {});
    int existingCount = processor.totalCount;
    int existingSize = processor.totalSize;

    // 2. 计算本次新选的统计数据
    int selectingCount = newFiles.length;
    int selectingSize = newFiles.fold(0, (sum, f) => sum + f.size);

    // 3. 校验总数量
    if (existingCount + selectingCount > maxTotalCount) {
      Toast.showToast("upload_total_count_exceeded".tr(args: [maxTotalCount.toString(), existingCount.toString()]));
      return false;
    }

    // 4. 校验总大小
    if (existingSize + selectingSize > maxTotalSize) {
      final String limitStr = (maxTotalSize / 1024 / 1024).toStringAsFixed(0);
      Toast.showToast("upload_total_size_exceeded".tr(args: [limitStr]));
      return false;
    }

    return true;
  }

  /// 校验单个文件是否过大（用于循环内部）
  static bool validateSingleFile(PlatformFile file) {
    if (file.size > maxSingleFileSize) {
      Toast.showToast("upload_single_file_too_large".tr(args: [file.name]));
      return false;
    }
    return true;
  }
}
