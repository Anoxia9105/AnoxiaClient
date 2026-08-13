import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/common/widgets/vibrating_badge.dart';
import 'package:anoxia/features/settings/application/settings_page_controller.dart';
import 'package:anoxia/framework/provider/setting/settings_provider.dart';
import 'package:anoxia/gen/assets.gen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// 作者联系方式与对外链接占位符。
///
/// 接入真实信息后直接修改下面的常量即可。
const String _authorEmail = 'your-email@example.com';
const String _authorGithubUrl = 'https://github.com/your-name';
const String _sponsorUrl = 'https://github.com/sponsors/your-name';
const String _privacyPolicyUrl = 'https://example.com/privacy';
const String _termsUrl = 'https://example.com/terms';
const String _appShareUrl = 'https://github.com/your-name/anoxia';

/// 设置-关于与支持区块
///
/// 展示应用介绍、功能特性、开源许可证入口和版本更新检查等
/// 关于与支持相关的设置内容。

/// 设置-关于与支持区块组件
///
/// 包含应用介绍、特性标签、开源许可证入口和版本更新检查等功能。
class SettingsAboutSupportSection extends StatefulWidget {
  /// 应用版本号文本
  final String appVersionText;

  /// 是否有应用更新
  final bool hasAppUpdate;

  /// 设置页面状态
  final SettingsPageState pageState;

  /// 检查更新回调
  final VoidCallback onCheckUpdate;

  /// 导航到更新页面回调
  final ValueChanged<AppUpdateInfo> onNavigateToUpdatePage;

  /// 打开开源许可证页面回调
  final VoidCallback onOpenOpenSourceLicenses;

  /// 打开开发者致敬页面回调
  final VoidCallback onOpenDeveloperTribute;

  const SettingsAboutSupportSection({
    super.key,
    required this.appVersionText,
    required this.hasAppUpdate,
    required this.pageState,
    required this.onCheckUpdate,
    required this.onNavigateToUpdatePage,
    required this.onOpenOpenSourceLicenses,
    required this.onOpenDeveloperTribute,
  });

  @override
  State<SettingsAboutSupportSection> createState() =>
      _SettingsAboutSupportSectionState();
}

/// 关于与支持区块状态
///
/// 管理版本号连续点击计数，触发开发者致敬彩蛋页面。
class _SettingsAboutSupportSectionState
    extends State<SettingsAboutSupportSection> {
  /// 版本号点击计数
  int _versionTapCount = 0;

  /// 处理版本号点击
  ///
  /// 连续点击 7 次版本号后触发开发者致敬页面。
  void _handleVersionTap() {
    _versionTapCount += 1;
    if (_versionTapCount < 7) return;
    _versionTapCount = 0;
    widget.onOpenDeveloperTribute();
  }

  @override
  Widget build(BuildContext context) {
    final updateInfo = widget.pageState.updateInfo;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AppIntro(version: widget.appVersionText, onTap: _handleVersionTap),
        const SizedBox(height: 14),
        Text(
          'settings_about_description'.tr(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _InfoPill(
              icon: HugeIcons.strokeRoundedMessageUser01,
              text: 'settings_about_im_focus'.tr(),
            ),
            _InfoPill(
              icon: HugeIcons.strokeRoundedShield01,
              text: 'settings_about_privacy'.tr(),
            ),
            _InfoPill(
              icon: HugeIcons.strokeRoundedRocket01,
              text: 'settings_about_one_person'.tr(),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SectionLabel(text: 'settings_about_contact_title'.tr()),
        const SizedBox(height: 10),
        _ActionRow(
          icon: HugeIcons.strokeRoundedMail01,
          title: 'settings_about_email'.tr(),
          subtitle: _authorEmail,
          onTap: () => _launchEmail(context),
        ),
        const SizedBox(height: 12),
        _ActionRow(
          icon: HugeIcons.strokeRoundedGithub,
          title: 'settings_about_github'.tr(),
          subtitle: _authorGithubUrl,
          onTap: () => _launchUrl(context, _authorGithubUrl),
        ),
        const SizedBox(height: 18),
        _SectionLabel(text: 'settings_about_more_title'.tr()),
        const SizedBox(height: 10),
        _ActionRow(
          icon: HugeIcons.strokeRoundedHeartCheck,
          title: 'settings_about_sponsor'.tr(),
          subtitle: 'settings_about_sponsor_subtitle'.tr(),
          onTap: () => _launchUrl(context, _sponsorUrl),
        ),
        const SizedBox(height: 12),
        _ActionRow(
          icon: HugeIcons.strokeRoundedShare01,
          title: 'settings_about_share'.tr(),
          subtitle: 'settings_about_share_subtitle'.tr(),
          onTap: () => _shareApp(context),
        ),
        const SizedBox(height: 12),
        _ActionRow(
          icon: HugeIcons.strokeRoundedLock,
          title: 'settings_about_privacy_policy'.tr(),
          subtitle: 'settings_about_privacy_policy_subtitle'.tr(),
          onTap: () => _launchUrl(context, _privacyPolicyUrl),
        ),
        const SizedBox(height: 12),
        _ActionRow(
          icon: HugeIcons.strokeRoundedLegal01,
          title: 'settings_about_terms'.tr(),
          subtitle: 'settings_about_terms_subtitle'.tr(),
          onTap: () => _launchUrl(context, _termsUrl),
        ),
        const SizedBox(height: 12),
        _ActionRow(
          icon: HugeIcons.strokeRoundedCode,
          title: 'settings_open_source_title'.tr(),
          subtitle: 'settings_about_open_source_subtitle'.tr(),
          onTap: widget.onOpenOpenSourceLicenses,
        ),
        const SizedBox(height: 12),
        // Web 端通过浏览器刷新即可获取最新版本，不提供检查更新入口
        if (!DeviceUtil.isWeb) ...[
          _UpdateCard(
            updateInfo: updateInfo,
            checkingUpdate: widget.pageState.checkingUpdate,
            hasAppUpdate: widget.hasAppUpdate,
            onCheckUpdate: widget.onCheckUpdate,
          ),
          if (widget.pageState.updateErrorKey != null) ...[
            const SizedBox(height: 10),
            Text(
              widget.pageState.updateErrorKey!.tr(),
              style: TextStyle(color: colorScheme.error, fontSize: 12),
            ),
          ],
          if (updateInfo?.hasUpdate == true &&
              updateInfo?.downloadUrl.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => widget.onNavigateToUpdatePage(updateInfo!),
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedDownload01,
                  size: 18,
                ),
                label: Text('update_now'.tr()),
              ),
            ),
          ],
        ],
      ],
    );
  }

  /// 打开外部链接，失败时提示。
  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          Toast.showToast('settings_about_link_failed'.tr(), type: ToastType.error);
        }
      }
    } catch (_) {
      if (context.mounted) {
        Toast.showToast('settings_about_link_failed'.tr(), type: ToastType.error);
      }
    }
  }

  /// 发送邮件给作者。
  Future<void> _launchEmail(BuildContext context) async {
    final uri = Uri(scheme: 'mailto', path: _authorEmail);
    try {
      if (!await launchUrl(uri)) {
        if (context.mounted) {
          Toast.showToast('settings_about_link_failed'.tr(), type: ToastType.error);
        }
      }
    } catch (_) {
      if (context.mounted) {
        Toast.showToast('settings_about_link_failed'.tr(), type: ToastType.error);
      }
    }
  }

  /// 分享应用。
  Future<void> _shareApp(BuildContext context) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          title: 'Anoxia IM Client',
          text: _appShareUrl,
        ),
      );
    } catch (_) {
      if (context.mounted) {
        Toast.showToast('settings_about_share_failed'.tr(), type: ToastType.error);
      }
    }
  }
}

