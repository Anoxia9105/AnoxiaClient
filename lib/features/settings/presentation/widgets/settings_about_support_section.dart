import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/features/settings/application/settings_page_controller.dart';
import 'package:anoxia/framework/provider/setting/settings_provider.dart';
import 'package:anoxia/framework/provider/setting/update_check_provider.dart';
import 'package:anoxia/framework/provider/setting/update_download_provider.dart';
import 'package:anoxia/framework/theme/spacing_token.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'settings_about_widgets.dart';

/// 作者联系方式与对外链接。
const String _authorEmail = 'zhangj9105@gmail.com';
const String _officialRepositoryUrl = 'https://github.com/Anoxia9105/AnoxiaClient';
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
class SettingsAboutSupportSection extends ConsumerStatefulWidget {
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
  ConsumerState<SettingsAboutSupportSection> createState() =>
      _SettingsAboutSupportSectionState();
}

/// 关于与支持区块状态
///
/// 管理版本号连续点击计数，触发开发者致敬彩蛋页面。
class _SettingsAboutSupportSectionState
    extends ConsumerState<SettingsAboutSupportSection> {
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
    // 本地手动检查结果优先，缺省时回落到全局后台检查结果：
    // 刚启动已发现新版本但用户尚未手动检查时，卡片同样能展示版本号与下载状态。
    final globalUpdateInfo = ref.watch(appUpdateCheckerProvider);
    final updateInfo = widget.pageState.updateInfo ?? globalUpdateInfo;
    final hasUpdate =
        updateInfo?.hasUpdate == true || widget.hasAppUpdate;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppOverviewCard(
          version: widget.appVersionText,
          onVersionTap: _handleVersionTap,
        ),
        // Web 端通过浏览器刷新即可获取最新版本，不提供检查更新入口。
        if (!DeviceUtil.isWeb) ...[
          const SizedBox(height: SpacingToken.lg),
          UpdateCard(
            updateInfo: updateInfo,
            checkingUpdate: widget.pageState.checkingUpdate,
            hasAppUpdate: hasUpdate,
            onCheckUpdate: widget.onCheckUpdate,
            onOpenDetail: widget.onNavigateToUpdatePage,
          ),
          if (widget.pageState.updateErrorKey != null) ...[
            const SizedBox(height: SpacingToken.sm),
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
          if (hasUpdate &&
              updateInfo != null &&
              updateInfo.downloadUrl.isNotEmpty)
            _UpdateCtaButton(updateInfo: updateInfo),
        ],
        const SizedBox(height: SpacingToken.xl),
        SectionLabel(text: 'settings_about_contact_title'.tr()),
        const SizedBox(height: SpacingToken.sm),
        ActionGroup(
          key: const Key('about-contact-group'),
          children: [
            ActionRow(
              icon: HugeIcons.strokeRoundedMail01,
              title: 'settings_about_email'.tr(),
              subtitle: _authorEmail,
              onTap: () => _launchEmail(context),
            ),
            ActionRow(
              icon: HugeIcons.strokeRoundedGithub,
              title: 'settings_about_github'.tr(),
              subtitle: _officialRepositoryUrl,
              onTap: () => _launchUrl(context, _officialRepositoryUrl),
            ),
          ],
        ),
        const SizedBox(height: SpacingToken.xl),
        SectionLabel(text: 'settings_about_more_title'.tr()),
        const SizedBox(height: SpacingToken.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final useColumns = constraints.maxWidth >= 600;
            final actions = [
              SupportShortcut(
                key: const Key('about-sponsor-action'),
                icon: HugeIcons.strokeRoundedHeartCheck,
                title: 'settings_about_sponsor'.tr(),
                subtitle: 'settings_about_sponsor_subtitle'.tr(),
                onTap: () => _launchUrl(context, _sponsorUrl),
              ),
              SupportShortcut(
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
                  const SizedBox(width: SpacingToken.md),
                  Expanded(child: actions.last),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: SpacingToken.md),
        ActionGroup(
          key: const Key('about-resource-group'),
          children: [
            ActionRow(
              icon: HugeIcons.strokeRoundedLock,
              title: 'settings_about_privacy_policy'.tr(),
              subtitle: 'settings_about_privacy_policy_subtitle'.tr(),
              onTap: () => _launchUrl(context, _privacyPolicyUrl),
            ),
            ActionRow(
              icon: HugeIcons.strokeRoundedLegal01,
              title: 'settings_about_terms'.tr(),
              subtitle: 'settings_about_terms_subtitle'.tr(),
              onTap: () => _launchUrl(context, _termsUrl),
            ),
            ActionRow(
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

/// 更新 CTA 按钮：按静默下载状态切换文案与行为
///
/// - 下载中：显示百分比，点击进入详情页查看完整进度；
/// - 已就绪：显示「立即安装」，直接拉起安装器（失败则 Toast + 进入详情页兜底）；
/// - 失败：显示「重试下载」，重新触发下载；
/// - 空闲：显示「立即升级」，进入详情页。
class _UpdateCtaButton extends ConsumerWidget {
  final AppUpdateInfo updateInfo;

  const _UpdateCtaButton({required this.updateInfo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final download = ref.watch(updateDownloadControllerProvider);
    final matchesVersion =
        download.version.isNotEmpty &&
        download.version == updateInfo.latestVersion;

    if (matchesVersion &&
        download.phase == UpdateDownloadPhase.downloading) {
      final percent = (download.progress * 100).clamp(0, 100).toInt();
      return _CtaContainer(
        child: FilledButton.icon(
          onPressed: () => _openDetail(context),
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedDownload01,
            size: 18,
          ),
          label: Text('${'update_downloading'.tr()} $percent%'),
        ),
      );
    }

    if (matchesVersion && download.phase == UpdateDownloadPhase.ready) {
      return _CtaContainer(
        child: FilledButton.icon(
          onPressed: () => _installNow(context, ref),
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedRocket,
            size: 18,
          ),
          label: Text('update_install_now'.tr()),
        ),
      );
    }

    if (matchesVersion && download.phase == UpdateDownloadPhase.failed) {
      return _CtaContainer(
        child: FilledButton.icon(
          onPressed: () => ref
              .read(updateDownloadControllerProvider.notifier)
              .startDownload(updateInfo),
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedRefresh01,
            size: 18,
          ),
          label: Text('update_retry_download'.tr()),
        ),
      );
    }

    return _CtaContainer(
      child: FilledButton.icon(
        onPressed: () => _openDetail(context),
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedDownload01,
          size: 18,
        ),
        label: Text('update_now'.tr()),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    // 通过祖先 State 的回调进入详情页：沿用 UpdateCard 的 onOpenDetail 语义，
    // 这里直接在 context 中向上查找并调用，避免额外传参。
    final state = context.findAncestorStateOfType<
        _SettingsAboutSupportSectionState>();
    state?.widget.onNavigateToUpdatePage(updateInfo);
  }

  Future<void> _installNow(BuildContext context, WidgetRef ref) async {
    final ok = await ref
        .read(updateDownloadControllerProvider.notifier)
        .installReadyUpdate();
    if (!ok && context.mounted) {
      Toast.showToast(
        'update_error_open_installer'.tr(),
        type: ToastType.error,
      );
      _openDetail(context);
    }
  }
}

/// CTA 按钮容器：与卡片保持 10px 间距并撑满宽度
class _CtaContainer extends StatelessWidget {
  final Widget child;

  const _CtaContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(width: double.infinity, child: child),
    );
  }
}
