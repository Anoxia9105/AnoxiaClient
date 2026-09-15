// 更新安装包文件操作助手（原生平台实现）
import 'dart:io';

import 'package:anoxia/common/utils/device_util.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 解析更新安装包的保存目录
///
/// - Android：应用专属外部目录（`Android/data/<pkg>/files`，免存储权限，
///   open_filex 自带 FileProvider 已覆盖 external-files-path，可直接拉起安装）；
/// - 其它桌面平台：getApplicationSupportDirectory()/updates/；
/// 目录不存在时自动创建。
Future<String> resolveUpdateSaveDir() async {
  final Directory base;
  if (DeviceUtil.isAndroid()) {
    final external = await getExternalStorageDirectory();
    base = external ?? await getApplicationSupportDirectory();
  } else {
    final support = await getApplicationSupportDirectory();
    base = Directory(p.join(support.path, 'updates'));
  }
  if (!await base.exists()) {
    await base.create(recursive: true);
  }
  return base.path;
}

/// 清理更新目录中的残留安装包
///
/// [keepName] 保留的文件名（当前已就绪/正在下载的目标文件，可为空），
/// [maxAge] 超过该时长且不在保留名单内的文件一律删除。
/// 任何失败都静默忽略：清理是纯体验优化，绝不能影响更新主流程。
Future<void> cleanupUpdateFiles(
  String dirPath, {
  String? keepName,
  Duration maxAge = const Duration(days: 7),
}) async {
  try {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return;
    final now = DateTime.now();
    await for (final entry in dir.list()) {
      if (entry is! File) continue;
      final name = p.basename(entry.path);
      if (keepName != null && name == keepName) continue;
      try {
        final modified = await entry.lastModified();
        if (now.difference(modified) > maxAge) {
          await entry.delete();
        }
      } catch (_) {
        // 单个文件删除失败不影响其余清理
      }
    }
  } catch (_) {
    // 目录不存在/无法访问时直接跳过
  }
}

/// 删除单个安装包文件（静默失败）
Future<void> deleteUpdateFile(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  } catch (_) {
    // 删除失败不影响主流程
  }
}

/// 读取文件字节数（文件不存在返回 0）
Future<int> updateFileLength(String path) async {
  final file = File(path);
  if (!await file.exists()) return 0;
  final length = await file.length();
  return length;
}

/// 计算文件 SHA-256（流式分块读取，避免大安装包撑爆内存）
///
/// 返回十六进制小写字符串；读取失败返回空字符串。
Future<String> updateFileSha256Hex(String path) async {
  try {
    final file = File(path);
    if (!await file.exists()) return '';
    final collector = _DigestCollector();
    final input = crypto.sha256.startChunkedConversion(collector);
    await for (final chunk in file.openRead()) {
      input.add(chunk);
    }
    input.close();
    final digest = collector.value;
    return digest?.toString() ?? '';
  } catch (_) {
    return '';
  }
}

/// 分块哈希结果收集器
class _DigestCollector implements Sink<crypto.Digest> {
  crypto.Digest? value;

  @override
  void add(crypto.Digest data) => value = data;

  @override
  void close() {}
}