/// 分区标签组件
///
/// 用于「关于与支持」区块内分组的标签文字。
class _SectionLabel extends StatelessWidget {
  /// 标签文本
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

/// 应用介绍组件
///
/// 显示应用图标、名称和版本号，版本号可点击触发彩蛋。
class _AppIntro extends StatelessWidget {
  /// 版本号
  final String version;

  /// 点击回调
  final VoidCallback onTap;

  const _AppIntro({required this.version, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Assets.images.appLogo.image(
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Anoxia IM Client',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onTap,
                    child: Text(
                      '${'settings_app_version'.tr()} $version',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        decoration: TextDecoration.underline,
                        decorationColor: colorScheme.outline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 信息标签组件
///
/// 带图标的圆角信息标签，用于展示应用功能特性。
class _InfoPill extends StatelessWidget {
  /// 图标
  final List<List<dynamic>> icon;

  /// 标签文本
  final String text;

  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, size: 15, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// 操作行组件
///
/// 带图标、标题、副标题和箭头的可点击操作入口。
class _ActionRow extends StatelessWidget {
  /// 图标
  final List<List<dynamic>> icon;

  /// 标题
  final String title;

  /// 副标题
  final String subtitle;

  /// 点击回调
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      mouseCursor: SystemMouseCursors.click,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            HugeIcon(icon: icon, size: 22, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// 更新卡片组件
///
/// 显示版本更新检查入口，有新版本时显示升级图标和更新信息。
class _UpdateCard extends StatelessWidget {
  /// 更新信息
  final AppUpdateInfo? updateInfo;

  /// 是否正在检查更新
  final bool checkingUpdate;

  /// 是否有应用更新
  final bool hasAppUpdate;

  /// 检查更新回调
  final VoidCallback onCheckUpdate;

  const _UpdateCard({
    required this.updateInfo,
    required this.checkingUpdate,
    required this.hasAppUpdate,
    required this.onCheckUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      mouseCursor: checkingUpdate
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onTap: checkingUpdate ? null : onCheckUpdate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            HugeIcon(
              icon: hasAppUpdate
                  ? HugeIcons.strokeRoundedUpload03
                  : HugeIcons.strokeRoundedCloudSavingDone01,
              size: 22,
              color: hasAppUpdate
                  ? const Color(0xFFFF9800)
                  : colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(child: _UpdateCopy(updateInfo: updateInfo)),
            if (checkingUpdate)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}

/// 更新文案组件
///
/// 根据是否有更新显示不同的版本信息和更新说明。
class _UpdateCopy extends StatelessWidget {
  /// 更新信息
  final AppUpdateInfo? updateInfo;

  const _UpdateCopy({required this.updateInfo});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasUpdate = updateInfo?.hasUpdate == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                hasUpdate
                    ? '${'update_new_version'.tr()}: ${updateInfo!.latestVersion}'
                    : 'settings_update_check'.tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: hasUpdate
                      ? const Color(0xFFFF9800)
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (hasUpdate) ...[
              const SizedBox(width: 8),
              const VibratingBadge(isDot: true),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          updateInfo?.releaseNotes.isNotEmpty == true
              ? updateInfo!.releaseNotes
              : 'update_default_notes'.tr(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
