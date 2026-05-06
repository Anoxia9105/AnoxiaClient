import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/framework/provider/chat/call/call_window_controller.dart';
import 'package:anoxia/framework/provider/setting/settings_provider.dart';
import 'package:anoxia/framework/provider/theme/theme_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../common/utils/DeviceUtil.dart';
import '../../framework/theme/AppTheme.dart';
import 'SettingItemCard.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _feedbackFormKey = GlobalKey<FormState>();
  final _feedbackTitleController = TextEditingController();
  final _feedbackContentController = TextEditingController();
  final _feedbackContactController = TextEditingController();
  bool _submittingFeedback = false;
  bool _checkingUpdate = false;
  AppUpdateInfo? _updateInfo;
  String? _updateError;

  @override
  void dispose() {
    _feedbackTitleController.dispose();
    _feedbackContentController.dispose();
    _feedbackContactController.dispose();
    super.dispose();
  }

  Future<void> _checkUpdate() async {
    if (_checkingUpdate) return;
    setState(() {
      _checkingUpdate = true;
      _updateError = null;
    });

    try {
      final currentVersion = await ref.read(appVersionProvider.future);
      final info = await ref
          .read(settingsRepositoryProvider)
          .checkForUpdate(
            currentVersion: currentVersion,
            clientType: resolveUpdateClientType(),
          );
      if (!mounted) return;
      setState(() => _updateInfo = info);
      if (info.hasUpdate) {
        Toast.showToast('update_new_version'.tr(), type: ToastType.success);
      } else {
        Toast.showToast('settings_update_no_update'.tr(), type: ToastType.info);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _updateError = 'settings_update_check_failed'.tr());
      Toast.showToast(
        'settings_update_check_failed'.tr(),
        type: ToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _checkingUpdate = false);
      }
    }
  }

  Future<void> _openDownloadUrl(String url) async {
    final ok = await launchUrlString(url, mode: LaunchMode.externalApplication);
    if (!ok) {
      Toast.showToast(
        'settings_update_open_download_failed'.tr(),
        type: ToastType.error,
      );
    }
  }

  Future<void> _submitFeedback() async {
    if (!_feedbackFormKey.currentState!.validate()) return;
    if (_submittingFeedback) return;

    setState(() => _submittingFeedback = true);
    try {
      final appVersion = ref
          .read(appVersionProvider)
          .maybeWhen(data: (value) => value, orElse: () => 'unknown');
      final clientType = DeviceUtil.isMobile(context)
          ? 'mobile'
          : (DeviceUtil.isDesktop(context) ? 'desktop' : 'tablet');
      final result = await ref
          .read(settingsRepositoryProvider)
          .submitFeedback(
            title: _feedbackTitleController.text.trim(),
            content: _feedbackContentController.text.trim(),
            contact: _feedbackContactController.text.trim(),
            clientType: clientType,
            appVersion: appVersion,
          );

      if (result.success) {
        _feedbackTitleController.clear();
        _feedbackContentController.clear();
        _feedbackContactController.clear();
        Toast.showToast(
          'settings_feedback_submit_success'.tr(),
          type: ToastType.success,
        );
      } else {
        Toast.showToast(
          (result.message ?? '').isNotEmpty
              ? result.message!
              : 'settings_feedback_submit_failed'.tr(),
          type: ToastType.error,
        );
      }
    } catch (_) {
      Toast.showToast(
        'settings_feedback_submit_failed'.tr(),
        type: ToastType.error,
      );
    } finally {
      if (mounted) setState(() => _submittingFeedback = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeIndex = ref.watch(themeIndexProvider);
    final callWin = ref.read(callWindowControllerProvider);
    final appVersionAsync = ref.watch(appVersionProvider);
    final appVersionText = appVersionAsync.maybeWhen(
      data: (value) => value,
      orElse: () => '--',
    );

    return Scaffold(
      appBar: AppBar(title: Text("settings_page_title".tr())),
      body: ListView(
        children: [
          // 主题设置
          SettingItemCard(
            title: "settings_page_theme_title".tr(),
            subtitle: "settings_page_theme_subtitle".tr(),
            icon: HugeIcons.strokeRoundedColors,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 8) / 2; // 8 是 spacing
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(AppTheme.themes.length, (index) {
                    final isSelected = themeIndex == index;

                    final theme = AppTheme.themes[index];
                    return SizedBox(
                      width: itemWidth,
                      child: InkWell(
                        onTap: () {
                          ref.read(themeIndexProvider.notifier).setTheme(index);
                          if (callWin != null) {
                            ref
                                .read(callWindowControllerProvider.notifier)
                                .updateSettings(themeIndex: index);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).brightness ==
                                        Brightness.dark
                                  ? Colors.grey.shade900
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: theme.color,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  theme.localizedName,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 18,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),

          // 语言设置
          SettingItemCard(
            title: "settings_page_language_title".tr(),
            subtitle: "settings_page_language_subtitle".tr(),
            icon: HugeIcons.strokeRoundedLanguageSquare,
            child: Row(
              children: [
                Expanded(flex: 2, child: SizedBox.shrink()),
                Expanded(
                  flex: DeviceUtil.isDesktop(context) ? 1 : 2,
                  child: Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: DropdownButtonFormField<String>(
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        // fontFamily: setting.fontFamily,
                      ),
                      icon: Icon(Icons.expand_more),
                      initialValue: context.locale.languageCode,
                      items: [
                        DropdownMenuItem(
                          value: 'en',
                          child: Text('settings_language_english'.tr()),
                        ),
                        DropdownMenuItem(
                          value: 'zh',
                          child: Text('settings_language_chinese'.tr()),
                        ),
                        DropdownMenuItem(
                          value: 'ja',
                          child: Text('settings_language_japanese'.tr()),
                        ),
                      ],
                      onChanged: (locale) {
                        if (locale != null) {
                          context.setLocale(Locale(locale));
                          if (callWin != null) {
                            ref
                                .read(callWindowControllerProvider.notifier)
                                .updateSettings(localeCode: locale);
                          }
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          //关于与支持
          SettingItemCard(
            title: "settings_page_about_title".tr(),
            subtitle: "settings_page_about_subtitle".tr(),
            icon: HugeIcons.strokeRoundedLink01,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 30),
              child: Column(
                children: [
                  ListTile(
                    dense: true,
                    leading: HugeIcon(
                      icon: HugeIcons.strokeRoundedQuillWrite01,
                      size: 18,
                    ),
                    title: Text('settings_app_name'.tr()),
                    trailing: Text("Anoxia", style: TextStyle(fontSize: 14)),
                  ),
                  ListTile(
                    dense: true,
                    leading: HugeIcon(
                      icon: HugeIcons.strokeRoundedSortByUp01,
                      size: 18,
                    ),
                    title: Text('settings_app_version'.tr()),
                    trailing: Text(
                      appVersionText,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  ListTile(
                    dense: true,
                    leading: HugeIcon(
                      icon: HugeIcons.strokeRoundedCloudSavingDone01,
                      size: 18,
                    ),
                    title: Text('settings_update_check'.tr()),
                    subtitle: _updateInfo?.latestVersion.isNotEmpty == true
                        ? Text(
                            '${'settings_update_latest'.tr()}: ${_updateInfo!.latestVersion}',
                            style: const TextStyle(fontSize: 12),
                          )
                        : null,
                    trailing: FilledButton.tonalIcon(
                      onPressed: _checkingUpdate ? null : _checkUpdate,
                      icon: _checkingUpdate
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            )
                          : const Icon(Icons.refresh, size: 16),
                      label: Text('settings_update_check'.tr()),
                    ),
                  ),
                  if (_updateError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Text(
                        _updateError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (_updateInfo != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: .04)
                            : Colors.black.withValues(alpha: .03),
                        border: Border.all(
                          color: _updateInfo!.hasUpdate
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: .45)
                              : Theme.of(
                                  context,
                                ).dividerColor.withValues(alpha: .25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _updateInfo!.hasUpdate
                                ? '${'update_new_version'.tr()}: ${_updateInfo!.latestVersion}'
                                : 'settings_update_no_update'.tr(),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _updateInfo!.hasUpdate
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _updateInfo!.releaseNotes.isNotEmpty
                                ? _updateInfo!.releaseNotes
                                : 'update_default_notes'.tr(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                          if (_updateInfo!.hasUpdate &&
                              _updateInfo!.downloadUrl.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () =>
                                    _openDownloadUrl(_updateInfo!.downloadUrl),
                                icon: const Icon(
                                  Icons.download_rounded,
                                  size: 18,
                                ),
                                label: Text('update_now'.tr()),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          SettingItemCard(
            title: 'settings_feedback_title'.tr(),
            subtitle: 'settings_feedback_subtitle'.tr(),
            icon: HugeIcons.strokeRoundedMessage02,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Form(
                key: _feedbackFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _feedbackTitleController,
                      decoration: InputDecoration(
                        labelText: 'settings_feedback_subject'.tr(),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if ((v ?? '').trim().isEmpty) {
                          return 'settings_feedback_subject_required'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _feedbackContentController,
                      minLines: 4,
                      maxLines: 8,
                      decoration: InputDecoration(
                        labelText: 'settings_feedback_content'.tr(),
                        alignLabelWithHint: true,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if ((v ?? '').trim().isEmpty) {
                          return 'settings_feedback_content_required'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _feedbackContactController,
                      decoration: InputDecoration(
                        labelText: 'settings_feedback_contact'.tr(),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _submittingFeedback ? null : _submitFeedback,
                        icon: _submittingFeedback
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                              )
                            : const Icon(Icons.bug_report_outlined, size: 18),
                        label: Text('settings_feedback_submit'.tr()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
