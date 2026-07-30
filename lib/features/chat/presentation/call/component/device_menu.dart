import 'dart:async';

import 'package:anoxia/common/widgets/BubbleDialog.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/features/chat/presentation/call/component/volume_indicator.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
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

/// 显示设备选择菜单
///
/// [items] 设备列表项
/// [footer] 底部附加组件（如麦克风音量指示器）
void showDeviceMenu({
  required BuildContext context,
  required List<DeviceMenuItem> items,
  Widget? footer,
}) {
  if (items.isEmpty) return;

  Function? close;
  close = Toast.showWidget(
    context,
    direction: PreferDirection.topRight,
    child: Material(
      color: Colors.transparent,
      child: BubbleWidget(
        arrowDirection: AxisDirection.up,
        arrowOffset: 280,
        backgroundColor: Theme.of(context).colorScheme.surface,
        border: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.5,
        ),
        contentBuilder: (context) => SizedBox(
          width: 300,
          height: 260,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < items.length; i++) ...[
                        ListTile(
                          dense: true,
                          onTap: () {
                            items[i].onTap();
                            close?.call();
                          },
                          selected: items[i].selected,
                          leading: Icon(
                            items[i].selected
                                ? Icons.check
                                : Icons.circle_outlined,
                            size: 16,
                            color: items[i].selected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                          ),
                          title: Text(
                            items[i].label,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 4,
                            style: TextStyle(
                              fontSize: 13,
                              color: items[i].selected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                        ),
                        if (i < items.length - 1) const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
              ),
              if (footer != null) ...[
                Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                footer,
              ],
            ],
          ),
        ),
      ),
    ),
  );
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