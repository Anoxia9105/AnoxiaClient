import 'package:anoxia/framework/domain/official_room_config.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/desktop/launch_at_startup_provider.dart';
import 'package:anoxia/framework/provider/setting/general_settings_provider.dart';
import 'package:anoxia/framework/provider/setting/hide_official_room_provider.dart';
import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/platform/shims/auto_start_shim.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 设置页「通用」分区
///
/// 整合窗口、动效、字号、快捷键、通知预览、媒体与官方入口等通用能力。
class SettingsGeneralSection extends ConsumerWidget {
  const SettingsGeneralSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(hideOfficialRoomProvider);
    final visible = !hidden;
    final minimizeToTray = ref.watch(windowMinimizeToTrayProvider);
    final reduceMotion = ref.watch(reduceMotionProvider);
    final textScale = ref.watch(textScaleProvider);
    final sendShortcut = ref.watch(chatSendShortcutProvider);
    final messagePreview = ref.watch(messagePreviewProvider);
    final autoPlay = ref.watch(autoPlayMediaProvider);
    final autoDownloadUpdate = ref.watch(autoDownloadUpdateProvider);
    final updateCellularDownload = ref.watch(updateCellularDownloadProvider);
    final launchAtStartup = ref.watch(launchAtStartupProvider);
    final launchSilent = ref.watch(launchAtStartupSilentProvider);
    final startupSupported = autoStartSupported();
    // 开机自启是桌面端专属能力（Web/移动端无此概念）
    final showStartupGroup = DeviceUtil.isRealDesktop();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GroupLabel(icon: HugeIcons.strokeRoundedComputer, title: 'settings_general_group_interface'.tr()),
        _SettingsCard(
          children: [
            _SwitchTile(
              icon: HugeIcons.strokeRoundedMinimizeScreen,
              title: 'settings_window_minimize_to_tray'.tr(),
              subtitle: 'settings_window_minimize_to_tray_desc'.tr(),
              value: minimizeToTray,
              onChanged: (v) => ref.read(windowMinimizeToTrayProvider.notifier).setEnabled(v),
            ),
            _Divider(),
            _SwitchTile(
              icon: HugeIcons.strokeRoundedSparkles,
              title: 'settings_reduce_motion'.tr(),
              subtitle: 'settings_reduce_motion_desc'.tr(),
              value: reduceMotion,
              onChanged: (v) => ref.read(reduceMotionProvider.notifier).setEnabled(v),
            ),
            _Divider(),
            _TextScaleTile(
              value: textScale,
              onChanged: (v) => ref.read(textScaleProvider.notifier).setScale(v),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _GroupLabel(icon: HugeIcons.strokeRoundedMessage02, title: 'settings_general_group_messages'.tr()),
        _SettingsCard(
          children: [
            // 发送快捷键依赖实体键盘的 Ctrl/Enter，手机/平板（触屏、无实体键盘）
            // 直接隐藏，与桌面端保持区分；按布局宽度判定，Web 窄窗口同样隐藏。
            if (DeviceUtil.isDesktop(context)) ...[
              _SegmentTile<ChatSendShortcut>(
                icon: HugeIcons.strokeRoundedKeyboard,
                title: 'settings_chat_send_key'.tr(),
                subtitle: 'settings_chat_send_key_desc'.tr(),
                value: sendShortcut,
                options: const [
                  SegmentOption(value: ChatSendShortcut.enter, labelKey: 'settings_chat_send_key_enter'),
                  SegmentOption(value: ChatSendShortcut.ctrlEnter, labelKey: 'settings_chat_send_key_ctrl_enter'),
                ],
                onChanged: (v) => ref.read(chatSendShortcutProvider.notifier).setShortcut(v),
              ),
              _Divider(),
            ],
            _SwitchTile(
              icon: HugeIcons.strokeRoundedNotification01,
              title: 'settings_message_preview'.tr(),
              subtitle: 'settings_message_preview_desc'.tr(),
              value: messagePreview,
              onChanged: (v) => ref.read(messagePreviewProvider.notifier).setEnabled(v),
            ),
            _Divider(),
            _SwitchTile(
              icon: HugeIcons.strokeRoundedPlay,
              title: 'settings_auto_play_media'.tr(),
              subtitle: 'settings_auto_play_media_desc'.tr(),
              value: autoPlay,
              onChanged: (v) => ref.read(autoPlayMediaProvider.notifier).setEnabled(v),
            ),
          ],
        ),
        const SizedBox(height: 18),
        // 应用更新（Web 端无安装包概念；iOS 走应用商店，均不展示）
        if (!DeviceUtil.isRealWeb() && !DeviceUtil.isIOS()) ...[
          _GroupLabel(icon: HugeIcons.strokeRoundedDownload04, title: 'settings_general_group_update'.tr()),
          _SettingsCard(
            children: [
              _SwitchTile(
                icon: HugeIcons.strokeRoundedCloudSavingDone01,
                title: 'settings_auto_download_update'.tr(),
                subtitle: 'settings_auto_download_update_desc'.tr(),
                value: autoDownloadUpdate,
                onChanged: (v) => ref
                    .read(autoDownloadUpdateProvider.notifier)
                    .setEnabled(v),
              ),
              // 移动流量开关仅移动端有意义（桌面端无计费流量概念）
              if (DeviceUtil.isRealMobile()) ...[
                _Divider(),
                _SwitchTile(
                  icon: HugeIcons.strokeRoundedSmartPhone01,
                  title: 'settings_cellular_download_update'.tr(),
                  subtitle: 'settings_cellular_download_update_desc'.tr(),
                  value: updateCellularDownload,
                  enabled: autoDownloadUpdate,
                  onChanged: (v) => ref
                      .read(updateCellularDownloadProvider.notifier)
                      .setEnabled(v),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: 18),
        _GroupLabel(icon: HugeIcons.strokeRoundedDatabase, title: 'settings_general_group_storage'.tr()),
        _SettingsCard(
          children: [
            _SwitchTile(
              icon: HugeIcons.strokeRoundedMegaphone01,
              title: 'settings_show_official_room'.tr(),
              subtitle: 'settings_show_official_room_desc'.tr(),
              value: visible,
              onChanged: (value) => _setVisible(ref, value),
              onTapOverride: () => _setVisible(ref, !visible),
            ),
          ],
        ),
        if (showStartupGroup) ...[
          const SizedBox(height: 18),
          _GroupLabel(
            icon: HugeIcons.strokeRoundedComputer,
            title: 'settings_general_group_startup'.tr(),
          ),
          _SettingsCard(
            children: [
              _SwitchTile(
                icon: HugeIcons.strokeRoundedPower,
                title: 'settings_launch_at_startup'.tr(),
                subtitle: startupSupported
                    ? 'settings_launch_at_startup_desc'.tr()
                    : 'settings_launch_at_startup_unsupported'.tr(),
                value: launchAtStartup && startupSupported,
                enabled: startupSupported,
                onChanged: (v) => ref
                    .read(launchAtStartupProvider.notifier)
                    .setEnabled(v),
              ),
              _Divider(),
              _SwitchTile(
                icon: HugeIcons.strokeRoundedViewOff,
                title: 'settings_launch_silent'.tr(),
                subtitle: 'settings_launch_silent_desc'.tr(),
                value: launchSilent,
                enabled: startupSupported && launchAtStartup,
                onChanged: (v) => ref
                    .read(launchAtStartupSilentProvider.notifier)
                    .setEnabled(v),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _setVisible(WidgetRef ref, bool visible) {
    if (!visible && ref.read(activeRoomIdProvider) == OfficialRoomConfig.virtualRoomId) {
      ref.read(activeRoomIdProvider.notifier).setActive(null);
      ref.read(chatRightPanelVisibleProvider.notifier).state = false;
    }
    ref.read(hideOfficialRoomProvider.notifier).setHidden(!visible);
  }
}

class _GroupLabel extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String title;
  const _GroupLabel({required this.icon, required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          HugeIcon(icon: icon, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusToken.lg)),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35));
  }
}

class _SwitchTile extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onTapOverride;
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.onTapOverride,
  });
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: HugeIcon(icon: icon, size: 22),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
      trailing: Transform.scale(
        scale: 0.85,
        child: Switch.adaptive(value: value, onChanged: enabled ? onChanged : null),
      ),
      // 禁用态整体降透明度，与开关的灰化保持视觉一致
      textColor: enabled ? null : scheme.onSurface.withValues(alpha: 0.45),
      enabled: enabled,
      onTap: enabled ? (onTapOverride ?? () => onChanged?.call(!value)) : null,
    );
  }
}

class SegmentOption<T> {
  final T value;
  final String labelKey;
  const SegmentOption({required this.value, required this.labelKey});
}

class _SegmentTile<T> extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final T value;
  final List<SegmentOption<T>> options;
  final ValueChanged<T> onChanged;
  const _SegmentTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(icon: icon, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SegmentedButton<T>(
            segments: [
              for (final o in options) ButtonSegment<T>(value: o.value, label: Text(o.labelKey.tr())),
            ],
            selected: {value},
            onSelectionChanged: (s) => onChanged(s.first),
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RadiusToken.lg),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextScaleTile extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const _TextScaleTile({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labels = {
      0.9: 'settings_text_scale_small',
      1.0: 'settings_text_scale_default',
      1.1: 'settings_text_scale_large',
      1.2: 'settings_text_scale_xlarge',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HugeIcon(icon: HugeIcons.strokeRoundedTextFont, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('settings_text_scale'.tr(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('settings_text_scale_desc'.tr(), style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(RadiusToken.pill),
                ),
                child: Text(labels[value]?.tr() ?? '${(value * 100).round()}%', style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Slider(
            value: value,
            min: 0.9,
            max: 1.2,
            divisions: 3,
            label: labels[value]?.tr(),
            onChanged: onChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final v in [0.9, 1.0, 1.1, 1.2])
                Text(labels[v]!.tr(), style: Theme.of(context).textTheme.labelSmall!.copyWith( color: v == value ? scheme.primary : scheme.onSurfaceVariant, fontWeight: v == value ? FontWeight.w700 : FontWeight.w400)),
            ],
          ),
        ],
      ),
    );
  }
}
