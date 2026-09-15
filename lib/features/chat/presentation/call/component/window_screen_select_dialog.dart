import 'dart:async';
import 'dart:math' as math;
import 'package:hugeicons/hugeicons.dart';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:anoxia/common/widgets/adaptive_page_presenter.dart';
import 'package:anoxia/framework/theme/app_colors.dart';
import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:anoxia/framework/logs/debug_log.dart';

/// 桌面端屏幕共享：弹出窗口/屏幕选择对话框
///
/// 返回用户选中的屏幕源 ID；用户取消时返回 null。
/// 调用方需自行判断当前是否为桌面端。
///
/// 点击遮罩 / ESC 均视为"取消"，返回 null。
Future<String?> showDesktopScreenSourcePicker(BuildContext context) async {
  final source = await showEscClosableDialog<rtc.DesktopCapturerSource>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (_) => const WindowScreenSelectDialog(),
  );
  return source?.id;
}

/// 屏幕选择对话框
///
/// 用于在发起屏幕共享时选择要共享的屏幕或窗口。
/// 支持选择整个屏幕或单个应用程序窗口，并提供实时缩略图预览。
///
/// 交互约定：
/// - 单击卡片选中，双击卡片直接开始共享
/// - 底部左侧实时回显当前选中项，右侧为「取消 / 开始共享」
/// - ESC 或点击遮罩取消（由 [showEscClosableDialog] 承载）
class WindowScreenSelectDialog extends StatefulWidget {
  const WindowScreenSelectDialog({super.key});

  @override
  State<WindowScreenSelectDialog> createState() =>
      _WindowScreenSelectDialogState();
}

class _WindowScreenSelectDialogState extends State<WindowScreenSelectDialog> {
  /// 可用的共享源（屏幕和窗口），以 source.id 为键保证顺序稳定
  final Map<String, rtc.DesktopCapturerSource> _sources = {};

  /// 当前选中的共享源
  rtc.DesktopCapturerSource? _selectedSource;

  /// 事件订阅列表
  final List<StreamSubscription> _subscriptions = [];

  /// 定时刷新缩略图的计时器
  Timer? _timer;

  /// 内容区滚动控制器（供 Scrollbar 展示常驻滚动条）
  final ScrollController _scrollController = ScrollController();

  /// 首次拉取共享源中（用于展示加载态）
  bool _loading = true;

