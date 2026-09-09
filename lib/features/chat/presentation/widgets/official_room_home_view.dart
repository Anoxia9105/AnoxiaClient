import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/adaptive_page_presenter.dart';
import 'package:anoxia/common/widgets/desktop/connection_status_tag.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/features/chat/presentation/pages/scan_qr_page.dart';
import 'package:anoxia/features/chat/presentation/widgets/create_chat_dialog_widget.dart';
import 'package:anoxia/features/chat/presentation/widgets/official_room_sections.dart';
import 'package:anoxia/features/contact/presentation/pages/add_friend_page.dart';
import 'package:anoxia/features/settings/application/settings_page_controller.dart';
import 'package:anoxia/features/settings/presentation/pages/open_source_licenses_page.dart';
import 'package:anoxia/features/settings/presentation/pages/settings_page.dart';
import 'package:anoxia/features/settings/presentation/widgets/settings_announcement_section.dart';
import 'package:anoxia/framework/provider/router/router.dart';
import 'package:anoxia/framework/provider/setting/settings_provider.dart';
import 'package:anoxia/framework/provider/setting/update_check_provider.dart';
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
/// 纯前端富内容帮助页：欢迎 Hero（状态徽章）+ 更新/公告卡 + 快速操作
/// （按平台裁剪与弹窗/页面自适应）+ 功能一览 + 快速上手 + 常见问题
/// + 小贴士 + 快捷入口。小窗口或窗口尺寸限制时自动降为紧凑排版。
class OfficialRoomHomeView extends ConsumerStatefulWidget {
  const OfficialRoomHomeView({super.key});

  @override
  ConsumerState<OfficialRoomHomeView> createState() =>
      _OfficialRoomHomeViewState();
}

class _OfficialRoomHomeViewState extends ConsumerState<OfficialRoomHomeView> {
  final GlobalKey _quickKey = GlobalKey();
  final GlobalKey _featKey = GlobalKey();
  final GlobalKey _stepsKey = GlobalKey();
  final GlobalKey _faqKey = GlobalKey();
  final GlobalKey _tipsKey = GlobalKey();
  final GlobalKey _navKey = GlobalKey();
  final ScrollController _scroller = ScrollController();

  bool _updateDismissed = false;

  /// 吸顶章节导航高度（与 [_SectionChipsDelegate] 保持一致）。
  bool _compact = false;

  @override
  void dispose() {
    _scroller.dispose();
    super.dispose();
  }

  /// 按平台构建快速操作列表。
  ///
  /// - 扫一扫：原生移动端专属（摄像头扫码），Web / 桌面端不展示；
  /// - 系统公告：桌面端与 Web PC 宽屏展示（走弹窗），移动端不展示；
  /// - 桌面端 / Web PC 下动作统一走 [presentAdaptivePage] 弹窗，移动端走页面路由。
  List<QuickActionData> _buildActions(BuildContext context) {
    final isMobile = DeviceUtil.isMobile(context);
    final nativeMobile = DeviceUtil.isRealMobile();
    return [
      QuickActionData(
        icon: HugeIcons.strokeRoundedUserAdd02,
        titleKey: 'official_room_action_add_friend',
        descKey: 'official_room_action_add_friend_desc',
        onTap: _openAddFriend,
      ),
      QuickActionData(
        icon: HugeIcons.strokeRoundedUserGroup02,
        titleKey: 'official_room_action_create_group',
        descKey: 'official_room_action_create_group_desc',
        onTap: _openCreateGroup,
      ),
      if (nativeMobile)
        QuickActionData(
          icon: HugeIcons.strokeRoundedQrCode01,
          titleKey: 'official_room_action_scan',
          descKey: 'official_room_action_scan_desc',
          onTap: _openScan,
        ),
      if (!isMobile)
        QuickActionData(
          icon: HugeIcons.strokeRoundedMegaphone01,
          titleKey: 'official_room_action_announcement',
          descKey: 'official_room_action_announcement_desc',
          onTap: _openAnnouncements,
        ),
      QuickActionData(
        icon: HugeIcons.strokeRoundedDownload01,
        titleKey: 'official_room_action_update',
        descKey: 'official_room_action_update_desc',
        onTap: _checkUpdate,
      ),
      QuickActionData(
        icon: HugeIcons.strokeRoundedShare01,
        titleKey: 'official_room_action_share',
        descKey: 'official_room_action_share_desc',
        onTap: _shareApp,
      ),
      QuickActionData(
        icon: HugeIcons.strokeRoundedSettings01,
        titleKey: 'official_room_action_settings',
        descKey: 'official_room_action_settings_desc',
        onTap: _openSettings,
      ),
    ];
  }

