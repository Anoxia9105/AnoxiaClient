import 'dart:io';

Never _exit(int code) => exit(code);

Future<void> terminateAppProcess() async => _exit(0);
