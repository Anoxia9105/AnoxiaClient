// 客户端诊断报告工具。
//
// 三个职责，全部保持纯 Dart（不依赖 flutter/dart:io，Web/Wasm 可直接用）：
// 1. [LogSanitizer] 对文本行做脱敏（JWT/token/邮箱/手机号）；
// 2. [AppRuntimeLog] 内存环形日志缓冲（调用方需自行决定是否写入，
//    `debug_log.dart` 在 debug 构建下会写入；发布版可见的诊断数据走
//    本地库 sync_logs 表，两者在 [buildDiagnosticsReport] 汇合）；
// 3. [buildDiagnosticsReport] 把各来源拼成固定结构的文本报告，
//    总长钳制在 [DiagnosticsReportBuilder.maxReportChars]。
//
// 报告文本是给开发者看的机器证据，不做本地化（不属于用户界面文案）。
import 'dart:collection';

/// 文本行脱敏工具。
abstract final class LogSanitizer {
  // 不用 (?i) 内联开关与 lookbehind：Dart VM / dart2js / WASM 三种运行时的
  // RegExp 支持面不一致，这里用显式大小写组与前后非数字消费放到上限兼容面。

  static final RegExp _jwt = RegExp(
    r'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{6,}\.?[A-Za-z0-9_.-]*',
  );

  /// 独立的 Bearer 凭据值（先处理，避免键值对规则只吃掉 'Bearer'）。
  static final RegExp _bearerValue = RegExp(
    r'\b[Bb][Ee][Aa][Rr][Ee][Rr]\s+[A-Za-z0-9._-]+',
  );

  /// 形如 `token=xxx` / `password: xxx` 的键值密钥。
  static final RegExp _secretAssignment = RegExp(
    r'\b([Tt][Oo][Kk][Ee][Nn]|[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd]|'
    r'[Pp][Aa][Ss][Ss][Ww][Dd]|[Ss][Ee][Cc][Rr][Ee][Tt]|'
    r'[Aa][Pp][Ii][-_]?[Kk][Ee][Yy]|'
    r'[Aa][Uu][Tt][Hh][Oo][Rr][Ii][Zz][Aa][Tt][Ii][Oo][Nn])'
    r'[=:]\s*\S+',
  );

  static final RegExp _email = RegExp(
    r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}',
  );

  /// 中国大陆手机号；前后需为非数字，用消费式分组保证兼容。
  static final RegExp _phoneCn = RegExp(r'(^|[^\d])(1[3-9]\d{9})([^\d]|$)');

  /// 对单行文本做脱敏；未知模式原样返回，不在报告里保留密钥明文。
  static String maskLine(String line) {
    var masked = line;
    masked = masked.replaceAllMapped(_jwt, (match) => '[JWT]');
    masked = masked.replaceAllMapped(
      _bearerValue,
      (match) => 'Bearer [REDACTED]',
    );
    masked = masked.replaceAllMapped(
      _secretAssignment,
      (match) => '${match.group(1)}=[REDACTED]',
    );
    masked = masked.replaceAll(_email, '[EMAIL]');
    masked = masked.replaceAllMapped(
      _phoneCn,
      (match) => '${match.group(1)}[PHONE]${match.group(3)}',
    );
    return masked;
  }
}

/// 内存环形运行日志（容量 [_maxEntries]，逐行脱敏、压平换行）。
///
/// 仅是诊断辅助：发布版构建默认无人写入该缓冲（入口在 debug_log.dart，
/// kDebugMode 才生效），发布版可见的诊断数据来自本地库 sync_logs 表。
class AppRuntimeLog {
  AppRuntimeLog._();

  /// 缓冲上限（条）。
  static const int maxEntries = 500;

  /// 单行长度上限（字符），超出截断。
  static const int maxLineLength = 800;

  static final ListQueue<String> _lines = ListQueue<String>();

  /// 追加一条日志（自动脱敏、压平多行、截断超长行）。
  static void add(String line) {
    if (line.isEmpty) return;
    var text = LogSanitizer.maskLine(line);
    text = text
        .replaceAll('\r\n', ' | ')
        .replaceAll('\n', ' | ')
        .replaceAll('\r', ' | ');
    if (text.length > maxLineLength) {
      text = text.substring(0, maxLineLength);
    }
    if (_lines.length >= maxEntries) {
      _lines.removeFirst();
    }
    _lines.addLast(text);
  }

  /// 当前缓冲的只读快照（时间正序）。
  static List<String> snapshot() => List.unmodifiable(_lines);

  /// 清空缓冲。
  static void clear() => _lines.clear();
}

/// 单条诊断记录（来自本地库 sync_logs 等来源）。
class DiagnosticEntry {
  final DateTime createdAt;
  final String scope;
  final String? scopeId;
  final int retryCount;
  final String message;

  const DiagnosticEntry({
    required this.createdAt,
    required this.scope,
    required this.retryCount,
    required this.message,
    this.scopeId,
  });
}

/// 诊断报告装配常量。
abstract final class DiagnosticsReportBuilder {
  /// 报告总长上限（字符）。服务端同样按此量级限制。
  static const int maxReportChars = 60000;

  /// 盛放同步失败记录的单条数量上限。
  static const int maxFailures = 50;
}

/// 生成诊断报告文本。
///
/// 结构固定、行序确定（失败记录按传入顺序）、超长自动截断并标注，
/// 方便服务端/开发者在同一版式下快速定位。
String buildDiagnosticsReport({
  required String appVersion,
  required String platform,
  required List<DiagnosticEntry> failures,
  required List<String> runtimeLogs,
  DateTime? now,
  int maxChars = DiagnosticsReportBuilder.maxReportChars,
}) {
  final timestamp = (now ?? DateTime.now()).toIso8601String();
  final buffer = StringBuffer();

  void writeLine(String line) {
    if (buffer.length + line.length + 1 > maxChars) {
      if (buffer.length + 12 <= maxChars) {
        buffer
          ..write('\n... [报告已截断至 ')
          ..write(maxChars)
          ..write(' 字符]');
      }
      throw _ReportTooLong();
    }
    buffer
      ..write(line)
      ..write('\n');
  }

  try {
    writeLine('===== Anoxia Client Diagnostics =====');
    writeLine('generated_at: $timestamp');
    writeLine('app_version: ${appVersion.isEmpty ? '--' : appVersion}');
    writeLine('platform: $platform');
    writeLine('--- recent sync failures ---');
    if (failures.isEmpty) {
      writeLine('- none');
    }
    for (final failure in failures.take(DiagnosticsReportBuilder.maxFailures)) {
      final id = (failure.scopeId == null || failure.scopeId!.isEmpty)
          ? ''
          : 'id=${failure.scopeId} ';
      writeLine(
        '[${failure.createdAt.toIso8601String()}] '
        'scope=${failure.scope} $id'
        'retry=${failure.retryCount} '
        '${LogSanitizer.maskLine(failure.message)}',
      );
    }
    writeLine('--- recent runtime logs ---');
    if (runtimeLogs.isEmpty) {
      writeLine('- none');
    }
    for (final line in runtimeLogs) {
      writeLine(LogSanitizer.maskLine(line));
    }
    writeLine('===== End =====');
  } on _ReportTooLong {
    // 截断标记已写入。
  }

  return buffer.toString();
}

class _ReportTooLong implements Exception {}