  List<NavLinkData> _navLinks(BuildContext context) => [
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

  /// 添加好友：桌面端 / Web PC 走弹窗，移动端 / Web SP 走页面跳转。
  void _openAddFriend() => presentAdaptivePage(
    context,
    builder: (_) => const AddFriendPage(),
  );

  /// 发起群聊：桌面端 / Web PC 走弹窗，移动端 / Web SP 走页面跳转。
  void _openCreateGroup() => presentAdaptivePage(
    context,
    builder: (_) => const CreateChatDialogWidget(asPage: true),
  );

  /// 扫一扫：仅原生移动端（摄像头扫码），页面跳转。
  void _openScan() => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const ScanQrPage()));

  /// 系统公告：桌面端 / Web PC 走弹窗，移动端 / Web SP 走页面跳转。
  void _openAnnouncements() => presentAdaptivePage(
    context,
    builder: (_) => const _AnnouncementListPage(),
  );

  /// 设置：桌面端 / Web PC 走弹窗，移动端 / Web SP 走页面跳转。
  void _openSettings() => presentAdaptivePage(
    context,
    builder: (_) => const SettingsPage(),
  );

  /// 开源许可：桌面端 / Web PC 走弹窗，移动端 / Web SP 走页面跳转。
  void _openLicenses() => presentAdaptivePage(
    context,
    builder: (_) => const OpenSourceLicensesPage(),
  );

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

  @override
  Widget build(BuildContext context) {
    final version = ref
        .watch(appVersionProvider)
        .maybeWhen(data: (v) => v, orElse: () => '--');
    final updateInfo = ref.watch(appUpdateCheckerProvider);
    final hasUpdate = updateInfo != null && updateInfo.hasUpdate;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 520 || constraints.maxHeight < 620;
        _compact = compact;
        final horizontalPadding = constraints.maxWidth < 420 ? 16.0 : 24.0;

        return SafeArea(
          child: CustomScrollView(
            controller: _scroller,
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _SectionChipsDelegate(
                  items: [
                    _ChipData('official_room_chips_overview'.tr(), null),
                    _ChipData('official_room_action_title'.tr(), _quickKey),
                    _ChipData('official_room_onboarding_title'.tr(), _stepsKey),
                    _ChipData('official_room_feat_title'.tr(), _featKey),
                    _ChipData('official_room_faq_title'.tr(), _faqKey),
                    _ChipData('official_room_tips_title'.tr(), _tipsKey),
                    _ChipData('official_room_nav_title'.tr(), _navKey),
                  ],
                  onSelected: _scrollTo,
                  compact: compact,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
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
                          _WelcomeHeader(
                            compact: compact,
                            version: version,
                            hasUpdate: hasUpdate,
                          ),
                          SizedBox(height: compact ? 20 : 28),
                          if (hasUpdate && !_updateDismissed) ...[
                            _UpdateBanner(
                              latestVersion: updateInfo.latestVersion,
                              onCheck: _checkUpdate,
                              onDismiss: () => setState(() => _updateDismissed = true),
                            ),
                            SizedBox(height: compact ? 20 : 28),
                          ],
                          SectionAnchor(
                            anchor: _quickKey,
                            child: QuickActionsSection(items: _buildActions(context)),
                          ),
                          SizedBox(height: compact ? 20 : 28),
                          SectionAnchor(
                            anchor: _stepsKey,
                            child: const OnboardingSection(),
                          ),
                          SizedBox(height: compact ? 20 : 28),
                          SectionAnchor(
                            anchor: _featKey,
                            child: const FeaturesSection(),
                          ),
                          SizedBox(height: compact ? 20 : 28),
                          SectionAnchor(
                            anchor: _faqKey,
                            child: const FaqSection(),
                          ),
                          SizedBox(height: compact ? 20 : 28),
                          SectionAnchor(
                            anchor: _tipsKey,
                            child: const TipsSection(),
                          ),
                          SizedBox(height: compact ? 20 : 28),
                          SectionAnchor(
                            anchor: _navKey,
                            child: NavLinksSection(items: _navLinks(context)),
                          ),
                          const SizedBox(height: 20),
                          _Footer(version: version),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _scrollTo(GlobalKey? key) {
    if (key == null) {
      _jumpToTop();
      return;
    }
    final target = key.currentContext;
    if (target == null) return;
    // 吸顶 chips 会遮挡内容顶部：将目标顶部对齐到头部高度之下，
    // 避免跳转后区块标题被 sticky 导航盖住。
    final headerHeight = _compact ? 44.0 : 52.0;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    Scrollable.ensureVisible(
      target,
      alignment: viewportHeight > 0 ? headerHeight / viewportHeight : 0.08,
      duration: const Duration(milliseconds: 320),
    );
  }

  void _jumpToTop() {
    if (!_scroller.hasClients) return;
    _scroller.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }
}

/// 章节锚点包装：将 [anchor] 应用到子树，供 `Scrollable.ensureVisible` 定位。
class SectionAnchor extends StatelessWidget {
  const SectionAnchor({super.key, required this.anchor, required this.child});

  final GlobalKey anchor;
  final Widget child;

  @override
  Widget build(BuildContext context) => KeyedSubtree(key: anchor, child: child);
}

/// 章节横向快捷导航（置顶吸顶）。
class _SectionChips extends StatelessWidget {
  const _SectionChips({
    required this.items,
    required this.onSelected,
  });

  final List<_ChipData> items;
  final ValueChanged<GlobalKey?> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.92),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SizedBox(
        height: double.infinity,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            // 自绘胶囊按钮：主题强调色底 + 项目圆角令牌，不依赖
            // ActionChip 的平台默认样式（深色下会显示近乎全黑）。
            return Material(
              color: colorScheme.primaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(RadiusToken.pill),
              child: InkWell(
                onTap: () => onSelected(item.anchor),
                borderRadius: BorderRadius.circular(RadiusToken.pill),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(RadiusToken.pill),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ChipData {
  const _ChipData(this.label, this.anchor);

  final String label;
  final GlobalKey? anchor;
}

/// 吸顶章节导航的 SliverPersistentHeader 代理。
class _SectionChipsDelegate extends SliverPersistentHeaderDelegate {
  _SectionChipsDelegate({
    required this.items,
    required this.onSelected,
    required this.compact,
  });

  final List<_ChipData> items;
  final ValueChanged<GlobalKey?> onSelected;
  final bool compact;

  double get _height => compact ? 44.0 : 52.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  bool shouldRebuild(covariant _SectionChipsDelegate oldDelegate) =>
      oldDelegate.items.length != items.length ||
      !identical(oldDelegate.onSelected, onSelected) ||
      oldDelegate.compact != compact;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) =>
      _SectionChips(items: items, onSelected: onSelected);
}

/// 欢迎 Hero：品牌标识 + 标题 + 状态徽章（连接状态 / 版本 / 更新提示）。
class _WelcomeHeader extends ConsumerWidget {
  const _WelcomeHeader({
    required this.compact,
    required this.version,
    required this.hasUpdate,
  });

  final bool compact;
  final String version;
  final bool hasUpdate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const ConnectionStatusTag(),
                _StatusChip(
                  text: '${'settings_app_version'.tr()} $version',
                  icon: HugeIcons.strokeRoundedInformationCircle,
                ),
                if (hasUpdate)
                  _StatusChip(
                    text: 'official_room_update_badge'.tr(),
                    icon: HugeIcons.strokeRoundedSystemUpdate02,
                    highlighted: true,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.text,
    required this.icon,
    this.highlighted = false,
  });

  final String text;
  final List<List<dynamic>> icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = highlighted
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerLow;
    final foreground = highlighted
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;
    return Tooltip(
      message: text,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(RadiusToken.pill),
          border: Border.all(
            color: (highlighted ? colorScheme.primary : colorScheme.outlineVariant)
                .withValues(alpha: 0.35),
          ),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(icon: icon, size: 14, color: foreground),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 新版本可用横幅：主 CTA 触发检查更新，右上角可暂不提醒。
class _UpdateBanner extends StatelessWidget {
  const _UpdateBanner({
    required this.latestVersion,
    required this.onCheck,
    required this.onDismiss,
  });

  final String latestVersion;
  final VoidCallback onCheck;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(RadiusToken.xl),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(RadiusToken.lg),
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedSystemUpdate02,
                size: 20,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'official_room_update_title'.tr(args: [latestVersion]),
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'official_room_update_desc'.tr(),
                    style: textTheme.bodySmall?.copyWith(
                      height: 1.4,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: onCheck,
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedRefresh01, size: 16),
              label: Text('official_room_update_check'.tr()),
            ),
            IconButton(
              tooltip: 'official_room_update_dismiss'.tr(),
              onPressed: onDismiss,
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedCancel01,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 系统公告列表页（弹窗 / 页面自适应由 [presentAdaptivePage] 决定）。
class _AnnouncementListPage extends ConsumerWidget {
  const _AnnouncementListPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        centerTitle: false,
        title: Text('announcement_settings_title'.tr()),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SettingsAnnouncementSection(),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
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
