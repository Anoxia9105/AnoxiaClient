import 'dart:async';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:anoxia/framework/theme/AppColors.dart';
import 'package:hugeicons/hugeicons.dart';

class WindowScreenSelectDialog extends StatefulWidget {
  const WindowScreenSelectDialog({super.key});

  @override
  State<WindowScreenSelectDialog> createState() =>
      _WindowScreenSelectDialogState();
}

class _WindowScreenSelectDialogState extends State<WindowScreenSelectDialog> {
  final Map<String, rtc.DesktopCapturerSource> _sources = {};
  rtc.DesktopCapturerSource? _selectedSource;
  final List<StreamSubscription> _subscriptions = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _getSources();

    // 监听源的动态增减
    _subscriptions.add(
      rtc.desktopCapturer.onAdded.stream.listen((source) {
        setState(() => _sources[source.id] = source);
      }),
    );

    _subscriptions.add(
      rtc.desktopCapturer.onRemoved.stream.listen((source) {
        setState(() => _sources.remove(source.id));
      }),
    );

    _subscriptions.add(
      rtc.desktopCapturer.onThumbnailChanged.stream.listen((source) {
        if (_sources.containsKey(source.id)) {
          setState(() {
            _sources[source.id] = source;
          });
        }
      }),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  Future<void> _getSources() async {
    try {
      // 同时获取屏幕和窗口
      final types = [rtc.SourceType.Screen, rtc.SourceType.Window];
      final sources = await rtc.desktopCapturer.getSources(types: types);

      setState(() {
        _sources.clear();
        for (var element in sources) {
          _sources[element.id] = element;
        }
      });

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
        // updateSources 会触发 onThumbnailChanged / onAdded / onRemoved 流
        unawaited(rtc.desktopCapturer.updateSources(types: types));
      });
    } catch (e) {
      debugPrint('获取共享源失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = Theme.of(context).extension<AppColors>()?.scaffoldGradient;

    // 将源按类型分类
    final screens = _sources.values
        .where((s) => s.type == rtc.SourceType.Screen)
        .toList();
    final windows = _sources.values
        .where((s) => s.type == rtc.SourceType.Window)
        .toList();

    return Center(
      child: Dialog(
        child: Container(
          width: 700.w,
          height: 600.h,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // --- 屏幕部分 ---
                    if (screens.isNotEmpty) ...[
                      _buildSectionTitle("call_share_screen".tr()),
                      _buildSourceGrid(screens, crossCount: 2),
                    ],

                    // --- 窗口部分 ---
                    if (windows.isNotEmpty) ...[
                      _buildSectionTitle("call_share_window".tr()),
                      _buildSourceGrid(windows, crossCount: 3),
                    ],

                    // 底部留白
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  ],
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // 分组标题
  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  // 网格布局
  Widget _buildSourceGrid(
    List<rtc.DesktopCapturerSource> list, {
    required int crossCount,
  }) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossCount,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1.3,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final source = list[index];
          return ThumbnailWidget(
            source: source,
            selected: _selectedSource?.id == source.id,
            onTap: (s) => setState(() => _selectedSource = s),
            // 双击直接开始共享，提升效率
            onDoubleTap: (s) {
              setState(() => _selectedSource = s);
              _onOk();
            },
          );
        }, childCount: list.length),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          HugeIcon(icon: HugeIcons.strokeRoundedComputerScreenShare),
          const SizedBox(width: 10),
          Text(
            "call_share_select_title".tr(),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('dialog_cancel'.tr()),
          ),
          const SizedBox(width: 15),
          FilledButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _selectedSource != null ? _onOk : null,
            child: Text(
              "call_share_start".tr(),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _onOk() => Navigator.pop(context, _selectedSource);
}

class ThumbnailWidget extends StatelessWidget {
  final rtc.DesktopCapturerSource source;
  final bool selected;
  final Function(rtc.DesktopCapturerSource) onTap;
  final Function(rtc.DesktopCapturerSource) onDoubleTap;

  const ThumbnailWidget({
    super.key,
    required this.source,
    required this.selected,
    required this.onTap,
    required this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(source),
      onDoubleTap: () => onDoubleTap(source),
      child: Column(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                border: Border.all(
                  color: selected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.withValues(alpha: 0.2),
                  width: selected ? 3 : 1,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Container(
                  color: Colors.black87,
                  child: source.thumbnail != null
                      ? Image.memory(
                          source.thumbnail!,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        )
                      : const Center(
                          child: Icon(Icons.monitor, color: Colors.white24),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            source.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? Theme.of(context).primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }
}
