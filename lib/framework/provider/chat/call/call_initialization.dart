/// 语音优先，分别处理设备失败；生命周期关闭必须中断后续初始化。
Future<void> initializeCallMedia({
  required Future<void> Function() microphone,
  required Future<void> Function() camera,
  required void Function() ensureOpen,
  required void Function(Object, StackTrace) onError,
}) async {
  for (final initialize in [microphone, camera]) {
    ensureOpen();
    try {
      await initialize();
    } catch (error, stack) {
      onError(error, stack);
    }
    ensureOpen();
  }
}
