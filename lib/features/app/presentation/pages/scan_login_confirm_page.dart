import 'package:anoxia/common/widgets/toast.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/core/device_identity.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/core/auth_repository_provider.dart';
import 'package:dio/dio.dart' show DioException;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 扫码登录确认页（手机端）
///
/// 手机 App 扫描桌面端二维码后进入本页，展示登录确认信息。
/// 用户点击确认后以当前账号为新设备签发登录令牌。
class ScanLoginConfirmPage extends ConsumerStatefulWidget {
  const ScanLoginConfirmPage({super.key, required this.ticket});

  /// 扫码登录会话 ticket
  final String ticket;

  @override
  ConsumerState<ScanLoginConfirmPage> createState() =>
      _ScanLoginConfirmPageState();
}

class _ScanLoginConfirmPageState extends ConsumerState<ScanLoginConfirmPage> {
  /// 是否正在提交确认
  bool _submitting = false;

  Future<void> _confirm() async {
    if (_submitting) return;
    final me = ref.read(authControllerProvider).value;
    if (me == null) {
      Toast.showToast(
        'scan_login_confirm_need_login'.tr(),
        type: ToastType.warning,
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(authRepositoryProvider).confirmScanLogin(
            widget.ticket,
            deviceId: await DeviceIdentity.instance.getPlatformQualifiedId(),
          );
      if (!mounted) return;
      Toast.showToast(
        'scan_login_confirm_success'.tr(),
        type: ToastType.success,
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      Toast.showToast(
        _parseErrorMessage(e),
        type: ToastType.error,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// 优先展示后端返回的错误文案
  String _parseErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final msg = data['msg'] ?? data['message'];
        if (msg is String && msg.trim().isNotEmpty) return msg.trim();
      }
    }
    return 'scan_login_confirm_failed'.tr();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final me = ref.watch(authControllerProvider).value;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text('scan_login_confirm_title'.tr()),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedComputer,
                  size: 48,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'scan_login_confirm_title'.tr(),
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'scan_login_confirm_hint'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              if (me != null && (me.nickName.isNotEmpty || me.userName.isNotEmpty)) ...[
                const SizedBox(height: 8),
                Text(
                  me.nickName.isNotEmpty ? me.nickName : me.userName,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _submitting ? null : _confirm,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text('scan_login_confirm_confirm'.tr()),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _submitting
                    ? null
                    : () => Navigator.of(context).pop(),
                child: Text('scan_login_confirm_cancel'.tr()),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}