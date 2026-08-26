import 'package:anoxia/common/widgets/adaptive_page_presenter.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/features/settings/application/settings_page_controller.dart';
import 'package:anoxia/features/me/presentation/pages/change_password_page.dart';
import 'package:anoxia/features/me/presentation/pages/me_page.dart';
import 'package:anoxia/features/me/presentation/pages/personal_qr_page.dart';
import 'package:anoxia/features/settings/presentation/pages/account_switch_page.dart';
import 'package:anoxia/features/settings/presentation/pages/developer_tribute_page.dart';
import 'package:anoxia/features/settings/presentation/widgets/settings_account_section.dart';
import 'package:anoxia/features/settings/presentation/widgets/settings_about_support_section.dart';
import 'package:anoxia/features/settings/presentation/widgets/settings_background_section.dart';
import 'package:anoxia/features/settings/presentation/widgets/settings_chat_density_section.dart';
import 'package:anoxia/features/settings/presentation/widgets/settings_feedback_section.dart';
import 'package:anoxia/features/settings/presentation/widgets/settings_general_section.dart';
import 'package:anoxia/features/settings/presentation/widgets/settings_language_section.dart';
import 'package:anoxia/features/settings/presentation/widgets/settings_layout_section.dart';
import 'package:anoxia/features/settings/presentation/widgets/settings_split_view.dart';
import 'package:anoxia/features/settings/presentation/widgets/settings_sticker_section.dart';
import 'package:anoxia/features/settings/presentation/widgets/settings_theme_section.dart';
import 'package:anoxia/features/settings/presentation/widgets/settings_web_notification_section.dart';
import 'package:anoxia/framework/provider/chat/call/call_window_controller.dart';
import 'package:anoxia/framework/provider/chat/message/chat_content_density_controller.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/layout/desktop_layout_controller.dart';
import 'package:anoxia/framework/provider/setting/settings_provider.dart';
import 'package:anoxia/framework/provider/setting/update_check_provider.dart';
import 'package:anoxia/framework/provider/theme/theme_controller.dart';
import 'package:anoxia/framework/provider/router/router.dart';
import 'package:anoxia/framework/theme/app_theme.dart';
import 'package:anoxia/framework/network/dio_client.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../common/utils/device_util.dart';

