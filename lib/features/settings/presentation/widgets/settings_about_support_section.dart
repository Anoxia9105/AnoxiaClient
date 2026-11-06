import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/features/settings/application/settings_page_controller.dart';
import 'package:anoxia/framework/provider/setting/settings_provider.dart';
import 'package:anoxia/framework/provider/setting/update_check_provider.dart';
import 'package:anoxia/framework/provider/setting/update_download_provider.dart';
import 'package:anoxia/framework/theme/spacing_token.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'settings_about_widgets.dart';

/// 作者联系方式与对外链接。
const String _authorEmail = 'zhangj9105@gmail.com';
const String _officialRepositoryUrl =
    'https://github.com/Anoxia9105/AnoxiaClient';
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
  final VoidCallback onOpenFeedback;

  const SettingsAboutSupportSection({
    super.key,
    required this.appVersionText,
    required this.hasAppUpdate,
    required this.pageState,
    required this.onCheckUpdate,
    required this.onNavigateToUpdatePage,
    required this.onOpenOpenSourceLicenses,
    required this.onOpenDeveloperTribute,
    required this.onOpenFeedback,
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
    final hasUpdate = updateInfo?.hasUpdate == true || widget.hasAppUpdate;
    final colorScheme = Theme.of(context).colorScheme;

    final download = ref.watch(updateDownloadControllerProvider);
    final matches =
        updateInfo != null &&
        download.version == updateInfo.latestVersion &&
        download.url == updateInfo.downloadUrl;
    final status = widget.pageState.checkingUpdate
        ? 'settings_update_checking'.tr()
        : matches && download.phase == UpdateDownloadPhase.downloading
        ? '${'update_downloading'.tr()} ${(download.progress * 100).toInt()}%'
        : matches && download.phase == UpdateDownloadPhase.paused
        ? 'update_paused'.tr()
        : matches && download.phase == UpdateDownloadPhase.ready
        ? 'update_ready_state'.tr()
        : matches && download.phase == UpdateDownloadPhase.failed
        ? 'update_error_generic_safe'.tr()
        : hasUpdate
        ? 'update_new_version'.tr()
        : updateInfo != null
        ? 'settings_update_no_update'.tr()
        : '';
    return LayoutBuilder(
      builder: (context, box) {
        final compact = box.maxWidth < 600;
        Widget resources(String heading, List<Widget> rows) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              heading,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: SpacingToken.sm),
            ...rows,
          ],
        );
        final contact = resources('about_stay_in_touch'.tr(), [
          AboutResourceRow(
            title: 'GitHub',
            subtitle: 'about_github_hint'.tr(),
            icon: HugeIcons.strokeRoundedGithub,
            onTap: () => _launchUrl(context, _officialRepositoryUrl),
          ),
          AboutResourceRow(
            title: 'settings_about_contact_title'.tr(),
            subtitle: _authorEmail,
            icon: HugeIcons.strokeRoundedMail01,
            copy: true,
            onTap: () async {
              await Clipboard.setData(const ClipboardData(text: _authorEmail));
              if (context.mounted) Toast.showToast('chat_copy_success'.tr());
            },
          ),
          AboutResourceRow(
            title: 'about_website'.tr(),
            subtitle: 'www.anoxia.cn',
            icon: HugeIcons.strokeRoundedGlobe02,
            onTap: () => _launchUrl(context, _appShareUrl),
          ),
        ]);
        final legal = resources('about_app_information'.tr(), [
          AboutResourceRow(
            title: 'settings_about_privacy_policy'.tr(),
            onTap: () => _launchUrl(context, _privacyPolicyUrl),
          ),
          AboutResourceRow(
            title: 'settings_about_terms'.tr(),
            onTap: () => _launchUrl(context, _termsUrl),
          ),
          AboutResourceRow(
            title: 'settings_open_source_title'.tr(),
            onTap: widget.onOpenOpenSourceLicenses,
          ),
        ]);
        final actions = <Widget>[
          AboutQuickAction(
            key: const Key('about-feedback-action'),
            icon: HugeIcons.strokeRoundedMessage02,
            title: 'settings_feedback_title'.tr(),
            subtitle: 'about_feedback_hint'.tr(),
            compact: compact,
            onTap: widget.onOpenFeedback,
          ),
          AboutQuickAction(
            key: const Key('about-sponsor-action'),
            icon: HugeIcons.strokeRoundedHeartCheck,
            title: 'about_support_action'.tr(),
            subtitle: 'about_support_hint'.tr(),
            compact: compact,
            onTap: () => _launchUrl(context, _sponsorUrl),
          ),
          AboutQuickAction(
            key: const Key('about-share-action'),
            icon: HugeIcons.strokeRoundedShare01,
            title: 'about_share_action'.tr(),
            subtitle: 'about_share_hint'.tr(),
            compact: compact,
            onTap: () => _shareApp(context),
          ),
        ];
        return ColoredBox(
          color: colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AboutBrandHeader(),
              AboutVersionRow(
                version: widget.appVersionText,
                status: status,
                checking: widget.pageState.checkingUpdate,
                hasUpdate: hasUpdate,
                onVersionTap: _handleVersionTap,
                onCheck: hasUpdate && updateInfo != null
                    ? () => widget.onNavigateToUpdatePage(updateInfo)
                    : widget.onCheckUpdate,
                progress: matches && download.isBusy ? download.progress : null,
              ),
              if (widget.pageState.updateErrorKey != null) ...[
                const SizedBox(height: SpacingToken.sm),
                Text(
                  widget.pageState.updateErrorKey!.tr(),
                  style: TextStyle(color: colorScheme.error),
                ),
              ],
              const SizedBox(height: SpacingToken.xl),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0)
                        SizedBox(
                          width: compact ? SpacingToken.sm : SpacingToken.lg,
                        ),
                      Expanded(child: actions[i]),
                    ],
                  ],
                ),
              ),
              const AboutAuthorNote(),
              Divider(color: colorScheme.outlineVariant.withValues(alpha: .5)),
              const SizedBox(height: SpacingToken.lg),
              if (compact) ...[
                contact,
                const SizedBox(height: SpacingToken.xl),
                legal,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: contact),
                    const SizedBox(width: SpacingToken.xxl),
                    Expanded(child: legal),
                  ],
                ),
              const SizedBox(height: SpacingToken.xl),
              Row(
                children: [
                  Text('Anoxia', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(width: SpacingToken.lg),
                  Expanded(
                    child: Text(
                      'about_footer'.tr(),
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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

  /// 分享应用。
  Future<void> _shareApp(BuildContext context) async {
    final renderBox = context.findRenderObject() as RenderBox?;
    final origin = renderBox != null && renderBox.hasSize
        ? renderBox.localToGlobal(Offset.zero) & renderBox.size
        : null;
    try {
      await SharePlus.instance.share(
        ShareParams(
          title: 'Anoxia',
          text: _appShareUrl,
          sharePositionOrigin: origin,
        ),
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
