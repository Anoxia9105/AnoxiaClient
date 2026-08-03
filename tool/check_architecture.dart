import 'dart:io';

/// 架构检查脚本：禁止 provider 层直接依赖 UI 层代码
///
/// 运行方式：
/// ```bash
/// dart run tool/check_architecture.dart
/// ```
///
/// 检查规则（lib/framework/provider/ 下的文件）：
/// 1. 不得 import 'package:anoxia/common/widgets/'
/// 2. 不得 import 'package:anoxia/features/*/presentation/'
/// 3. 不得直接 import 'package:anoxia/framework/network/dio_client.dart'
///    （HTTP 请求必须走 domain 仓库，由 *_repository_provider 提供）
///
/// 白名单（有意的桥接/组合点，改动前需三思）：
/// - toast_service_provider.dart：Toast 的唯一样板桥接（Phase 1 设计，
///   所有 provider 通过 ToastService 抽象间接使用 UI Toast）
/// - router.dart：路由配置本质上是页面组合，属于导航组合点，
///   其 import 的页面是路由表的必要组成
void main() {
  final root = Directory('lib/framework/provider');
  final violations = <String>[];

  final files = root
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final fileName = file.uri.pathSegments.last;
    if (_isWhitelisted(fileName)) continue;

    final content = file.readAsStringSync();
    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('import ')) continue;

      final path = trimmed.replaceAll(RegExp(r"import '([^']+)';"), r'$1');
      if (path.startsWith('package:anoxia/common/widgets/') ||
          path.startsWith('package:anoxia/features/') &&
              path.contains('/presentation/') ||
          path == 'package:anoxia/framework/network/dio_client.dart') {
        violations.add('${file.path} -> $path');
      }
    }
  }

  if (violations.isEmpty) {
    stdout.writeln('架构检查通过：provider 层无 UI / DioClient 直接依赖。');
    return;
  }

  for (final v in violations) {
    stderr.writeln('架构违规: $v');
  }
  stderr.writeln(
    '\n发现 ${violations.length} 处架构违规。\n'
    '修复方向：\n'
    '  - UI 组件（对话框/弹窗/Toast）：由 UI 层调用点负责，控制器只接收数据参数；\n'
    '  - HTTP 调用：通过 domain 仓库 + *_repository_provider 注入；\n'
    '  - 确属有意桥接的，加入 check_architecture.dart 白名单并注明原因。',
  );
  exitCode = 1;
}

/// 白名单文件（按文件名匹配，必须位于 provider 层内）
bool _isWhitelisted(String fileName) {
  switch (fileName) {
    case 'toast_service_provider.dart':
    case 'router.dart':
      return true;
    default:
      return false;
  }
}
