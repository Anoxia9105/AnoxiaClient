import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:anoxia/platform/shims/capture_video.dart';

class ChatCaptureResult {
  final XFile file;
  final bool isVideo;
  const ChatCaptureResult(this.file, this.isVideo);
}

/// 轻触拍照、按住录像；离开页面或切后台立即释放相机。
class ChatCapturePage extends StatefulWidget {
  const ChatCapturePage({super.key});
  @override
  State<ChatCapturePage> createState() => _ChatCapturePageState();
}

class _ChatCapturePageState extends State<ChatCapturePage>
    with WidgetsBindingObserver {
  CameraController? _camera;
  VideoPlayerController? _video;
  List<CameraDescription> _cameras = [];
  ChatCaptureResult? _result;
  Uint8List? _photoBytes;
  Timer? _timer;
  int _seconds = 0;
  int _generation = 0;
  int _index = 0;
  bool _busy = false;
  bool _holding = false;
  bool _recording = false;
  bool _foreground = true;
  bool _flash = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_open());
  }

  Future<void> _open() async {
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _error = null;
    });
    CameraController? next;
    try {
      final old = _camera;
      _camera = null;
      await old?.dispose();
      if (_cameras.isEmpty) {
        _cameras = await availableCameras();
        final back = _cameras.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
        );
        if (back >= 0) _index = back;
      }
      if (_cameras.isEmpty) throw CameraException('NoCamera', '');
      if (!mounted || generation != _generation || !_foreground) return;
      next = CameraController(
        _cameras[_index],
        ResolutionPreset.high,
        enableAudio: true,
      );
      await next.initialize();
      try {
        await next.setFlashMode(FlashMode.off);
      } on CameraException {
        // 不支持闪光灯的设备仍可正常拍摄。
      }
      if (!mounted || generation != _generation || !_foreground) {
        await next.dispose();
        return;
      }
      _camera = next;
      _flash = false;
    } catch (_) {
      if (next != null && next != _camera) await next.dispose();
      if (mounted && generation == _generation) _error = 'chat_capture_error';
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _foreground = true;
      if (_result == null) unawaited(_open());
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _foreground = false;
      ++_generation;
      _timer?.cancel();
      _holding = false;
      _recording = false;
      final camera = _camera;
      _camera = null;
      unawaited(camera?.dispose());
      unawaited(_video?.pause());
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    ++_generation;
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    unawaited(_camera?.dispose());
    unawaited(_video?.dispose());
    super.dispose();
  }

  Future<void> _photo() async {
    final camera = _camera;
    if (_busy || _recording || camera == null) return;
    setState(() => _busy = true);
    try {
      final file = await camera.takePicture();
      if (mounted && _foreground) {
        await _preview(ChatCaptureResult(file, false));
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'chat_capture_failed');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startVideo() async {
    final camera = _camera;
    if (_busy || camera == null || _result != null) return;
    _holding = true;
    setState(() => _busy = true);
    try {
      await camera.startVideoRecording();
      if (!mounted || camera != _camera || !_foreground) return;
      _seconds = 0;
      setState(() {
        _recording = true;
        _busy = false;
      });
      // 用户可能在原生录制启动期间已经松手。
      if (!_holding) {
        await _stopVideo();
        return;
      }
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _seconds++);
        if (_seconds >= 60) unawaited(_stopVideo());
      });
    } catch (_) {
      // 原生启动可能部分成功；释放资源后由重试入口重新创建相机。
      if (_camera == camera) {
        _camera = null;
        await camera.dispose();
      }
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'chat_capture_failed';
        });
      }
    }
  }

  Future<void> _stopVideo() async {
    _holding = false;
    final camera = _camera;
    if (!_recording || _busy || camera == null) return;
    _timer?.cancel();
    setState(() => _busy = true);
    try {
      final file = await camera.stopVideoRecording();
      if (mounted && _foreground) await _preview(ChatCaptureResult(file, true));
    } catch (_) {
      // 停止失败不能只清 UI 状态，否则原生相机可能仍在后台录制。
      if (_camera == camera) {
        _camera = null;
        await camera.dispose();
      }
      if (mounted) setState(() => _error = 'chat_capture_failed');
    } finally {
      if (mounted) {
        setState(() {
          _recording = false;
          _busy = false;
        });
      }
    }
  }

  Future<void> _preview(ChatCaptureResult result) async {
    final camera = _camera;
    _camera = null;
    await camera?.dispose();
    if (!mounted) return;
    setState(() => _result = result);
    if (!result.isVideo) {
      final bytes = await result.file.readAsBytes();
      if (mounted) setState(() => _photoBytes = bytes);
    }
    if (result.isVideo) {
      final video = captureVideoController(result.file.path);
      _video = video;
      try {
        await video.initialize();
        if (!mounted || video != _video) return;
        await video.setLooping(true);
        await video.play();
        if (mounted) setState(() {});
      } catch (_) {
        if (mounted) setState(() => _error = 'chat_capture_failed');
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_busy || _recording) return;
    final camera = _camera;
    if (camera == null) return;
    setState(() => _busy = true);
    try {
      await camera.setFlashMode(_flash ? FlashMode.off : FlashMode.torch);
      if (mounted) setState(() => _flash = !_flash);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('chat_capture_flash_unavailable'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _retake() async {
    final video = _video;
    _video = null;
    await video?.dispose();
    if (!mounted) return;
    setState(() {
      _result = null;
      _photoBytes = null;
      _error = null;
    });
    await _open();
  }

  bool get _canFlip =>
      _cameras.any(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      ) &&
      _cameras.any(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );

  void _flipCamera() {
    final target = _cameras[_index].lensDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    final index = _cameras.indexWhere(
      (camera) => camera.lensDirection == target,
    );
    if (index < 0) return;
    _index = index;
    unawaited(_open());
  }

  @override
  Widget build(BuildContext context) {
    final camera = _camera;
    final result = _result;
    return PopScope(
      canPop: !_busy && !_recording,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'cancel'.tr(),
                    onPressed: _busy || _recording
                        ? null
                        : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                  const Spacer(),
                  if (_recording)
                    Text(
                      '00:${_seconds.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  if (result == null)
                    IconButton(
                      tooltip: 'chat_capture_flash'.tr(),
                      onPressed: _busy || _recording || camera == null
                          ? null
                          : _toggleFlash,
                      icon: Icon(
                        _flash
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: result != null
                        ? result.isVideo
                              ? _video?.value.isInitialized == true
                                    ? AspectRatio(
                                        aspectRatio: _video!.value.aspectRatio,
                                        child: VideoPlayer(_video!),
                                      )
                                    : const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                              : _photoBytes != null
                              ? Image.memory(
                                  _photoBytes!,
                                  fit: BoxFit.contain,
                                  gaplessPlayback: true,
                                )
                              : const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                        : camera?.value.isInitialized == true
                        ? CameraPreview(camera!)
                        : _busy
                        ? const CircularProgressIndicator(color: Colors.white)
                        : TextButton(
                            onPressed: _open,
                            child: Text('chat_share_retry'.tr()),
                          ),
                  ),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _error!.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 24,
                ),
                child: result != null
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white54),
                            ),
                            onPressed: _busy ? null : _retake,
                            child: Text('chat_capture_retake'.tr()),
                          ),
                          FilledButton.icon(
                            onPressed: _busy
                                ? null
                                : () => Navigator.pop(context, result),
                            icon: const Icon(Icons.send_rounded),
                            label: Text('chat_share_send'.tr()),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Text(
                            (_recording
                                    ? 'chat_capture_recording'
                                    : 'chat_capture_hint')
                                .tr(),
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(width: 48),
                              Semantics(
                                button: true,
                                label: 'chat_capture'.tr(),
                                child: GestureDetector(
                                  onTap: _busy ? null : _photo,
                                  onLongPressStart: _busy
                                      ? null
                                      : (_) => _startVideo(),
                                  onLongPressEnd: (_) => _stopVideo(),
                                  onLongPressCancel: _stopVideo,
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                    ),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 160,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _recording
                                            ? Colors.redAccent
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          _recording ? 16 : 40,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'chat_capture_flip'.tr(),
                                onPressed: _busy || _recording || !_canFlip
                                    ? null
                                    : _flipCamera,
                                icon: const Icon(
                                  Icons.flip_camera_ios_outlined,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
