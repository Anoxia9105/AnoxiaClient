import 'dart:io';

import 'package:anoxia/features/chat/presentation/widgets/desktop_drop_files.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('anoxia_drop_test_');
  });
  tearDown(() async => directory.delete(recursive: true));

  test('保留中文文件名、大小和路径，不预读整个文件', () async {
    final file = await File(
      '${directory.path}/测试报告.pdf',
    ).writeAsBytes([1, 2, 3]);
    final result = await prepareDesktopDropFiles([XFile(file.path)]);
    expect(result.files.single.name, '测试报告.pdf');
    expect(result.files.single.size, 3);
    expect(result.files.single.path, file.path);
    expect(result.files.single.bytes, isNull);
    expect(result.rejected, isEmpty);
  });

  test('文件夹和丢失文件不影响同批有效文件', () async {
    final file = await File('${directory.path}/有效.txt').writeAsString('ok');
    final result = await prepareDesktopDropFiles([
      XFile(directory.path),
      XFile('${directory.path}/missing.txt'),
      XFile(file.path),
    ]);
    expect(result.files.single.name, '有效.txt');
    expect(result.rejected, hasLength(2));
  });

  test('同批重复路径只添加一次', () async {
    final file = await File('${directory.path}/文件.txt').writeAsString('ok');
    final result = await prepareDesktopDropFiles([
      XFile(file.path),
      XFile(file.path),
    ]);
    expect(result.files, hasLength(1));
  });
}
