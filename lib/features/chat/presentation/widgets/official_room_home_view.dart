import 'dart:ui' as ui;

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
import 'package:flutter/rendering.dart';
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
  /// 分区锚点：顺序与下方内容列一致，点击胶囊按钮滚动到对应分区。
  static const List<String> _anchorTitleKeys = [
    'official_room_anchor_overview',
    'official_room_action_title',
    'official_room_help_title',
    'official_room_onboarding_title',
    'official_room_faq_title',
    'official_room_nav_title',
  ];

  /// 悬浮胶囊占据的顶部高度：滚动定位时预留，避免分区标题被胶囊遮挡。
  static const double _anchorRevealGap = 76;

  late final ScrollController _scrollController;
  late final List<GlobalKey> _sectionKeys;
  int _selectedAnchor = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _sectionKeys = [for (var i = 0; i < _anchorTitleKeys.length; i++) GlobalKey()];
    _scrollController.addListener(_syncAnchorWithScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_syncAnchorWithScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 点击胶囊按钮：平滑滚动到对应分区顶部（预留胶囊高度）。
  Future<void> _scrollToSection(int index) async {
    setState(() => _selectedAnchor = index);
    final box =
        _sectionKeys[index].currentContext?.findRenderObject();
    if (box is! RenderBox || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    final target = RenderAbstractViewport.of(
      box,
    ).getOffsetToReveal(box, 0.0).offset;
    final clamped = (target - _anchorRevealGap).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((position.pixels - clamped).abs() < 1) return;
    await _scrollController.animateTo(
      clamped,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
    );
  }

  /// 滚动联动：根据各分区顶部位置高亮当前锚点。
  void _syncAnchorWithScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (!position.hasContentDimensions) return;
    final threshold = position.pixels + _anchorRevealGap + 8;
    var current = 0;
    for (var i = 0; i < _sectionKeys.length; i++) {
      final box = _sectionKeys[i].currentContext?.findRenderObject();
      if (box is! RenderBox) continue;
      final top = RenderAbstractViewport.of(
        box,
      ).getOffsetToReveal(box, 0.0).offset;
      if (top <= threshold) current = i;
    }
    if (current != _selectedAnchor && mounted) {
      setState(() => _selectedAnchor = current);
    }
  }

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
          child: Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
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
                        // 给悬浮胶囊预留顶部空间，避免遮挡欢迎头。
                        const SizedBox(height: 60),
                        _WelcomeHeader(
                          key: _sectionKeys[0],
                          compact: compact,
                        ),
                        SizedBox(height: compact ? 20 : 28),
                        QuickActionsSection(
                          key: _sectionKeys[1],
                          onAddFriend: _openAddFriend,
                          onCreateGroup: _openCreateGroup,
                          onCheckUpdate: _checkUpdate,
                          onOpenSettings: _openSettings,
                        ),
                        SizedBox(height: compact ? 20 : 28),
                        OfficialRoomHelpPanel(
                          key: _sectionKeys[2],
                          showTitle: false,
                        ),
                        SizedBox(height: compact ? 20 : 28),
                        OnboardingSection(key: _sectionKeys[3]),
                        SizedBox(height: compact ? 20 : 28),
                        FaqSection(key: _sectionKeys[4]),
                        SizedBox(height: compact ? 20 : 24),
                        NavLinksSection(
                          key: _sectionKeys[5],
                          items: _navLinks,
                        ),
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
              // 顶部悬浮胶囊锚点导航：毛玻璃 + 主题色-scroll to section。
              Positioned(
                top: 12,
                left: horizontalPadding,
                right: horizontalPadding,
                child: Center(
                  child: _AnchorCapsule(
                    labels: [
                      for (final key in _anchorTitleKeys) key.tr(),
                    ],
                    selected: _selectedAnchor,
                    onTap: _scrollToSection,
                  ),
                ),
              ),
            ],
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

/// 顶部悬浮胶囊锚点导航。
///
/// 毛玻璃容器 + 阴影，悬浮于内容之上；背景/文字/选中态全部取主题色，
/// 随亮暗主题与强调色自动适配。点击按钮滚动到对应分区。
class _AnchorCapsule extends StatelessWidget {
  const _AnchorCapsule({
    required this.labels,
    required this.selected,
    required this.onTap,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(RadiusToken.pill),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(RadiusToken.pill),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.12),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 3),
                spreadRadius: -2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            key: const ValueKey('official_anchor_scroll'),
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < labels.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      right: i == labels.length - 1 ? 0 : 4,
                    ),
                    child: _AnchorPill(
                      label: labels[i],
                      selected: i == selected,
                      onTap: () => onTap(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnchorPill extends StatelessWidget {
  const _AnchorPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadiusToken.pill),
        splashColor: colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: colorScheme.primary.withValues(alpha: 0.06),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: selected
              ? BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(RadiusToken.pill),
                )
              : null,
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({super.key, required this.compact});

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
