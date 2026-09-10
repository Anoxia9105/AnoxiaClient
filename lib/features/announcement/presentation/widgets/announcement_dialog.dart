import 'dart:math' as math;

import 'package:anoxia/common/utils/date_util.dart';
import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/framework/domain/announcement.dart';
import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 系统公告弹窗。
///
/// 桌面/平板：480 宽居中卡片；移动端：底部面板（顶部圆角 + 拖拽条）。
/// 普通公告可关闭（关闭后由调用方静默 markRead）；需确认公告为阻断式，
/// 不可点遮罩/下滑/返回关闭，必须显式确认。
class AnnouncementDialog extends StatefulWidget {
  const AnnouncementDialog({
    super.key,
    required this.announcement,
    required this.onClose,
    required this.onAcknowledge,
    this.queueIndex,
    this.queueTotal,
  });

  final Announcement announcement;
  final VoidCallback onClose;
  final Future<bool> Function() onAcknowledge;

  /// 当前公告在待处理队列中的 0 起索引，null 表示不展示队列指示。
  final int? queueIndex;

  /// 待处理队列总数，与 [queueIndex] 成对使用。
  final int? queueTotal;

  /// 按当前屏幕构建路由：移动端用底部面板，其余用居中弹窗。
  ///
  /// [dismissible] 为 false 时遮罩点击与下滑/返回均不可关闭（需确认公告）。
  static Route<void> buildRoute(
    BuildContext context,
    Widget Function(BuildContext) builder, {
    required bool dismissible,
  }) {
    if (DeviceUtil.isMobile(context)) {
      return ModalBottomSheetRoute<void>(
        capturedThemes: InheritedTheme.capture(from: context, to: null),
        builder: builder,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        isDismissible: dismissible,
        enableDrag: dismissible,
        showDragHandle: dismissible,
        isScrollControlled: true,
        useSafeArea: true,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(RadiusToken.xl)),
        ),
      );
    }
    return DialogRoute<void>(
      context: context,
      barrierDismissible: dismissible,
      builder: builder,
    );
  }

  @override
  State<AnnouncementDialog> createState() => _AnnouncementDialogState();
}

class _AnnouncementDialogState extends State<AnnouncementDialog> {
  bool _submitting = false;
  bool _ackFailed = false;

  Future<void> _acknowledge() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _ackFailed = false;
    });
    final success = await widget.onAcknowledge();
    if (!mounted) return;
    if (success) {
      widget.onClose();
      return;
    }
    setState(() {
      _submitting = false;
      _ackFailed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final required = widget.announcement.level == AnnouncementLevel.required;
    final isMobile = DeviceUtil.isMobile(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bodyMaxHeight =
        math.min(280.0, (isMobile ? 0.30 : 0.35) * screenHeight);
    final cardMaxHeight = math.max(96.0, screenHeight - 16.0);

    final queueIndex = widget.queueIndex;
    final queueTotal = widget.queueTotal;
    final showQueue = queueIndex != null && (queueTotal ?? 0) > 1;

    final chipColor = colorScheme.primaryContainer;
    final chipIconColor = colorScheme.onPrimaryContainer;

    final header = Padding(
      padding: isMobile ? const EdgeInsets.all(4) : EdgeInsets.zero,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: chipColor,
              borderRadius: BorderRadius.circular(RadiusToken.lg),
            ),
            child: Icon(
              required ? Icons.security : Icons.campaign,
              size: 19,
              color: chipIconColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    'announcement_settings_title'.tr(),
                    style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (required) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(RadiusToken.pill),
                    ),
                    child: Text(
                      'announcement_required_badge'.tr(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            DateUtil.formatShortDate(widget.announcement.publishAt),
            style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );

    final title = Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        widget.announcement.title,
        style: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
          height: 1.4,
        ),
      ),
    );

    final body = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: bodyMaxHeight),
      child: SingleChildScrollView(
        child: SelectableText(
          widget.announcement.content,
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
        ),
      ),
    );

    final errorBanner = _ackFailed
        ? Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(RadiusToken.lg),
            ),
              child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 16,
                  color: colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'announcement_ack_error'.tr(),
                    key: const Key('announcement-ack-error'),
                    style: TextStyle(color: colorScheme.onErrorContainer),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();

    final primaryButton = required
        ? Focus(
            autofocus: true,
            child: FilledButton(
              key: const Key('announcement-acknowledge'),
              onPressed: _submitting ? null : _acknowledge,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RadiusToken.lg),
                ),
              ),
              child: _submitting
                  ? SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : Text(
                      _ackFailed
                          ? 'announcement_retry'.tr()
                          : 'announcement_acknowledge'.tr(),
                    ),
            ),
          )
        : FilledButton(
            key: const Key('announcement-close'),
            onPressed: widget.onClose,
            child: Text('announcement_got_it'.tr()),
          );

    final dotCount = math.min(queueTotal ?? 0, 10);
    final queueIndicator = showQueue
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < dotCount; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i <= queueIndex
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              Flexible(
                child: Text(
                  '${queueIndex + 1}/${queueTotal ?? 0}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          )
        : const SizedBox.shrink();

    // 队列指示可收缩（窄屏/长文案不挤占按钮），按钮始终右对齐。
    final footer = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: queueIndicator),
        primaryButton,
      ],
    );

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        title,
        const SizedBox(height: 8),
        Flexible(child: body),
        errorBanner,
        const SizedBox(height: 16),
        footer,
      ],
    );

    // 注意：DialogRoute 的页面占满全屏，内容必须自行居中（标准 Dialog 内部
    // 也是用 alignment居中）。不包 Align/Center 会导致卡片被拉伸到全屏。
    final child = isMobile
        ? Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: cardMaxHeight),
              child: content,
            ),
          )
        : Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 480,
                maxHeight: cardMaxHeight,
              ),
              child: Material(
                color: colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    width: 1,
                    color: colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                  borderRadius: BorderRadius.circular(RadiusToken.xl),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: content,
                ),
              ),
            ),
          );

    return PopScope(
      canPop: !required,
      child: child,
    );
  }
}
