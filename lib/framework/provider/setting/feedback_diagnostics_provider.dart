import 'package:flutter_riverpod/legacy.dart' as legacy;

import '../../../common/utils/sp_util.dart';
import '../../../common/constants/storage_keys.dart';

/// 反馈是否附带脱敏诊断日志（持久化，默认关闭）。
///
/// 开启后提交反馈时由 [DiagnosticsReportService] 汇总
/// sync_logs 同步失败记录 + debug 运行日志（如有）形成文本，
/// 随 multipart 字段 `diagnostics` 上送。
class FeedbackDiagnosticsController extends legacy.StateNotifier<bool> {
  FeedbackDiagnosticsController() : super(_load());

  static bool _load() {
    return SPUtil.instance.getBool(StorageKeys.feedbackAttachDiagnostics) ??
        false;
  }

  void setEnabled(bool enabled) {
    if (state == enabled) return;
    state = enabled;
    SPUtil.instance.setBool(StorageKeys.feedbackAttachDiagnostics, enabled);
  }
}

final feedbackAttachDiagnosticsProvider =
    legacy.StateNotifierProvider<FeedbackDiagnosticsController, bool>(
      (ref) => FeedbackDiagnosticsController(),
    );
