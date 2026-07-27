import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/utils/AppPermission.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/features/chat/presentation/call/component/window_screen_select_dialog.dart';
import 'package:anoxia/features/live/presentation/pages/live_room_page.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:window_manager/window_manager.dart';

class LivePreviewPage extends StatefulWidget {
  final LiveVisibility visibility;
  final LiveSource initialSource;
  final String initialTitle;
  final Future<void> Function({
    required String title,
    required LiveVisibility visibility,
    required LiveSource source,
    String? sourceId,
  })
  onStart;

  const LivePreviewPage({
    super.key,
    required this.visibility,
    this.initialSource = LiveSource.camera,
    this.initialTitle = '',
    required this.onStart,
  });

  @override
  State<LivePreviewPage> createState() => _LivePreviewPageState();
}

class _LivePreviewPageState extends State<LivePreviewPage> {
  final TextEditingController _titleController = TextEditingController();
  LocalVideoTrack? _previewTrack;
  late LiveVisibility _visibility;
  LiveSource _source = LiveSource.camera;
  String? _screenSourceId;
  bool _loading = true;
  bool _starting = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _visibility = widget.visibility;
    _source = widget.initialSource;
    _titleController.text = widget.initialTitle;
    _startPreview();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _disposePreviewTrack();
    super.dispose();
  }

  Future<void> _switchSource(LiveSource source) async {
    if (_source == source || _starting) return;
    setState(() => _source = source);
    await _startPreview();
  }

  Future<void> _startPreview() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    await _disposePreviewTrack();

    try {
      LocalVideoTrack track;
      if (_source == LiveSource.camera) {
        _screenSourceId = null;
        if (!mounted) return;
        final camera = await ensureAppPermission(
          context,
          Permission.camera,
          permissionName: '摄像头',
        );
        if (!mounted) return;
        final mic = await ensureAppPermission(
          context,
          Permission.microphone,
          permissionName: '麦克风',
        );
        if (!camera || !mic) {
          throw Exception('需要开启摄像头和麦克风权限');
        }
        track = await LocalVideoTrack.createCameraTrack(
          const CameraCaptureOptions(params: VideoParametersPresets.h720_169),
        );
      } else {
        String? sourceId;
        if (DeviceUtil.isRealDesktop() && mounted) {
          final source = await showDialog<dynamic>(
            context: context,
            builder: (context) => const WindowScreenSelectDialog(),
          );
          if (source == null) {
            throw Exception('未选择共享屏幕或窗口');
          }
          sourceId = source.id?.toString();
        }
        _screenSourceId = sourceId;
        if (!mounted) return;
        final mic = await ensureAppPermission(
          context,
          Permission.microphone,
          permissionName: '麦克风',
        );
        if (!mic) {
          throw Exception('需要开启麦克风权限');
        }
        track = await LocalVideoTrack.createScreenShareTrack(
          ScreenShareCaptureOptions(
            sourceId: sourceId,
            captureScreenAudio: true,
            maxFrameRate: 15,
            params: VideoParametersPresets.screenShareH1080FPS15,
          ),
        );
      }

      if (!mounted) {
        await track.stop();
        return;
      }

      setState(() {
        _previewTrack = track;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _disposePreviewTrack() async {
    final track = _previewTrack;
    _previewTrack = null;
    try {
      await track?.stop();
    } catch (_) {}
  }

  Future<void> _startLive() async {
    if (_starting) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      Toast.showNotificationNow('请填写直播标题');
      return;
    }
    if (title.length > 60) {
      Toast.showNotificationNow('直播标题不能超过 60 个字符');
      return;
    }

    setState(() => _starting = true);
    try {
      await _disposePreviewTrack();
      await widget.onStart(
        title: title,
        visibility: _visibility,
        source: _source,
        sourceId: _source == LiveSource.screen ? _screenSourceId : null,
      );
    } catch (e) {
      if (!mounted) return;
      Toast.showNotificationNow('开播失败：$e');
      setState(() => _starting = false);
      if (_previewTrack == null) {
        await _startPreview();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = DeviceUtil.isRealDesktop();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('直播预览'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        leading: isDesktop
            ? null
            : IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
              ),
        automaticallyImplyLeading: !isDesktop,
        flexibleSpace: isDesktop
            ? const DragToMoveArea(child: SizedBox.expand())
            : null,
        actions: [
          if (isDesktop) ...[
            IconButton(
              tooltip: '最小化',
              onPressed: () => windowManager.minimize(),
              icon: const Icon(Icons.minimize),
            ),
            IconButton(
              tooltip: '关闭',
              onPressed: () => windowManager.close(),
              icon: const Icon(Icons.close),
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildPreview()),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _titleController,
                    enabled: !_starting,
                    style: const TextStyle(color: Colors.white),
                    maxLength: 60,
                    decoration: const InputDecoration(
                      counterStyle: TextStyle(color: Colors.white54),
                      labelText: '直播标题',
                      labelStyle: TextStyle(color: Colors.white70),
                      hintText: '例如：今晚一起聊产品设计',
                      hintStyle: TextStyle(color: Colors.white38),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<LiveVisibility>(
                          segments: const [
                            ButtonSegment(
                              value: LiveVisibility.public,
                              icon: Icon(Icons.public),
                              label: Text('公开'),
                            ),
                            ButtonSegment(
                              value: LiveVisibility.private,
                              icon: Icon(Icons.lock_outline),
                              label: Text('私密'),
                            ),
                          ],
                          selected: {_visibility},
                          onSelectionChanged: _starting
                              ? null
                              : (value) {
                                  setState(() => _visibility = value.first);
                                },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SegmentedButton<LiveSource>(
                          segments: const [
                            ButtonSegment(
                              value: LiveSource.camera,
                              icon: Icon(Icons.videocam),
                              label: Text('摄像头'),
                            ),
                            ButtonSegment(
                              value: LiveSource.screen,
                              icon: Icon(Icons.screen_share),
                              label: Text('屏幕'),
                            ),
                          ],
                          selected: {_source},
                          onSelectionChanged: _starting
                              ? null
                              : (value) => _switchSource(value.first),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_visibility.label}直播 · ${_source.label} · 房间号由服务端生成',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _loading || _error != null || _starting
                            ? null
                            : _startLive,
                        icon: _starting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.live_tv),
                        label: Text(_starting ? '开播中' : '开始直播'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off, color: Colors.white70, size: 64),
              const SizedBox(height: 12),
              Text(
                '预览启动失败：$_error',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: _startPreview,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    final track = _previewTrack;
    if (track == null) {
      return const Center(
        child: Icon(Icons.videocam_off, color: Colors.white70, size: 64),
      );
    }

    return VideoTrackRenderer(track, fit: VideoViewFit.contain);
  }
}
