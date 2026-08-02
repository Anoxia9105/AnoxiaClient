import 'dart:async';

import 'package:anoxia/common/widgets/bubble_dialog.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/features/chat/presentation/call/component/volume_indicator.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:livekit_client/livekit_client.dart';

/// 设备菜单项数据
class DeviceMenuItem {
  /// 设备名称
  final String label;

  /// 是否选中
  final bool selected;

  /// 点击回调
  final VoidCallback onTap;

  const DeviceMenuItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });
}

/// 显示设备选择气泡菜单
///
/// [items] 设备列表项
/// [footer] 底部附加组件（如麦克风音量指示器）
/// [title] 菜单标题（如"麦克风"），为空时隐藏标题栏
/// [icon] 标题栏图标
void showDeviceMenu({
  required BuildContext context,
  required List<DeviceMenuItem> items,
  Widget? footer,
  String? title,
  List<List<dynamic>>? icon,
}) {
  Function? close;
  close = Toast.showWidget(
    context,
    direction: PreferDirection.topRight,
    child: Material(
      color: Colors.transparent,
      child: CallBubbleMenu(
        anchorContext: context,
        borderRadius: BorderRadius.circular(12),
        backgroundColor: Theme.of(context).colorScheme.surface,
        border: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.5,
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x2E000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
        contentBuilder: (context) => _DeviceMenuContent(
          title: title,
          icon: icon,
          items: items,
          footer: footer,
          onClose: () => close?.call(),
        ),
      ),
    ),
  );
}

/// 通话页气泡菜单容器
///
/// 自带淡入 + 缩放入场动画，并通过测量触发按钮的位置，
/// 让气泡箭头始终精确指向按钮（自动处理气泡在按钮上方/下方的情况）。
class CallBubbleMenu extends StatefulWidget {
  /// 触发菜单的按钮 Context，用于定位箭头
  final BuildContext anchorContext;

  /// 气泡内容
  final WidgetBuilder contentBuilder;

  final BorderRadius borderRadius;

  final BorderSide border;

  final Color? backgroundColor;

  final double arrowLength;

  final double arrowWidth;

  final double arrowRadius;

  final List<BoxShadow>? shadows;

  const CallBubbleMenu({
    super.key,
    required this.anchorContext,
    required this.contentBuilder,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.border = BorderSide.none,
    this.backgroundColor,
    this.arrowLength = 10,
    this.arrowWidth = 17,
    this.arrowRadius = 3,
    this.shadows,
  });

  @override
  State<CallBubbleMenu> createState() => _CallBubbleMenuState();
}

class _CallBubbleMenuState extends State<CallBubbleMenu> {
  final GlobalKey _bubbleKey = GlobalKey();

  AxisDirection _arrowDirection = AxisDirection.up;

  double _arrowOffset = 160;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureArrow());
  }

  /// 测量气泡与触发按钮的位置关系，计算箭头方向和偏移
  void _measureArrow() {
    if (!mounted) return;
    final anchorBox = widget.anchorContext.findRenderObject() as RenderBox?;
    final bubbleBox = _bubbleKey.currentContext?.findRenderObject() as RenderBox?;
    if (anchorBox == null ||
        bubbleBox == null ||
        !anchorBox.hasSize ||
        !bubbleBox.hasSize) {
      return;
    }

    final anchorCenter = anchorBox.localToGlobal(
      anchorBox.size.center(Offset.zero),
    );
    final bubbleRect = bubbleBox.localToGlobal(Offset.zero) & bubbleBox.size;
    final offset = (anchorCenter.dx - bubbleRect.left).clamp(
      widget.arrowWidth / 2 + 8,
      bubbleRect.width - widget.arrowWidth / 2 - 8,
    );
    // 气泡在按钮上方 → 箭头在气泡底部指向按钮（AxisDirection.down）
    // 气泡在按钮下方 → 箭头在气泡顶部指向按钮（AxisDirection.up）
    final direction = anchorCenter.dy >= bubbleRect.bottom
        ? AxisDirection.down
        : AxisDirection.up;

    if (direction == _arrowDirection && (offset - _arrowOffset).abs() < 0.5) {
      return;
    }
    setState(() {
      _arrowDirection = direction;
      _arrowOffset = offset;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.scale(
            scale: 0.94 + 0.06 * t,
            alignment: Alignment.topCenter,
            child: child,
          ),
        );
      },
      child: BubbleWidget(
        key: _bubbleKey,
        arrowDirection: _arrowDirection,
        arrowOffset: _arrowOffset,
        arrowLength: widget.arrowLength,
        arrowWidth: widget.arrowWidth,
        arrowRadius: widget.arrowRadius,
        borderRadius: widget.borderRadius,
        border: widget.border,
        backgroundColor: widget.backgroundColor,
        shadows: widget.shadows,
        contentBuilder: widget.contentBuilder,
      ),
    );
  }
}

/// 设备菜单内容
class _DeviceMenuContent extends StatelessWidget {
  final String? title;

  final List<List<dynamic>>? icon;

  final List<DeviceMenuItem> items;

  final Widget? footer;

  final VoidCallback? onClose;

  const _DeviceMenuContent({
    this.title,
    this.icon,
    required this.items,
    this.footer,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 320,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      HugeIcon(
                        icon: icon!,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      title!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onClose,
                      visualDensity: VisualDensity.compact,
                      iconSize: 16,
                      tooltip: 'call_close_tooltip'.tr(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            Divider(
              height: 1,
              thickness: 0.5,
              color: theme.colorScheme.outlineVariant,
            ),
            if (items.isEmpty)
              _EmptyDevices()
            else
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < items.length; i++)
                        _DeviceItemTile(
                          item: items[i],
                          onTap: () {
                            items[i].onTap();
                            onClose?.call();
                          },
                        ),
                    ],
                  ),
                ),
              ),
            if (footer != null) ...[
              Divider(
                height: 1,
                thickness: 0.5,
                color: theme.colorScheme.outlineVariant,
              ),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

/// 设备菜单项（单行显示，超长省略）
class _DeviceItemTile extends StatelessWidget {
  final DeviceMenuItem item;

  final VoidCallback onTap;

  const _DeviceItemTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      hoverColor: primary.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              item.selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 18,
              color: item.selected ? primary : theme.colorScheme.outlineVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: item.selected ? FontWeight.w600 : FontWeight.w400,
                  color: item.selected
                      ? primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 无可用设备时的空状态
class _EmptyDevices extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.devices_other_outlined,
            size: 30,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 10),
          Text(
            'call_no_device'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 本地音量指示器底部组件
///
/// 在麦克风设备选择菜单底部显示实时音量
class LocalVolumeFooter extends StatefulWidget {
  /// 本地参与者实例
  final LocalParticipant localParticipant;

  const LocalVolumeFooter({super.key, required this.localParticipant});

  @override
  State<LocalVolumeFooter> createState() => _LocalVolumeFooterState();
}

class _LocalVolumeFooterState extends State<LocalVolumeFooter> {
  Timer? _timer;
  double _volume = 0.0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      final v = widget.localParticipant.audioLevel;
      if ((v - _volume).abs() > 0.005) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _volume = v);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mic,
            size: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          VolumeIndicator(volume: _volume),
        ],
      ),
    );
  }
}
