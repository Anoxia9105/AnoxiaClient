import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/adaptive_page_presenter.dart';
import 'package:anoxia/common/widgets/desktop/connection_status_tag.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/features/chat/presentation/pages/scan_qr_page.dart';
import 'package:anoxia/features/chat/presentation/widgets/create_chat_dialog_widget.dart';
import 'package:anoxia/features/chat/presentation/widgets/official_room_sections.dart';
import 'package:anoxia/features/contact/presentation/pages/add_friend_page.dart';
import 'package:anoxia/features/settings/application/settings_page_controller.dart';
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

const String _officialHomePageUrl = 'https://www.anoxia.cn';

/// 官方虚拟房间内容页。
///
/// 纯前端富内容帮助页：紧凑 Hero + 分段 Tab（功能 / 上手 / 帮助）。
/// Tab 内为可滚动内容，一屏内切换分区，避免整页长列表下滑。
/// 入场与分区切换采用一次性错峰淡入动画，性能可控。
class OfficialRoomHomeView extends ConsumerStatefulWidget {
  const OfficialRoomHomeView({super.key});

  @override
  ConsumerState<OfficialRoomHomeView> createState() =>
      _OfficialRoomHomeViewState();
}

class _OfficialRoomHomeViewState extends ConsumerState<OfficialRoomHomeView>
    with SingleTickerProviderStateMixin {
  bool _updateDismissed = false;

  late final AnimationController _entranceController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 页面整体一次性入场动画（fade + 轻微上移 + 品牌缩放），播放一次即止。
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    )..forward();
    final curved = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _fade = curved;
    _slide = Tween(begin: const Offset(0, 0.035), end: Offset.zero).animate(
      curved,
    );
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _entranceController.dispose();
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

  Future<void> _shareApp() async {
    try {
      await SharePlus.instance.share(
        ShareParams(title: 'Anoxia IM Client', text: _officialHomePageUrl),
      );
    } catch (_) {
      if (!mounted) return;
      Toast.showToast('official_room_link_failed'.tr(), type: ToastType.error);
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
        final horizontalPadding = compact ? 14.0 : 20.0;

        return SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          compact ? 12 : 16,
                          horizontalPadding,
                          0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ScaleTransition(
                              scale: Tween(begin: 0.96, end: 1.0).animate(
                                _entranceController,
                              ),
                              child: _WelcomeHeader(
                                compact: compact,
                                version: version,
                                hasUpdate: hasUpdate,
                              ),
                            ),
                            if (hasUpdate && !_updateDismissed) ...[
                              const SizedBox(height: 10),
                              _UpdateBanner(
                                latestVersion: updateInfo.latestVersion,
                                onCheck: _checkUpdate,
                                onDismiss: () =>
                                    setState(() => _updateDismissed = true),
                              ),
                            ],
                            Padding(
                              padding: EdgeInsets.only(top: compact ? 10 : 14),
                              child: _HomeTabBar(controller: _tabController),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _FeatureTab(actions: _buildActions(context)),
                            const _OnboardingTab(),
                            const _HelpTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 分段 Tab 栏：胶囊分段控件，选中态着色，未选中透明。
class _HomeTabBar extends StatelessWidget {
  const _HomeTabBar({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(RadiusToken.pill),
      ),
      child: TabBar(
        controller: controller,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(RadiusToken.pill),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: colorScheme.onPrimaryContainer,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        tabs: [
          Tab(text: 'official_room_chips_overview'.tr()),
          Tab(text: 'official_room_onboarding_title'.tr()),
          Tab(text: 'official_room_faq_title'.tr()),
        ],
      ),
    );
  }
}

/// 通用 Tab 内容容器：可滚动 + 内边距 + 分区错峰淡入。
class _TabPage extends StatelessWidget {
  const _TabPage({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 18),
            _StaggerItem(index: i, child: children[i]),
          ],
          const _Footer(),
        ],
      ),
    );
  }
}

/// 一次性错峰淡入动画：单项从透明 + 轻微上移浮现。
///
/// 仅首次构建播放一次（TweenAnimationBuilder 单次 tween），无循环、
/// 无持续刷新，性能可控。
class _StaggerItem extends StatelessWidget {
  const _StaggerItem({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final delay = (index * 70).clamp(0, 350);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + delay),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}

/// 「功能」分区：快速操作 + 功能一览。
class _FeatureTab extends StatelessWidget {
  const _FeatureTab({required this.actions});

  final List<QuickActionData> actions;

  @override
  Widget build(BuildContext context) {
    return _TabPage(
      children: [
        QuickActionsSection(items: actions),
        const FeaturesSection(),
      ],
    );
  }
}

/// 「上手」分区：快速上手指引。
class _OnboardingTab extends StatelessWidget {
  const _OnboardingTab();

  @override
  Widget build(BuildContext context) {
    return const _TabPage(children: [OnboardingSection()]);
  }
}

/// 「帮助」分区：常见问题。
class _HelpTab extends StatelessWidget {
  const _HelpTab();

  @override
  Widget build(BuildContext context) {
    return const _TabPage(children: [FaqSection()]);
  }
}

/// 欢迎 Hero：紧凑品牌横幅 + 状态徽章（连接状态 / 版本 / 更新提示）。
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
    final logoSize = compact ? 48.0 : 56.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(RadiusToken.xl),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: logoSize,
                  height: logoSize,
                  padding: EdgeInsets.all(compact ? 6 : 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(RadiusToken.lg),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Assets.images.appIconPng.image(
                    fit: BoxFit.contain,
                    semanticLabel: 'official_room_name'.tr(),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'official_room_welcome_title'.tr(),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'official_room_welcome_desc'.tr(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          height: 1.45,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(RadiusToken.pill),
          border: Border.all(
            color: (highlighted ? colorScheme.primary : colorScheme.outlineVariant)
                .withValues(alpha: 0.35),
          ),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(icon: icon, size: 13, color: foreground),
              const SizedBox(width: 5),
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
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(RadiusToken.md),
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedSystemUpdate02,
                size: 18,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
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
                  const SizedBox(height: 2),
                  Text(
                    'official_room_update_desc'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: onCheck,
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedRefresh01, size: 15),
              label: Text('official_room_update_check'.tr()),
            ),
            IconButton(
              tooltip: 'official_room_update_dismiss'.tr(),
              onPressed: onDismiss,
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedCancel01,
                size: 16,
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
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Text(
        'official_room_footer_rights'.tr(),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}