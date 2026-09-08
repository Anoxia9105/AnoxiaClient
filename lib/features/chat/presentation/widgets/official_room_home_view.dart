import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/features/chat/presentation/widgets/create_chat_dialog_widget.dart';
import 'package:anoxia/features/chat/presentation/widgets/room_detail_settings/official_room_help_panel.dart';
import 'package:anoxia/features/chat/presentation/widgets/official_room_sections.dart';
import 'package:anoxia/features/contact/presentation/pages/add_friend_page.dart';
import 'package:anoxia/features/settings/presentation/pages/open_source_licenses_page.dart';
import 'package:anoxia/features/settings/presentation/pages/settings_page.dart';
import 'package:anoxia/features/settings/application/settings_page_controller.dart';
import 'package:anoxia/framework/provider/router/router.dart';
import 'package:anoxia/framework/provider/setting/settings_provider.dart';
import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:anoxia/gen/assets.gen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

const String _officialHomePageUrl = 'https://www.anoxia.cn';
const String _privacyPolicyUrl = 'https://www.anoxia.cn/privacy.html';
const String _termsUrl = 'https://www.anoxia.cn/terms.html';
const String _githubUrl = 'https://github.com/crazydavet';

/// 官方虚拟房间内容页。
///
/// 纯前端富内容帮助页：欢迎 Hero + 快速操作 + 功能引导 + 新手指引 + 常见问题 + 快捷导航。
/// 所有内容直接展示，不渲染消息流与输入框；小窗口或窗口尺寸限制时允许纵向滚动。
class OfficialRoomHomeView extends ConsumerStatefulWidget {
  const OfficialRoomHomeView({super.key});

  @override
  ConsumerState<OfficialRoomHomeView> createState() =>
      _OfficialRoomHomeViewState();
}

class _OfficialRoomHomeViewState extends ConsumerState<OfficialRoomHomeView> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final version = ref
        .watch(appVersionProvider)
        .maybeWhen(data: (v) => v, orElse: () => '--');

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 520 || constraints.maxHeight < 620;
        final horizontalPadding = constraints.maxWidth < 420 ? 16.0 : 24.0;

        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              compact ? 16 : 24,
              horizontalPadding,
              compact ? 16 : 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _WelcomeHeader(compact: compact),
                    SizedBox(height: compact ? 20 : 28),
                    QuickActionsSection(
                      onAddFriend: _openAddFriend,
                      onCreateGroup: _openCreateGroup,
                      onCheckUpdate: _checkUpdate,
                      onOpenSettings: _openSettings,
                    ),
                    SizedBox(height: compact ? 20 : 28),
                    const OfficialRoomHelpPanel(showTitle: false),
                    SizedBox(height: compact ? 20 : 28),
                    const OnboardingSection(),
                    SizedBox(height: compact ? 20 : 28),
                    const FaqSection(),
                    SizedBox(height: compact ? 20 : 24),
                    NavLinksSection(items: _navLinks),
                    const SizedBox(height: 20),
                    _Footer(
                      version: version,
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<NavLinkData> get _navLinks => [
    NavLinkData(
      icon: HugeIcons.strokeRoundedSettings01,
      title: 'official_room_nav_settings'.tr(),
      description: 'official_room_nav_settings_desc'.tr(),
      onTap: _openSettings,
    ),
    NavLinkData(
      icon: HugeIcons.strokeRoundedCode,
      title: 'official_room_nav_licenses'.tr(),
      description: 'official_room_nav_licenses_desc'.tr(),
      onTap: _openLicenses,
    ),
    NavLinkData(
      icon: HugeIcons.strokeRoundedLock,
      title: 'official_room_nav_privacy'.tr(),
      description: 'official_room_nav_privacy_desc'.tr(),
      onTap: () => _launchUrl(_privacyPolicyUrl),
    ),
    NavLinkData(
      icon: HugeIcons.strokeRoundedLegal01,
      title: 'official_room_nav_terms'.tr(),
      description: 'official_room_nav_terms_desc'.tr(),
      onTap: () => _launchUrl(_termsUrl),
    ),
    NavLinkData(
      icon: HugeIcons.strokeRoundedShare01,
      title: 'official_room_nav_share'.tr(),
      description: 'official_room_nav_share_desc'.tr(),
      onTap: _shareApp,
    ),
    NavLinkData(
      icon: HugeIcons.strokeRoundedGithub,
      title: 'official_room_nav_github'.tr(),
      description: 'official_room_nav_github_desc'.tr(),
      onTap: () => _launchUrl(_githubUrl),
    ),
  ];

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  void _openAddFriend() => _push(const AddFriendPage());

  void _openCreateGroup() => _push(const CreateChatDialogWidget(asPage: true));

  void _openSettings() => _push(const SettingsPage());

  void _openLicenses() => _push(const OpenSourceLicensesPage());

  Future<void> _checkUpdate() async {
    final result = await ref
        .read(settingsPageControllerProvider.notifier)
        .checkUpdate();
    if (!mounted) return;
    final info = ref.read(settingsPageControllerProvider).updateInfo;
    if (info != null && info.hasUpdate && info.downloadUrl.isNotEmpty) {
      UpdateRoute(
        hasUpdate: info.hasUpdate,
        latestVersion: info.latestVersion,
        downloadUrl: info.downloadUrl,
        releaseNotes: info.releaseNotes,
        forceUpdate: info.forceUpdate,
        minSupportVersion: info.minSupportVersion,
      ).push(context);
    } else {
      Toast.showToast(
        (result.messageKey ?? 'settings_update_no_update').tr(),
        type: result.status == SettingsActionStatus.error
            ? ToastType.error
            : ToastType.info,
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        _toastFailure();
      }
    } catch (_) {
      _toastFailure();
    }
  }

  void _toastFailure() {
    if (!mounted) return;
    Toast.showToast('official_room_link_failed'.tr(), type: ToastType.error);
  }

  Future<void> _shareApp() async {
    try {
      await SharePlus.instance.share(
        ShareParams(title: 'Anoxia IM Client', text: _officialHomePageUrl),
      );
    } catch (_) {
      _toastFailure();
    }
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final logoSize = compact ? 62.0 : 76.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(RadiusToken.xl),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: logoSize,
              height: logoSize,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(RadiusToken.xl),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Assets.images.appIconPng.image(
                fit: BoxFit.contain,
                semanticLabel: 'official_room_name'.tr(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'official_room_welcome_title'.tr(),
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'official_room_welcome_desc'.tr(),
                    style: textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.version,
    required this.colorScheme,
    required this.textTheme,
  });

  final String version;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(
            '${'official_room_footer_version'.tr()} $version',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'official_room_footer_rights'.tr(),
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
