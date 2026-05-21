import 'dart:async';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:anoxia/framework/theme/AppColors.dart';
import 'package:hugeicons/hugeicons.dart';

/// 屏幕选择对话框
///
/// 用于在发起屏幕共享时选择要共享的屏幕或窗口。
/// 支持选择整个屏幕或单个应用程序窗口，并提供实时缩略图预览。
class WindowScreenSelectDialog extends StatefulWidget {
  const WindowScreenSelectDialog({super.key});

  @override
  State<WindowScreenSelectDialog> createState() =>
      _WindowScreenSelectDialogState();
}

class _WindowScreenSelectDialogState extends State<WindowScreenSelectDialog> {
  /// 可用的共享源（屏幕和窗口）
  final Map<String, rtc.DesktopCapturerSource> _sources = {};

  /// 当前选中的共享源
  rtc.DesktopCapturerSource? _selectedSource;

  /// 事件订阅列表
  final List<StreamSubscription> _subscriptions = [];

  /// 定时刷新缩略图的计时器
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _getSources();

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

  /// 获取可共享的屏幕和窗口列表
  Future<void> _getSources() async {
    try {
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
        unawaited(rtc.desktopCapturer.updateSources(types: types));
      });
    } catch (e) {
      debugPrint('获取共享源失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = Theme.of(context).extension<AppColors>()?.scaffoldGradient;

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
                    if (screens.isNotEmpty) ...[
                      _buildSectionTitle("call_share_screen".tr()),
                      _buildSourceGrid(screens, crossCount: 2),
                    ],

                    if (windows.isNotEmpty) ...[
                      _buildSectionTitle("call_share_window".tr()),
                      _buildSourceGrid(windows, crossCount: 3),
                    ],

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

  /// 构建分组标题
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

  /// 构建共享源网格
  ///
  /// [list] 共享源列表
  /// [crossCount] 网格列数
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
            onDoubleTap: (s) {
              setState(() => _selectedSource = s);
              _onOk();
            },
          );
        }, childCount: list.length),
      ),
    );
  }

  /// 构建对话框头部
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

  /// 构建对话框底部按钮栏
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

  /// 确认选择，返回选中的共享源
  void _onOk() => Navigator.pop(context, _selectedSource);
}

/// 共享源缩略图组件
///
/// 显示单个屏幕或窗口的缩略图预览，支持单击选择和双击确认
class ThumbnailWidget extends StatelessWidget {
  /// 共享源数据
  final rtc.DesktopCapturerSource source;

  /// 是否选中
  final bool selected;

  /// 单击回调
  final Function(rtc.DesktopCapturerSource) onTap;

  /// 双击回调（直接开始共享）
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
