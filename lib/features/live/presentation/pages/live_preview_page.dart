// 直播预览页面
//
// 在正式开播前提供预览和配置界面，用户可以选择摄像头或屏幕共享源、
// 设置直播可见性，并通过预览确认画面效果后再开播。
import 'package:anoxia/common/utils/device_util.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/common/utils/app_permission.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/features/chat/presentation/call/component/window_screen_select_dialog.dart';
import 'package:anoxia/features/live/presentation/pages/live_room_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:anoxia/platform/shims/window_manager_shim.dart';

/// 直播预览页面
///
/// 开播前的预览与配置页面，支持摄像头和屏幕共享两种直播源。
/// 预览画面通过 LiveKit 本地视频轨道渲染，用户可在此设置标题、
/// 可见性和直播源，确认无误后点击开播按钮进入直播间。
class LivePreviewPage extends StatefulWidget {
  /// 直播的可见性设置
  final LiveVisibility visibility;
  /// 初始直播源类型
  final LiveSource initialSource;
  /// 初始标题文本
  final String initialTitle;
  /// 开播回调，传入标题、可见性、直播源和屏幕源 ID 后由父级处理开播逻辑
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
      Toast.showNotificationNow('live_title_required'.tr());
      return;
    }
    if (title.length > 60) {
      Toast.showNotificationNow('live_title_max_length'.tr());
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
      Toast.showNotificationNow('live_start_error'.tr(args: [e.toString()]));
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
        title: Text('live_preview_title'.tr()),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        leading: isDesktop
            ? null
            : IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01),
              ),
        automaticallyImplyLeading: !isDesktop,
        flexibleSpace: isDesktop
            ? const DragToMoveArea(child: SizedBox.expand())
            : null,
        actions: [
          if (isDesktop) ...[
            IconButton(
              tooltip: 'call_minimize_tooltip'.tr(),
              onPressed: () => windowManager.minimize(),
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedMinimize01),
            ),
            IconButton(
              tooltip: 'call_close_tooltip'.tr(),
              onPressed: () => windowManager.close(),
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01),
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
                    decoration: InputDecoration(
                      counterStyle: const TextStyle(color: Colors.white54),
                      labelText: 'live_title_label'.tr(),
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: 'live_title_hint_preview'.tr(),
                      hintStyle: const TextStyle(color: Colors.white38),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<LiveVisibility>(
                          segments: [
                            ButtonSegment(
                              value: LiveVisibility.public,
                              icon: const HugeIcon(icon: HugeIcons.strokeRoundedGlobe02),
                              label: Text('live_visibility_public'.tr()),
                            ),
                            ButtonSegment(
                              value: LiveVisibility.private,
                              icon: const HugeIcon(icon: HugeIcons.strokeRoundedLock),
                              label: Text('live_visibility_private'.tr()),
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
                          segments: [
                            ButtonSegment(
                              value: LiveSource.camera,
                              icon: const HugeIcon(icon: HugeIcons.strokeRoundedVideo01),
                              label: Text('live_source_camera'.tr()),
                            ),
                            ButtonSegment(
                              value: LiveSource.screen,
                              icon: const HugeIcon(icon: HugeIcons.strokeRoundedComputerScreenShare),
                              label: Text('live_source_screen_short'.tr()),
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
                          'live_info_template'.tr(args: [_visibility.trLabel(), _source.trLabel()]),
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
                            : const HugeIcon(icon: HugeIcons.strokeRoundedLiveStreaming01),
                        label: Text(_starting ? 'live_starting'.tr() : 'live_start_now'.tr()),
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
              const HugeIcon(icon: HugeIcons.strokeRoundedVideoOff, color: Colors.white70, size: 64),
              const SizedBox(height: 12),
              Text(
                '预览启动失败：$_error',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: _startPreview,
                child: Text('live_action_retry'.tr()),
              ),
            ],
          ),
        ),
      );
    }

    final track = _previewTrack;
    if (track == null) {
      return const Center(
        child: HugeIcon(icon: HugeIcons.strokeRoundedVideoOff, color: Colors.white70, size: 64),
      );
    }

    return VideoTrackRenderer(track, fit: VideoViewFit.contain);
  }
}
