import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';

Future<({List<PlatformFile> files, List<String> rejected})>
prepareDesktopDropFiles(List<XFile> items) async =>
    (files: <PlatformFile>[], rejected: <String>[]);
