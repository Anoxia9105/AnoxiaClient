import 'package:anoxia/common/utils/notification_helper.dart';
import 'package:anoxia/features/settings/presentation/widgets/settings_item_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Web 端浏览器通知授权分区
///
/// 浏览器只接受在**用户手势**（点击等）上下文中发起的 Notification 权限申请，
/// 在收到消息的异步回调里申请会被静默拒绝。因此这里提供一个显式按钮，
/// 让用户主动开启通知权限。仅在 Web 端渲染。
class SettingsWebNotificationSection extends StatefulWidget {
  const SettingsWebNotificationSection({super.key});

  @override
  State<SettingsWebNotificationSection> createState() =>
      _SettingsWebNotificationSectionState();
}

class _SettingsWebNotificationSectionState
    extends State<SettingsWebNotificationSection> {
  /// 当前权限是否已授予；null 表示尚未查询完成。
  bool? _granted;

  /// 是否正在申请中，避免重复弹窗。
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final granted = await NotificationHelper().isPermissionGranted();
    if (!mounted) return;
    setState(() => _granted = granted);
  }

  Future<void> _request() async {
    if (_requesting) return;
    setState(() => _requesting = true);
    try {
      // 该调用发生在按钮点击的手势上下文中，浏览器才会真正弹出授权框。
      final granted = await NotificationHelper().requestPermission();
      if (!mounted) return;
      setState(() => _granted = granted);
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final granted = _granted ?? false;

    return SettingItemCard(
      title: 'settings_web_notification_title'.tr(),
      subtitle: 'settings_web_notification_subtitle'.tr(),
      icon: HugeIcons.strokeRoundedNotification01,
      child: Row(
        children: [
          Expanded(
            child: Text(
              granted
                  ? 'settings_web_notification_granted'.tr()
                  : 'settings_web_notification_not_granted'.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: granted ? colorScheme.primary : colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.tonal(
            onPressed: (granted || _requesting) ? null : _request,
            child: _requesting
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  )
                : Text('settings_web_notification_enable'.tr()),
          ),
        ],
      ),
    );
  }
}
