import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FileUtil {
  static Future<File> writeToTempFile(Uint8List bytes, String ext) async {
    final dir = await getTemporaryDirectory();
    print("写入临时文件：${dir.path}");
    final file = File(
      p.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}.$ext'),
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
