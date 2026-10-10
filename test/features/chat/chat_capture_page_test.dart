import 'dart:async';
import 'package:anoxia/features/chat/presentation/pages/chat_capture_page.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Camera extends CameraPlatform {
  Completer<void>? startGate;
  bool denied = false;
  int starts = 0;
  int stops = 0;
  int disposed = 0;
  final opened = <CameraDescription>[];
  final flashes = <FlashMode>[];

  @override
  Future<List<CameraDescription>> availableCameras() async {
    if (denied) throw CameraException('CameraAccessDenied', '');
    return const [
      CameraDescription(
        name: 'back',
        lensDirection: CameraLensDirection.back,
        sensorOrientation: 90,
      ),
      CameraDescription(
        name: 'front',
        lensDirection: CameraLensDirection.front,
        sensorOrientation: 90,
      ),
    ];
  }

  @override
  Future<int> createCameraWithSettings(
    CameraDescription description,
    MediaSettings settings,
  ) async {
    opened.add(description);
    return opened.length;
  }

  @override
  Future<void> initializeCamera(
    int cameraId, {
    ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown,
  }) async {}
  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int cameraId) =>
      Stream.value(
        CameraInitializedEvent(
          cameraId,
          640,
          480,
          ExposureMode.auto,
          false,
          FocusMode.auto,
          false,
        ),
      );
  @override
  Stream<CameraErrorEvent> onCameraError(int cameraId) =>
      Stream.fromFuture(Completer<CameraErrorEvent>().future);
  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() =>
      const Stream.empty();
  @override
  Widget buildPreview(int cameraId) => const ColoredBox(color: Colors.black);
  @override
  Future<void> dispose(int cameraId) async {
    disposed++;
  }

  @override
  Future<void> setFlashMode(int cameraId, FlashMode mode) async {
    flashes.add(mode);
  }

  @override
  Future<void> startVideoCapturing(VideoCaptureOptions options) async {
    starts++;
    await startGate?.future;
  }

  @override
  Future<XFile> stopVideoRecording(int cameraId) async {
    stops++;
    // 避免测试依赖系统视频解码器；验证结束动作后走可恢复失败状态。
    throw CameraException('TestStopFailure', '');
  }
}

void main() {
  late _Camera camera;
  late CameraPlatform original;
  setUp(() {
    original = CameraPlatform.instance;
    camera = _Camera();
    CameraPlatform.instance = camera;
  });
  tearDown(() {
    CameraPlatform.instance = original;
  });

  Future<void> show(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ChatCapturePage()));
    await tester.pumpAndSettle();
  }

  testWidgets('后摄优先，支持补光和前后摄切换，退出释放相机', (tester) async {
    await show(tester);
    expect(camera.opened.single.name, 'back');
    await tester.tap(find.byIcon(Icons.flash_off_rounded));
    await tester.pumpAndSettle();
    expect(camera.flashes, [FlashMode.off, FlashMode.torch]);
    await tester.tap(find.byIcon(Icons.flip_camera_ios_outlined));
    await tester.pumpAndSettle();
    expect(camera.opened.last.name, 'front');
    expect(camera.disposed, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(camera.disposed, 2);
  });

  testWidgets('长按启动尚未完成时松手，启动完成后仍结束录像', (tester) async {
    camera.startGate = Completer<void>();
    await show(tester);
    final shutter = find.byWidgetPredicate(
      (w) => w is GestureDetector && w.onLongPressStart != null,
    );
    final gesture = await tester.startGesture(tester.getCenter(shutter));
    await tester.pump(const Duration(milliseconds: 600));
    expect(camera.starts, 1);
    await gesture.up();
    await tester.pump();
    camera.startGate!.complete();
    await tester.pumpAndSettle();
    expect(camera.stops, 1);
    expect(camera.disposed, 1);
    expect(find.text('chat_share_retry'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('相机拒绝访问后可以重试', (tester) async {
    camera.denied = true;
    await show(tester);
    expect(find.text('chat_capture_error'), findsOneWidget);
    camera.denied = false;
    await tester.tap(find.text('chat_share_retry'));
    await tester.pumpAndSettle();
    expect(camera.opened.length, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('切后台释放相机，回到前台重新初始化', (tester) async {
    await show(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();
    expect(camera.disposed, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(camera.opened.length, 2);
    expect(tester.takeException(), isNull);
  });
}
