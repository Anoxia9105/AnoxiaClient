import 'dart:async';

import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/features/chat/presentation/widgets/desktop_drop_files.dart';
import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// 只在原生桌面的当前聊天页面接收文件；遮罩不抢输入框焦点。
class DesktopChatDropTarget extends StatefulWidget {
  const DesktopChatDropTarget({
    super.key,
    required this.roomId,
    required this.enabled,
    required this.onFiles,
    required this.onRejected,
    required this.child,
  });

  final String roomId;
  final bool enabled;
  final Future<void> Function(
    List<PlatformFile> files,
    bool Function() isActive,
  )
  onFiles;
  final void Function(List<String> names) onRejected;
  final Widget child;

  @override
  State<DesktopChatDropTarget> createState() => _DesktopChatDropTargetState();
}

class _DesktopChatDropTargetState extends State<DesktopChatDropTarget> {
  bool _hovering = false;
  bool _preparing = false;
  int _generation = 0;

  bool get _available =>
      widget.enabled &&
      DeviceUtil.isRealDesktop() &&
      TickerMode.valuesOf(context).enabled &&
      (ModalRoute.of(context)?.isCurrent ?? true);

  @override
  void didUpdateWidget(DesktopChatDropTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roomId != widget.roomId ||
        oldWidget.enabled != widget.enabled) {
      _generation++;
      _hovering = false;
    }
  }

  Future<void> _accept(DropDoneDetails details) async {
    if (!_available || _preparing || details.files.isEmpty) return;
    final generation = _generation;
    bool isActive() => mounted && generation == _generation && _available;
    setState(() {
      _hovering = false;
      _preparing = true;
    });
    try {
      final result = await prepareDesktopDropFiles(details.files);
      if (!isActive()) return;
      if (result.rejected.isNotEmpty) widget.onRejected(result.rejected);
      if (result.files.isNotEmpty) {
        await widget.onFiles(result.files, isActive);
      }
    } catch (error, stack) {
      debugLog('桌面文件拖放处理失败', error, stack);
      if (isActive()) {
        widget.onRejected(details.files.map((f) => f.name).toList());
      }
    } finally {
      if (mounted) setState(() => _preparing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!DeviceUtil.isRealDesktop()) return widget.child;
    final visible = _available && (_hovering || _preparing);
    return DropTarget(
      enable: _available && !_preparing,
      onDragEntered: (_) => setState(() => _hovering = true),
      onDragExited: (_) => setState(() => _hovering = false),
      onDragDone: (details) => unawaited(_accept(details)),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 160),
                child: visible
                    ? _DropOverlay(preparing: _preparing)
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropOverlay extends StatelessWidget {
  const _DropOverlay({required this.preparing});
  final bool preparing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(RadiusToken.xl),
          border: Border.all(color: colors.primary, width: 2),
        ),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(RadiusToken.xl),
                ),
                child: preparing
                    ? SizedBox.square(
                        dimension: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.onPrimaryContainer,
                        ),
                      )
                    : Icon(
                        Icons.file_upload_outlined,
                        size: 28,
                        color: colors.onPrimaryContainer,
                      ),
              ),
              const SizedBox(height: 16),
              Text(
                (preparing ? 'chat_drop_preparing' : 'chat_drop_title').tr(),
                textAlign: TextAlign.center,
                style: text.titleMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'chat_drop_hint'.tr(),
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'chat_drop_limits'.tr(),
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
