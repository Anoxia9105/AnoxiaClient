import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/features/settings/application/settings_page_controller.dart';
import 'package:anoxia/framework/provider/setting/settings_provider.dart';
import 'package:anoxia/gen/assets.gen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// 作者联系方式与对外链接。
const String _authorEmail = 'zhangj9105@gmail.com';
const String _authorGithubUrl = 'https://github.com/crazydavet';
const String _sponsorUrl = 'https://www.anoxia.cn/sponsor.html';
const String _privacyPolicyUrl = 'https://www.anoxia.cn/privacy.html';
const String _termsUrl = 'https://www.anoxia.cn/terms.html';
const String _appShareUrl = 'https://www.anoxia.cn';

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
        _AppOverviewCard(
          version: widget.appVersionText,
          onVersionTap: _handleVersionTap,
        ),
        // Web 端通过浏览器刷新即可获取最新版本，不提供检查更新入口。
        if (!DeviceUtil.isWeb) ...[
          const SizedBox(height: 16),
          _UpdateCard(
            updateInfo: updateInfo,
            checkingUpdate: widget.pageState.checkingUpdate,
            hasAppUpdate: widget.hasAppUpdate,
            onCheckUpdate: widget.onCheckUpdate,
          ),
          if (widget.pageState.updateErrorKey != null) ...[
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(
                widget.pageState.updateErrorKey!.tr(),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
              ),
            ),
          ],
          if (updateInfo?.hasUpdate == true &&
              updateInfo?.downloadUrl.isNotEmpty == true) ...[
            const SizedBox(height: 10),
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
        const SizedBox(height: 24),
        _SectionLabel(text: 'settings_about_contact_title'.tr()),
        const SizedBox(height: 8),
        _ActionGroup(
          key: const Key('about-contact-group'),
          children: [
            _ActionRow(
              icon: HugeIcons.strokeRoundedMail01,
              title: 'settings_about_email'.tr(),
              subtitle: _authorEmail,
              onTap: () => _launchEmail(context),
            ),
            _ActionRow(
              icon: HugeIcons.strokeRoundedGithub,
              title: 'settings_about_github'.tr(),
              subtitle: _authorGithubUrl,
              onTap: () => _launchUrl(context, _authorGithubUrl),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SectionLabel(text: 'settings_about_more_title'.tr()),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final useColumns = constraints.maxWidth >= 600;
            final actions = [
              _SupportShortcut(
                key: const Key('about-sponsor-action'),
                icon: HugeIcons.strokeRoundedHeartCheck,
                title: 'settings_about_sponsor'.tr(),
                subtitle: 'settings_about_sponsor_subtitle'.tr(),
                onTap: () => _launchUrl(context, _sponsorUrl),
              ),
              _SupportShortcut(
                key: const Key('about-share-action'),
                icon: HugeIcons.strokeRoundedShare01,
                title: 'settings_about_share'.tr(),
                subtitle: 'settings_about_share_subtitle'.tr(),
                onTap: () => _shareApp(context),
              ),
            ];
            if (!useColumns) {
              return Column(
                children: [
                  actions.first,
                  const SizedBox(height: 10),
                  actions.last,
                ],
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: actions.first),
                  const SizedBox(width: 12),
                  Expanded(child: actions.last),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _ActionGroup(
          key: const Key('about-resource-group'),
          children: [
            _ActionRow(
              icon: HugeIcons.strokeRoundedLock,
              title: 'settings_about_privacy_policy'.tr(),
              subtitle: 'settings_about_privacy_policy_subtitle'.tr(),
              onTap: () => _launchUrl(context, _privacyPolicyUrl),
            ),
            _ActionRow(
              icon: HugeIcons.strokeRoundedLegal01,
              title: 'settings_about_terms'.tr(),
              subtitle: 'settings_about_terms_subtitle'.tr(),
              onTap: () => _launchUrl(context, _termsUrl),
            ),
            _ActionRow(
              icon: HugeIcons.strokeRoundedCode,
              title: 'settings_open_source_title'.tr(),
              subtitle: 'settings_about_open_source_subtitle'.tr(),
              onTap: widget.onOpenOpenSourceLicenses,
            ),
          ],
        ),
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
          Toast.showToast(
            'settings_about_link_failed'.tr(),
            type: ToastType.error,
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        Toast.showToast(
          'settings_about_link_failed'.tr(),
          type: ToastType.error,
        );
      }
    }
  }

  /// 发送邮件给作者。
  Future<void> _launchEmail(BuildContext context) async {
    final uri = Uri(scheme: 'mailto', path: _authorEmail);
    try {
      if (!await launchUrl(uri)) {
        if (context.mounted) {
          Toast.showToast(
            'settings_about_link_failed'.tr(),
            type: ToastType.error,
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        Toast.showToast(
          'settings_about_link_failed'.tr(),
          type: ToastType.error,
        );
      }
    }
  }

  /// 分享应用。
  Future<void> _shareApp(BuildContext context) async {
    try {
      await SharePlus.instance.share(
        ShareParams(title: 'Anoxia IM Client', text: _appShareUrl),
      );
    } catch (_) {
      if (context.mounted) {
        Toast.showToast(
          'settings_about_share_failed'.tr(),
          type: ToastType.error,
        );
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

/// 应用概览卡片，集中展示品牌、版本、简介与产品特性。
class _AppOverviewCard extends StatelessWidget {
  final String version;
  final VoidCallback onVersionTap;

  const _AppOverviewCard({required this.version, required this.onVersionTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      key: const Key('about-overview-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                child: Assets.images.appLogo.image(
                  filterQuality: FilterQuality.high,
                  semanticLabel: 'Anoxia IM Client',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Anoxia IM Client',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          key: const Key('about-version-button'),
                          canRequestFocus: true,
                          borderRadius: BorderRadius.circular(8),
                          onTap: onVersionTap,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 44),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Center(
                                child: Text(
                                  '${'settings_app_version'.tr()} $version',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: colorScheme.primary.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 16),
          Text(
            'settings_about_description'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, size: 15, color: colorScheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              softWrap: true,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
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
class _ActionGroup extends StatelessWidget {
  final List<_ActionRow> children;

  const _ActionGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: Column(
        children: [
          for (var index = 0; index < children.length; index += 1) ...[
            children[index],
            if (index < children.length - 1)
              Divider(
                height: 1,
                indent: 62,
                color: colorScheme.outlineVariant.withValues(alpha: 0.55),
              ),
          ],
        ],
      ),
    );
  }
}

/// 强调支持类操作，在宽屏下可与同级操作并排显示。
class _SupportShortcut extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SupportShortcut({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.secondaryContainer.withValues(alpha: 0.34),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.secondary.withValues(alpha: 0.18)),
      ),
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 96),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconSurface(icon: icon, emphasized: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowUpRight01,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
      mouseCursor: SystemMouseCursors.click,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 68),
        child: Row(
          children: [
            const SizedBox(width: 12),
            _IconSurface(icon: icon),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
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
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }
}

class _IconSurface extends StatelessWidget {
  final List<List<dynamic>> icon;
  final bool emphasized;

  const _IconSurface({required this.icon, this.emphasized = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: emphasized
            ? colorScheme.secondaryContainer
            : colorScheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: HugeIcon(
        icon: icon,
        size: 20,
        color: emphasized
            ? colorScheme.onSecondaryContainer
            : colorScheme.primary,
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

    return Semantics(
      button: true,
      enabled: !checkingUpdate,
      child: Material(
        color: hasAppUpdate
            ? colorScheme.tertiaryContainer.withValues(alpha: 0.32)
            : colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: hasAppUpdate
                ? colorScheme.tertiary.withValues(alpha: 0.22)
                : colorScheme.outlineVariant.withValues(alpha: 0.72),
          ),
        ),
        child: InkWell(
          mouseCursor: checkingUpdate
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          onTap: checkingUpdate ? null : onCheckUpdate,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  _IconSurface(
                    icon: hasAppUpdate
                        ? HugeIcons.strokeRoundedUpload03
                        : HugeIcons.strokeRoundedCloudSavingDone01,
                    emphasized: hasAppUpdate,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _UpdateCopy(updateInfo: updateInfo)),
                  if (checkingUpdate)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        semanticsLabel: 'settings_update_checking'.tr(),
                      ),
                    )
                  else
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
          ),
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
    final statusColor = hasUpdate
        ? colorScheme.onTertiaryContainer
        : colorScheme.onSurface;

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
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (hasUpdate) ...[
              const SizedBox(width: 8),
              Semantics(
                label: 'update_new_version'.tr(),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: colorScheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
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
