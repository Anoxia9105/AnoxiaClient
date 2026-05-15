import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/features/settings/application/settings_page_controller.dart';
import 'package:anoxia/features/settings/presentation/widgets/settings_about_support_section.dart';
import 'package:anoxia/features/settings/presentation/widgets/settings_feedback_section.dart';
import 'package:anoxia/features/settings/presentation/widgets/settings_language_section.dart';
import 'package:anoxia/features/settings/presentation/widgets/settings_theme_section.dart';
import 'package:anoxia/framework/provider/chat/call/call_window_controller.dart';
import 'package:anoxia/framework/provider/setting/settings_provider.dart';
import 'package:anoxia/framework/provider/setting/update_check_provider.dart';
import 'package:anoxia/framework/provider/theme/theme_controller.dart';
import 'package:anoxia/framework/provider/router/router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/utils/DeviceUtil.dart';

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
        );

    if (!mounted) return;

    if (result.status == SettingsActionStatus.success) {
      _feedbackTitleController.clear();
      _feedbackContentController.clear();
      _feedbackContactController.clear();
    }
    _showActionResult(result);
  }

  @override
  Widget build(BuildContext context) {
    final pageState = ref.watch(settingsPageControllerProvider);
    final themeIndex = ref.watch(themeIndexProvider);
    final callWin = ref.read(callWindowControllerProvider);
    final appVersionAsync = ref.watch(appVersionProvider);
    final hasUpdateBadge = ref.watch(hasAppUpdateProvider);

    final appVersionText = appVersionAsync.maybeWhen(
      data: (value) => value,
      orElse: () => '--',
    );

    return Scaffold(
      appBar: AppBar(title: Text('settings_page_title'.tr())),
      body: ListView(
        children: [
          SettingsThemeSection(
            selectedThemeIndex: themeIndex,
            onThemeChanged: (index) {
              ref.read(themeIndexProvider.notifier).setTheme(index);
              if (callWin != null) {
                ref
                    .read(callWindowControllerProvider.notifier)
                    .updateSettings(themeIndex: index);
              }
            },
          ),
          SettingsLanguageSection(
            selectedLanguageCode: context.locale.languageCode,
            isDesktop: DeviceUtil.isDesktop(context),
            onLanguageChanged: (localeCode) {
              context.setLocale(Locale(localeCode));
              if (callWin != null) {
                ref
                    .read(callWindowControllerProvider.notifier)
                    .updateSettings(localeCode: localeCode);
              }
            },
          ),
          SettingsAboutSupportSection(
            appVersionText: appVersionText,
            hasAppUpdate: hasUpdateBadge,
            pageState: pageState,
            onCheckUpdate: _checkUpdate,
            onNavigateToUpdatePage: _navigateToUpdatePage,
            onOpenOpenSourceLicenses: _navigateToOpenSourceLicenses,
          ),
          SettingsFeedbackSection(
            formKey: _feedbackFormKey,
            titleController: _feedbackTitleController,
            contentController: _feedbackContentController,
            contactController: _feedbackContactController,
            submitting: pageState.submittingFeedback,
            onSubmit: _submitFeedback,
          ),
        ],
      ),
    );
  }
}
