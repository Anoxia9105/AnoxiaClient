// 客户端诊断报告装配服务。
//
// 「反馈附带诊断日志」开关打开后，提交前从这里汇总文本：
// - 本地库 sync_logs 里的同步失败记录：发布版可见（每端最多保留 200 条）；
// - AppRuntimeLog 内存环形缓冲：仅 debug 构建有内容；
// 两者都经过 LogSanitizer 脱敏后再进入报告。
//
// 装配失败只降级（返回 null），绝不阻塞反馈提交主链路。
import 'package:anoxia/common/utils/diagnostics_report.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../local_cache/cache_providers.dart';

/// 诊断报告装配服务 Provider。
final diagnosticsReportServiceProvider = Provider<DiagnosticsReportService>((
  ref,
) {
  return DiagnosticsReportService(ref);
});

/// 把本地诊断数据汇成一份脱敏文本报告。
class DiagnosticsReportService {
  DiagnosticsReportService(this._ref);

  final Ref _ref;

  /// 汇总诊断文本。任何一步失败都返回 null（不阻塞反馈提交）。
  Future<String?> collectReport({String? appVersion}) async {
    try {
      final db = _ref.watch(appDatabaseProvider);
      final rows = await db.syncLogDao.getRecentDiagnosticLogs(
        limit: DiagnosticsReportBuilder.maxFailures,
      );
      return buildDiagnosticsReport(
        appVersion: appVersion ?? '--',
        platform: platformLabel(),
        failures: [
          for (final row in rows)
            DiagnosticEntry(
              createdAt: row.createdAt,
              scope: row.scope,
              scopeId: row.scopeId,
              retryCount: row.retryCount,
              message: row.message ?? row.action,
            ),
        ],
        runtimeLogs: AppRuntimeLog.snapshot(),
      );
    } catch (_) {
      return null;
    }
  }

  /// 平台标签（Web 安全，不用 dart:io）。
  String platformLabel() {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }
}