/// 设置页面
///
/// 提供主题切换、语言设置、关于支持、反馈意见等功能
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  /// 反馈表单 Key
  final _feedbackFormKey = GlobalKey<FormState>();

  /// 反馈标题编辑控制器
  final _feedbackTitleController = TextEditingController();

  /// 反馈内容编辑控制器
  final _feedbackContentController = TextEditingController();

  /// 反馈联系方式编辑控制器
  final _feedbackContactController = TextEditingController();

  final List<FeedbackImageAttachment> _feedbackImages = [];

  static const int _feedbackImageLimit = 3;
  static const int _feedbackImageMaxBytes = 5 * 1024 * 1024;

  @override
  void dispose() {
    _feedbackTitleController.dispose();
    _feedbackContentController.dispose();
    _feedbackContactController.dispose();
    super.dispose();
  }

  void _navigateToUpdatePage(AppUpdateInfo info) {
    UpdateRoute(
      hasUpdate: info.hasUpdate,
      latestVersion: info.latestVersion,
      downloadUrl: info.downloadUrl,
      releaseNotes: info.releaseNotes,
      forceUpdate: info.forceUpdate,
      minSupportVersion: info.minSupportVersion,
    ).push(context);
  }

  void _navigateToOpenSourceLicenses() {
    const OpenSourceLicensesRoute().push(context);
  }

  void _openDeveloperTribute() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const DeveloperTributePage(),
      ),
    );
  }

  void _showActionResult(SettingsActionResult result) {
    final text = (result.rawMessage ?? '').trim().isNotEmpty
        ? result.rawMessage!
        : (result.messageKey ?? '').tr();

    if (text.isEmpty) return;

    switch (result.status) {
      case SettingsActionStatus.success:
        Toast.showToast(text, type: ToastType.success);
        break;
      case SettingsActionStatus.info:
        Toast.showToast(text, type: ToastType.info);
        break;
      case SettingsActionStatus.error:
        Toast.showToast(text, type: ToastType.error);
        break;
    }
  }

  Future<void> _checkUpdate() async {
    final result = await ref
        .read(settingsPageControllerProvider.notifier)
        .checkUpdate();
    if (!mounted) return;
    _showActionResult(result);
  }

  Future<void> _submitFeedback() async {
    if (!_feedbackFormKey.currentState!.validate()) return;

    final clientType = DeviceUtil.isMobile(context)
        ? 'mobile'
        : (DeviceUtil.isDesktop(context) ? 'desktop' : 'tablet');

    final result = await ref
        .read(settingsPageControllerProvider.notifier)
        .submitFeedback(
          title: _feedbackTitleController.text.trim(),
          content: _feedbackContentController.text.trim(),
          contact: _feedbackContactController.text.trim(),
          clientType: clientType,
          images: _feedbackImages,
        );

    if (!mounted) return;

    if (result.status == SettingsActionStatus.success) {
      _feedbackTitleController.clear();
      _feedbackContentController.clear();
      _feedbackContactController.clear();
      setState(_feedbackImages.clear);
    }
    _showActionResult(result);
  }

  Future<void> _pickFeedbackImages() async {
    final remaining = _feedbackImageLimit - _feedbackImages.length;
    if (remaining <= 0) {
      Toast.showToast(
        'settings_feedback_image_limit'.tr(),
        type: ToastType.info,
      );
      return;
    }

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: true,
      withData: true,
    );
    if (!mounted || result == null) return;

    final picked = <FeedbackImageAttachment>[];
    for (final file in result.files.take(remaining)) {
      final bytes = file.bytes;
      if (bytes == null) continue;
      if (bytes.length > _feedbackImageMaxBytes) {
        Toast.showToast(
          'settings_feedback_image_too_large'.tr(args: [file.name]),
          type: ToastType.error,
        );
        continue;
      }
      picked.add(FeedbackImageAttachment(name: file.name, bytes: bytes));
    }

    if (result.files.length > remaining) {
      Toast.showToast(
        'settings_feedback_image_limit'.tr(),
        type: ToastType.info,
      );
    }
    if (picked.isNotEmpty) {
      setState(() => _feedbackImages.addAll(picked));
    }
  }

  void _removeFeedbackImage(int index) {
    setState(() => _feedbackImages.removeAt(index));
  }

  void _openProfile() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const MyPage()));
  }

  void _openPersonalQrCode() {
    final user = ref.read(authControllerProvider).value;
    if (user == null) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => PersonalQrPage(user: user)));
  }

  void _openChangePassword() {
    if (DeviceUtil.isDesktop(context)) {
      showEscClosableDialog<void>(
        context: context,
        builder: (_) => const ChangePasswordDialog(),
      );
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ChangePasswordPage()));
  }

  void _openSwitchAccount() {
    // 桌面/Web PC 宽屏：统一式样弹窗；移动端/Web SP：页面跳转
    presentAdaptivePage<void>(
      context,
      builder: (_) => const AccountSwitchPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pageState = ref.watch(settingsPageControllerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final themeAccentIndex = ref.watch(themeAccentProvider);
    final customAccentColor = ref.watch(customAccentColorProvider);
    final desktopLayoutPreference = ref.watch(desktopLayoutProvider);
    final appVersionAsync = ref.watch(appVersionProvider);
    final hasUpdateBadge = ref.watch(hasAppUpdateProvider);
    final supportsDesktopLayout = DeviceUtil.supportsDesktopLayoutPreference(
      context,
    );

    final appVersionText = appVersionAsync.maybeWhen(
      data: (value) => value,
      orElse: () => '--',
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        centerTitle: DeviceUtil.isMobile(context),
        title: Text('settings_page_title'.tr()),
      ),
      body: SettingsSplitView(
        destinations: [
          SettingsDestination(
            title: 'settings_account_title'.tr(),
            subtitle: 'settings_account_subtitle'.tr(),
            icon: HugeIcons.strokeRoundedUserAccount,
            builder: (_) => SettingsAccountSection(
              onOpenProfile: _openProfile,
              onOpenQrCode: _openPersonalQrCode,
              onChangePassword: _openChangePassword,
              onSwitchAccount: _openSwitchAccount,
            ),
          ),
          SettingsDestination(
            title: 'settings_appearance_title'.tr(),
            subtitle: 'settings_appearance_subtitle'.tr(),
            icon: HugeIcons.strokeRoundedColors,
            builder: (_) => Column(
              children: [
                SettingsThemeSection(
                  selectedBrightness: themeMode,
                  selectedAccentIndex: themeAccentIndex,
                  customColor: customAccentColor,
                  onBrightnessChanged: (brightness) {
                    ref.read(themeModeProvider.notifier).setMode(brightness);
                    final compatibilityIndex = AppTheme.compatibilityThemeIndex(
                      brightness: brightness,
                      accentIndex: themeAccentIndex,
                    );
                    ref.read(themeIndexProvider.notifier).setTheme(compatibilityIndex);
                    if (customAccentColor != null) {
                      // 保持自定义色时同步更新兼容索引（避免切回预设时跳色）
                      ref.read(themeIndexProvider.notifier).setTheme(compatibilityIndex);
                    }
                  },
                  onAccentChanged: (index) {
                    ref.read(customAccentColorProvider.notifier).setCustomColor(null);
                    ref.read(themeAccentProvider.notifier).setAccent(index);
                    final compatibilityIndex = AppTheme.compatibilityThemeIndex(
                      brightness: themeMode,
                      accentIndex: index,
                    );
                    ref.read(themeIndexProvider.notifier).setTheme(compatibilityIndex);
                  },
                  onCustomColorChanged: (color) {
                    ref.read(customAccentColorProvider.notifier).setCustomColor(color);
                    if (color != null) {
                      // 自定义色不依赖 accentIndex，兼容索引仍以当前预设为准
                      final compatibilityIndex = AppTheme.compatibilityThemeIndex(
                        brightness: themeMode,
                        accentIndex: themeAccentIndex,
                      );
                      ref.read(themeIndexProvider.notifier).setTheme(compatibilityIndex);
                    }
                  },
                ),
                if (supportsDesktopLayout) ...[
                  const SizedBox(height: 24),
                  SettingsLayoutSection(
                    selectedPreference: desktopLayoutPreference,
                    onChanged: (preference) => ref
                        .read(desktopLayoutProvider.notifier)
                        .setPreference(preference),
                  ),
                ],
                const SizedBox(height: 24),
                SettingsChatDensitySection(
                  selectedDensity: ref.watch(chatContentDensityProvider),
                  onChanged: (density) => ref
                      .read(chatContentDensityProvider.notifier)
                      .setDensity(density),
                ),
                if (DeviceUtil.supportsCustomBackground(context))
                  const SettingsBackgroundSection(),
              ],
            ),
          ),
          SettingsDestination(
            title: 'settings_page_language_title'.tr(),
            subtitle: 'settings_page_language_subtitle'.tr(),
            icon: HugeIcons.strokeRoundedLanguageSquare,
            builder: (_) => SettingsLanguageSection(
              selectedLanguageCode: context.locale.languageCode,
              isDesktop: DeviceUtil.isDesktop(context),
              onLanguageChanged: (localeCode) {
                context.setLocale(Locale(localeCode));
                DioClient().setLocale(localeCode);
                if (ref.read(callWindowControllerProvider) != null) {
                  ref
                      .read(callWindowControllerProvider.notifier)
                      .updateSettings(localeCode: localeCode);
                }
              },
            ),
          ),
          SettingsDestination(
            title: 'settings_general_title'.tr(),
            subtitle: 'settings_general_subtitle'.tr(),
            icon: HugeIcons.strokeRoundedSettings01,
            builder: (_) => const SettingsGeneralSection(),
          ),
          if (DeviceUtil.isWeb)
            SettingsDestination(
              title: 'settings_web_notification_title'.tr(),
              subtitle: 'settings_web_notification_subtitle'.tr(),
              icon: HugeIcons.strokeRoundedNotification01,
              builder: (_) => const SettingsWebNotificationSection(),
            ),
          SettingsDestination(
            title: 'settings_sticker_title'.tr(),
            subtitle: 'settings_sticker_subtitle'.tr(),
            icon: HugeIcons.strokeRoundedSticker,
            builder: (_) => const SettingsStickerSection(),
          ),
          SettingsDestination(
            title: 'settings_feedback_title'.tr(),
            subtitle: 'settings_feedback_subtitle'.tr(),
            icon: HugeIcons.strokeRoundedMessage02,
            builder: (_) => SettingsFeedbackSection(
              formKey: _feedbackFormKey,
              titleController: _feedbackTitleController,
              contentController: _feedbackContentController,
              contactController: _feedbackContactController,
              images: _feedbackImages,
              submitting: pageState.submittingFeedback,
              onPickImages: _pickFeedbackImages,
              onRemoveImage: _removeFeedbackImage,
              onSubmit: _submitFeedback,
            ),
          ),
          SettingsDestination(
            title: 'settings_page_about_title'.tr(),
            subtitle: 'settings_page_about_subtitle'.tr(),
            icon: HugeIcons.strokeRoundedInformationCircle,
            builder: (_) => SettingsAboutSupportSection(
              appVersionText: appVersionText,
              hasAppUpdate: hasUpdateBadge,
              pageState: pageState,
              onCheckUpdate: _checkUpdate,
              onNavigateToUpdatePage: _navigateToUpdatePage,
              onOpenOpenSourceLicenses: _navigateToOpenSourceLicenses,
              onOpenDeveloperTribute: _openDeveloperTribute,
            ),
          ),
        ],
      ),
    );
  }
}