  /// 拉取失败原因（非空时展示错误态）
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_getSources());

    _subscriptions.add(
      rtc.desktopCapturer.onAdded.stream.listen((source) {
        if (!mounted) return;
        setState(() => _sources[source.id] = source);
      }),
    );

    _subscriptions.add(
      rtc.desktopCapturer.onRemoved.stream.listen((source) {
        if (!mounted) return;
        setState(() {
          _sources.remove(source.id);
          // 被共享的窗口/屏幕被关闭时，同步清空选中态，
          // 否则会出现"选中项已消失但开始共享仍可点"的错觉
          if (_selectedSource?.id == source.id) {
            _selectedSource = null;
          }
        });
      }),
    );

    _subscriptions.add(
      rtc.desktopCapturer.onThumbnailChanged.stream.listen((source) {
        if (!mounted || !_sources.containsKey(source.id)) return;
        setState(() => _sources[source.id] = source);
      }),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  /// 获取可共享的屏幕和窗口列表
  Future<void> _getSources() async {
    final types = [rtc.SourceType.Screen, rtc.SourceType.Window];
    try {
      final sources = await rtc.desktopCapturer.getSources(types: types);
      if (!mounted) return;
      setState(() {
        _sources
          ..clear()
          ..addEntries(sources.map((e) => MapEntry(e.id, e)));
        _loading = false;
        _error = null;
        // 列表变化后选中的对象已失效，重置选中态
        final selected = _selectedSource;
        if (selected != null && !_sources.containsKey(selected.id)) {
          _selectedSource = null;
        }
      });
      _startThumbnailRefresh(types);
    } catch (e) {
      debugLog('获取共享源失败: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  /// 启动缩略图定时刷新（仅列表非空时需要）
  void _startThumbnailRefresh(List<rtc.SourceType> types) {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => unawaited(_refreshThumbnails(types)),
    );
  }

  /// 拉取最新缩略图（失败不打断定时器，仅记录日志）
  Future<void> _refreshThumbnails(List<rtc.SourceType> types) async {
    try {
      await rtc.desktopCapturer.updateSources(types: types);
    } catch (e) {
      debugLog('刷新共享源缩略图失败: $e');
    }
  }

  /// 手动刷新（刷新过程中保留当前选中项）
  void _refresh() {
    _timer?.cancel();
    setState(() {
      _loading = true;
      _error = null;
    });
    unawaited(_getSources());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gradient = Theme.of(context).extension<AppColors>()?.scaffoldGradient;
    final size = MediaQuery.sizeOf(context);

    // 桌面端禁用 ScreenUtil 的 .w/.h 缩放：
    // designSize 为 375 宽，700.w 在 1920 宽的窗口上会被放大到约 3584 逻辑像素，
    // 直接把弹窗撑爆屏幕。这里按窗口逻辑像素计算并留出 32 的内边距。
    final dialogWidth = math.min(
      math.max(size.width * 0.78, 380.0),
      math.min(860.0, size.width - 32),
    );
    final dialogHeight = math.min(
      math.max(size.height * 0.82, 320.0),
      math.min(640.0, size.height - 32),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          // 渐变主题下用渐变，其余主题回落为表面色，保证暗色模式不会"黑成一片"
          gradient: gradient,
          color: gradient == null ? cs.surface : null,
          borderRadius: BorderRadius.circular(RadiusToken.xl),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x59000000),
              blurRadius: 40,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            Divider(
              height: 1,
              thickness: 1,
              color: cs.outlineVariant.withValues(alpha: 0.4),
            ),
            Expanded(child: _buildBody(dialogWidth)),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ===================== 头部 =====================

  /// 构建对话框头部：图标徽章 + 标题/副标题 + 刷新/关闭
  Widget _buildHeader() {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(RadiusToken.lg),
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedComputerScreenShare,
              size: 20,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'call_share_select_title'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'call_share_subtitle'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _IconAction(
            icon: HugeIcons.strokeRoundedRefresh01,
            tooltip: 'call_share_refresh'.tr(),
            onTap: _refresh,
          ),
          const SizedBox(width: 2),
          _IconAction(
            icon: HugeIcons.strokeRoundedCancel01,
            tooltip: 'dialog_cancel'.tr(),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // ===================== 主体 =====================

  /// 构建内容区：加载态 / 错误态 / 空态 / 分组网格
  Widget _buildBody(double dialogWidth) {
    if (_loading) {
      return _buildPlaceholder(
        child: const SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
        text: 'call_share_loading'.tr(),
      );
    }

    if (_error != null) {
      return _buildPlaceholder(
        icon: HugeIcons.strokeRoundedInformationCircle,
        text: 'call_share_empty'.tr(),
        action: TextButton.icon(
          onPressed: _refresh,
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedRefresh01, size: 15),
          label: Text('call_share_refresh'.tr()),
        ),
      );
    }

    final screens = _sources.values
        .where((s) => s.type == rtc.SourceType.Screen)
        .toList();
    final windows = _sources.values
        .where((s) => s.type == rtc.SourceType.Window)
        .toList();

    if (screens.isEmpty && windows.isEmpty) {
      return _buildPlaceholder(
        icon: HugeIcons.strokeRoundedComputer,
        text: 'call_share_empty'.tr(),
        action: TextButton.icon(
          onPressed: _refresh,
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedRefresh01, size: 15),
          label: Text('call_share_refresh'.tr()),
        ),
      );
    }

    // 列数按弹窗实际宽度自适应，窄窗（通话小窗）也能保证缩略图不被压扁
    final screenCols = dialogWidth >= 720 ? 3 : 2;
    final windowCols = dialogWidth >= 720 ? 4 : 3;

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: screens.length + windows.length > 4,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          if (screens.isNotEmpty) ...[
            _buildSectionTitle('call_share_screen'.tr(), screens.length),
            _buildSourceGrid(screens, crossCount: screenCols),
          ],
          if (windows.isNotEmpty) ...[
            _buildSectionTitle('call_share_window'.tr(), windows.length),
            _buildSourceGrid(windows, crossCount: windowCols),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  /// 加载/错误/空状态的统一占位视图
  Widget _buildPlaceholder({
    List<List<dynamic>>? icon,
    Widget? child,
    required String text,
    Widget? action,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (child != null)
            child
          else if (icon != null)
            HugeIcon(
              icon: icon,
              size: 34,
              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          const SizedBox(height: 14),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          if (action != null) ...[const SizedBox(height: 6), action],
        ],
      ),
    );
  }

  /// 构建分组标题：标题 + 数量徽标
  Widget _buildSectionTitle(String title, int count) {
    final cs = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(RadiusToken.pill),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建共享源网格
  ///
  /// [list] 共享源列表；[crossCount] 网格列数
  Widget _buildSourceGrid(
    List<rtc.DesktopCapturerSource> list, {
    required int crossCount,
  }) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.42,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final source = list[index];
          return ThumbnailWidget(
            key: ValueKey(source.id),
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

  // ===================== 底部 =====================

  /// 构建底部按钮栏：左「选中回显 / 操作提示」，右「取消 / 开始共享」
  Widget _buildFooter() {
    final cs = Theme.of(context).colorScheme;
    final selected = _selectedSource;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: selected == null
                  ? _footerHint()
                  : _footerSelection(selected),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(RadiusToken.md),
              ),
            ),
            child: Text('dialog_cancel'.tr()),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(RadiusToken.md),
              ),
            ),
            onPressed: selected != null ? _onOk : null,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedComputerScreenShare,
              size: 16,
            ),
            label: Text(
              'call_share_start'.tr(),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// 未选中时的操作提示
  Widget _footerHint() {
    final cs = Theme.of(context).colorScheme;
    return Row(
      key: const ValueKey('hint'),
      children: [
        HugeIcon(
          icon: HugeIcons.strokeRoundedInformationCircle,
          size: 14,
          color: cs.onSurfaceVariant.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'call_share_pick_hint'.tr(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  /// 已选中时回显选中项名称，避免用户在多屏场景下忘记选了哪块
  Widget _footerSelection(rtc.DesktopCapturerSource source) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      key: const ValueKey('selected'),
      children: [
        HugeIcon(
          icon: HugeIcons.strokeRoundedCheckmarkCircle01,
          size: 15,
          color: cs.primary,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'call_share_selected'.tr(args: [source.name]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  /// 确认选择，返回选中的共享源
  void _onOk() => Navigator.pop(context, _selectedSource);
}

/// 头部图标按钮（悬停有底色，弱化视觉噪音）
class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(RadiusToken.md),
        hoverColor: cs.onSurface.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: HugeIcon(
            icon: icon,
            size: 17,
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// 共享源缩略图组件
///
/// 显示单个屏幕或窗口的缩略图预览，支持单击选择和双击确认。
/// 选中态：主色描边 + 主色辉光 + 右上角对勾徽标。
class ThumbnailWidget extends StatefulWidget {
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
  State<ThumbnailWidget> createState() => _ThumbnailWidgetState();
}

class _ThumbnailWidgetState extends State<ThumbnailWidget> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selected = widget.selected;
    final hovered = _hovered && !selected;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => widget.onTap(widget.source),
        onDoubleTap: () => widget.onDoubleTap(widget.source),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(
              alpha: selected ? 0.85 : (hovered ? 0.7 : 0.5),
            ),
            borderRadius: BorderRadius.circular(RadiusToken.lg),
            border: Border.all(
              color: selected
                  ? cs.primary
                  : cs.outlineVariant.withValues(alpha: hovered ? 0.9 : 0.5),
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                )
              else if (hovered)
                const BoxShadow(
                  color: Color(0x2E000000),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(RadiusToken.md),
                  child: ColoredBox(
                    color: const Color(0xFF101114),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (widget.source.thumbnail != null)
                          Image.memory(
                            widget.source.thumbnail!,
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                            filterQuality: FilterQuality.medium,
                          )
                        else
                          const Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedComputer,
                              color: Colors.white24,
                              size: 30,
                            ),
                          ),
                        if (selected)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 20,
                              height: 20,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: cs.surface,
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x40000000),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                                size: 16,
                                color: cs.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Tooltip(
                  message: widget.source.name,
                  waitDuration: const Duration(milliseconds: 600),
                  child: Text(
                    widget.source.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.2,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? cs.primary : cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
