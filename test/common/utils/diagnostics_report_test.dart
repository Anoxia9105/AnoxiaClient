// 诊断日志导出（INF-2）单元测试。
//
// 覆盖：
// - LogSanitizer 脱敏口径（JWT / 密钥键值 / 邮箱 / 手机号）；
// - AppRuntimeLog 环形缓冲（容量驱逐、压平换行、长度截断、清空）；
// - buildDiagnosticsReport 版式与超长截断；
// - sync_logs 最近失败读取（LocalDataSource → SyncLogDao）；
// - 反馈附带诊断开关默认关闭与持久化、诊断装配降级。
import 'package:anoxia/common/constants/storage_keys.dart';
import 'package:anoxia/common/utils/diagnostics_report.dart';
import 'package:anoxia/common/utils/sp_util.dart';
import 'package:anoxia/framework/local_cache/cache_providers.dart';
import 'package:anoxia/framework/local_cache/database.dart';
import 'package:anoxia/framework/local_cache/local_data_source.dart';
import 'package:anoxia/framework/local_cache/session_epoch.dart';
import 'package:anoxia/framework/provider/core/diagnostics_report_provider.dart';
import 'package:anoxia/framework/provider/setting/feedback_diagnostics_provider.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LogSanitizer.maskLine', () {
    test('JWT 三段式被替换', () {
      final line = LogSanitizer.maskLine(
        'auth header eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1MjM0NTY3ODkwIn0.3K9GgZQ tail',
      );
      expect(line, isNot(contains('eyJ')));
      expect(line, contains('[JWT]'));
      expect(line, contains('auth header'));
      expect(line, contains('tail'));
    });

    test('键值密钥被替换为 REDACTED', () {
      expect(LogSanitizer.maskLine('token=abc123'), 'token=[REDACTED]');
      expect(
        LogSanitizer.maskLine('password: hunter2'),
        contains('[REDACTED]'),
      );
      final auth = LogSanitizer.maskLine('Authorization: Bearer abc.def');
      expect(auth, contains('[REDACTED]'));
      expect(auth, isNot(contains('abc.def')));
      expect(LogSanitizer.maskLine('apiKey=sk-secret-1'), 'apiKey=[REDACTED]');
    });

    test('邮箱与手机号被替换', () {
      expect(LogSanitizer.maskLine('mail me a@b.com.cn'), contains('[EMAIL]'));
      final phone = LogSanitizer.maskLine('call 13812345678 ok');
      expect(phone, contains('[PHONE]'));
      expect(phone, isNot(contains('13812345678')));
    });

    test('普通日志行保持不变（不误伤）', () {
      const line = 'sync messages seq=12345 room=r1 ok';
      expect(LogSanitizer.maskLine(line), line);
      // 长数字串中即便含号码片段也不替换（前后都是数字）。
      const digits = 'seq=011381234567812345';
      expect(LogSanitizer.maskLine(digits), digits);
    });
  });

  group('AppRuntimeLog', () {
    String lineOf(int index) => 'l${index.toString().padLeft(3, '0')}';

    setUp(AppRuntimeLog.clear);

    test('追加时压平换行并脱敏', () {
      AppRuntimeLog.add('multi\nline\ntoken=secret');
      final snapshot = AppRuntimeLog.snapshot();
      expect(snapshot, hasLength(1));
      expect(snapshot.single, contains('multi | line | token=[REDACTED]'));
      expect(snapshot.single, isNot(contains('\n')));
    });

    test('超过容量后驱逐最旧条目（保持 500 条）', () {
      for (var i = 1; i <= 505; i++) {
        AppRuntimeLog.add(lineOf(i));
      }
      final snapshot = AppRuntimeLog.snapshot();
      expect(snapshot, hasLength(AppRuntimeLog.maxEntries));
      expect(snapshot.first, lineOf(6)); // 501~505 挤掉 l001~l005
      expect(snapshot.last, lineOf(505));
    });

    test('超长行截断到 800 字符', () {
      AppRuntimeLog.add('x' * 900);
      expect(AppRuntimeLog.snapshot().single.length, 800);
    });

    test('clear 清空缓冲', () {
      AppRuntimeLog.add('a');
      AppRuntimeLog.clear();
      expect(AppRuntimeLog.snapshot(), isEmpty);
    });
  });

  group('buildDiagnosticsReport', () {
    test('基础版式：头部信息 + 结束标记', () {
      final report = buildDiagnosticsReport(
        appVersion: '1.2.3',
        platform: 'windows',
        failures: const [],
        runtimeLogs: const [],
        now: DateTime.parse('2026-10-19 10:00:00'),
      );
      expect(report, startsWith('===== Anoxia Client Diagnostics =====\n'));
      expect(report, contains('generated_at: 2026-10-19T10:00:00.000\n'));
      expect(report, contains('app_version: 1.2.3\n'));
      expect(report, contains('platform: windows\n'));
      expect(report, contains('===== End ====='));
      expect(report, contains('- none'));
    });

    test('失败条目按固定版式输出且脱敏', () {
      final report = buildDiagnosticsReport(
        appVersion: '1.2.3',
        platform: 'web',
        failures: [
          DiagnosticEntry(
            createdAt: DateTime.parse('2026-10-19 09:00:00'),
            scope: 'messages',
            scopeId: 'r1',
            retryCount: 3,
            message: 'bad gateway token=secret123',
          ),
        ],
        runtimeLogs: const [],
        now: DateTime.parse('2026-10-19 10:00:00'),
      );
      expect(
        report,
        contains(
          '[2026-10-19T09:00:00.000] scope=messages id=r1 retry=3 '
          'bad gateway token=[REDACTED]',
        ),
      );
      expect(report, isNot(contains('secret123')));
    });

    test('超长报告被截断并标注', () {
      final report = buildDiagnosticsReport(
        appVersion: '1.2.3',
        platform: 'windows',
        failures: [
          for (var i = 0; i < 40; i++)
            DiagnosticEntry(
              createdAt: DateTime.now(),
              scope: 'messages',
              retryCount: i,
              message: 'y${'x' * 60}',
            ),
        ],
        runtimeLogs: const [],
        maxChars: 500,
      );
      // 截断后总长不超过上限（标注行允许越过一些），且以标注收尾。
      expect(report.length, lessThan(542));
      expect(report, contains('报告已截断至 500 字符'));
      expect(report, isNot(contains('===== End =====')));
    });
  });

  group('sync_logs 最近失败读取（LocalDataSource → SyncLogDao）', () {
    late AppDatabase db;
    late LocalDataSource local;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      local = LocalDataSource(db, sessionEpoch: SessionEpoch.instance);
    });

    tearDown(() => db.close());

    test('按时间倒序返回最近失败记录并受 limit 约束', () async {
      await local.logSyncFailure(
        scope: 'conversations',
        scopeId: 'r1',
        action: 'sync',
        error: 'offline',
        retryCount: 1,
      );
      await local.logSyncFailure(
        scope: 'messages',
        scopeId: 'r2',
        action: 'sync',
        error: 'timeout',
        retryCount: 2,
      );

      final recent = await local.recentSyncFailureLogs(limit: 50);
      expect(recent, hasLength(2));
      expect(recent.first.scope, 'messages'); // 最新在前
      expect(recent.first.message, contains('timeout'));
      expect(recent.last.scope, 'conversations');
      expect(recent.last.retryCount, 1);
    });
  });

  group('反馈附带诊断开关', () {
    test('未持久化时默认关闭', () {
      SharedPreferences.setMockInitialValues(const {});
      // 不调用 SPUtil.init：未初始化时读取须安全回退默认值。
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(feedbackAttachDiagnosticsProvider), isFalse);
      expect(
        StorageKeys.feedbackAttachDiagnostics,
        'FEEDBACK_ATTACH_DIAGNOSTICS',
      );
    });

    test('持久化值可读回开启状态', () async {
      SharedPreferences.setMockInitialValues(const {
        StorageKeys.feedbackAttachDiagnostics: true,
      });
      await SPUtil.instance.init();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(feedbackAttachDiagnosticsProvider), isTrue);
    });

    test('诊断装配：读 sync_logs 生成报告并脱敏', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final local = LocalDataSource(db, sessionEpoch: SessionEpoch.instance);
      await local.logSyncFailure(
        scope: 'conversations',
        scopeId: 'room-1',
        action: 'sync',
        error: 'offline boom token=abc',
      );
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      final report = await container
          .read(diagnosticsReportServiceProvider)
          .collectReport(appVersion: '9.9.9');
      expect(report, isNotNull);
      expect(report, contains('app_version: 9.9.9'));
      expect(report, contains('scope=conversations id=room-1'));
      expect(report, contains('offline boom token=[REDACTED]'));
    });

    test('诊断装配：数据库异常时降级为 null 而不是抛出', () async {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWith(
            (ref) => throw StateError('db unavailable'),
          ),
        ],
      );
      addTearDown(container.dispose);
      final report = await container
          .read(diagnosticsReportServiceProvider)
          .collectReport(appVersion: '9.9.9');
      expect(report, isNull);
    });
  });
}
