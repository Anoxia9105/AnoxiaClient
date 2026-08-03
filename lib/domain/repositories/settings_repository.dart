import 'package:anoxia/framework/domain/app_update_info.dart';

/// 反馈提交结果
class FeedbackSubmitResult {
  /// 是否提交成功
  final bool success;

  /// 结果消息
  final String? message;

  const FeedbackSubmitResult({required this.success, this.message});
}

/// 设置仓库抽象接口
///
/// 定义设置相关的数据操作契约：反馈提交和应用更新检查。
/// 数据层通过实现此接口提供具体实现，UI 层 Provider 仅依赖此接口。
abstract interface class SettingsRepository {
  /// 提交用户反馈
  Future<FeedbackSubmitResult> submitFeedback({
    required String title,
    required String content,
    required String contact,
    required String clientType,
    required String appVersion,
  });

  /// 检查应用更新
  Future<AppUpdateInfo> checkForUpdate({
    required String currentVersion,
    required String clientType,
  });
}
