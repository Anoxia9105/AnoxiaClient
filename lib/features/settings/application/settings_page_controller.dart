import 'package:anoxia/framework/provider/setting/settings_provider.dart';
import 'package:anoxia/framework/provider/setting/update_check_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPageState {
  final bool submittingFeedback;
  final bool checkingUpdate;
  final AppUpdateInfo? updateInfo;
  final String? updateErrorKey;

  const SettingsPageState({
    this.submittingFeedback = false,
    this.checkingUpdate = false,
    this.updateInfo,
    this.updateErrorKey,
  });

  SettingsPageState copyWith({
    bool? submittingFeedback,
    bool? checkingUpdate,
    AppUpdateInfo? updateInfo,
    bool clearUpdateInfo = false,
    String? updateErrorKey,
    bool clearUpdateError = false,
  }) {
    return SettingsPageState(
      submittingFeedback: submittingFeedback ?? this.submittingFeedback,
      checkingUpdate: checkingUpdate ?? this.checkingUpdate,
      updateInfo: clearUpdateInfo ? null : (updateInfo ?? this.updateInfo),
      updateErrorKey: clearUpdateError
          ? null
          : (updateErrorKey ?? this.updateErrorKey),
    );
  }
}

enum SettingsActionStatus { success, info, error }

class SettingsActionResult {
  final SettingsActionStatus status;
  final String? messageKey;
  final String? rawMessage;

  const SettingsActionResult({
    required this.status,
    this.messageKey,
    this.rawMessage,
  });
}

class SettingsPageController extends Notifier<SettingsPageState> {
  @override
  SettingsPageState build() => const SettingsPageState();

  Future<SettingsActionResult> checkUpdate() async {
    if (state.checkingUpdate) {
      return const SettingsActionResult(
        status: SettingsActionStatus.info,
        messageKey: 'settings_update_checking',
      );
    }

    state = state.copyWith(checkingUpdate: true, clearUpdateError: true);

    try {
      final currentVersion = await ref.read(appVersionProvider.future);
      final info = await ref
          .read(settingsRepositoryProvider)
          .checkForUpdate(
            currentVersion: currentVersion,
            clientType: resolveUpdateClientType(),
          );

      state = state.copyWith(updateInfo: info);

      ref
          .read(appUpdateCheckerProvider.notifier)
          .syncResult(info, currentVersion: currentVersion);

      if (info.hasUpdate) {
        return const SettingsActionResult(
          status: SettingsActionStatus.success,
          messageKey: 'update_new_version',
        );
      }

      return const SettingsActionResult(
        status: SettingsActionStatus.info,
        messageKey: 'settings_update_no_update',
      );
    } catch (_) {
      state = state.copyWith(updateErrorKey: 'settings_update_check_failed');
      return const SettingsActionResult(
        status: SettingsActionStatus.error,
        messageKey: 'settings_update_check_failed',
      );
    } finally {
      state = state.copyWith(checkingUpdate: false);
    }
  }

  Future<SettingsActionResult> submitFeedback({
    required String title,
    required String content,
    required String contact,
    required String clientType,
  }) async {
    if (state.submittingFeedback) {
      return const SettingsActionResult(
        status: SettingsActionStatus.info,
        messageKey: 'settings_feedback_submitting',
      );
    }

    state = state.copyWith(submittingFeedback: true);
    try {
      final appVersion = await ref.read(appVersionProvider.future);
      final result = await ref
          .read(settingsRepositoryProvider)
          .submitFeedback(
            title: title,
            content: content,
            contact: contact,
            clientType: clientType,
            appVersion: appVersion,
          );

      if (result.success) {
        return const SettingsActionResult(
          status: SettingsActionStatus.success,
          messageKey: 'settings_feedback_submit_success',
        );
      }

      return SettingsActionResult(
        status: SettingsActionStatus.error,
        messageKey: 'settings_feedback_submit_failed',
        rawMessage: result.message,
      );
    } catch (_) {
      return const SettingsActionResult(
        status: SettingsActionStatus.error,
        messageKey: 'settings_feedback_submit_failed',
      );
    } finally {
      state = state.copyWith(submittingFeedback: false);
    }
  }
}

final settingsPageControllerProvider =
    NotifierProvider.autoDispose<SettingsPageController, SettingsPageState>(
      SettingsPageController.new,
    );
