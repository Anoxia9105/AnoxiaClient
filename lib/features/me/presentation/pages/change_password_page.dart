import 'package:anoxia/common/constants/api.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/framework/network/dio_client.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 桌面端密码修改对话框，避免在主内容区继续压入移动端页面。
class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _oldPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _oldPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_oldPassword.text.isEmpty) {
      Toast.showToast('me_password_old_required'.tr(), type: ToastType.error);
      return;
    }
    if (_newPassword.text.length < 6) {
      Toast.showToast('me_password_new_len'.tr(), type: ToastType.error);
      return;
    }
    if (_confirmPassword.text != _newPassword.text) {
      Toast.showToast(
        'me_password_confirm_mismatch'.tr(),
        type: ToastType.error,
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final res = await DioClient().put(
        API.userProfileUpdatePassword,
        data: {
          'oldPassword': _oldPassword.text,
          'newPassword': _newPassword.text,
          'confirmPassword': _confirmPassword.text,
        },
      );
      final ok = res.data is Map && res.data['code'] == 200;
      if (!ok) {
        final msg =
            (res.data is Map ? res.data['msg']?.toString() : null) ?? '';
        Toast.showToast(
          msg.isNotEmpty ? msg : 'me_password_update_failed'.tr(),
          type: ToastType.error,
        );
        return;
      }
      Toast.showToast(
        'me_password_update_success'.tr(),
        type: ToastType.success,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      Toast.showToast('me_password_update_failed'.tr(), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Row(
        children: [
          HugeIcon(icon: HugeIcons.strokeRoundedLockSync01, color: cs.primary),
          const SizedBox(width: 10),
          Text('me_password_title'.tr()),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: AutofillGroup(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _passwordField(
                controller: _oldPassword,
                label: 'me_password_old'.tr(),
                autofillHints: const [AutofillHints.password],
              ),
              const SizedBox(height: 14),
              _passwordField(
                controller: _newPassword,
                label: 'me_password_new'.tr(),
                autofillHints: const [AutofillHints.newPassword],
              ),
              const SizedBox(height: 14),
              _passwordField(
                controller: _confirmPassword,
                label: 'me_password_confirm'.tr(),
                autofillHints: const [AutofillHints.newPassword],
                onSubmitted: (_) {
                  if (!_saving) _submit();
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text('dialog_cancel'.tr()),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _submit,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const HugeIcon(icon: HugeIcons.strokeRoundedLockSync01, size: 18),
          label: Text('me_password_submit'.tr()),
        ),
      ],
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required Iterable<String> autofillHints,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: true,
      enabled: !_saving,
      autofillHints: autofillHints,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const HugeIcon(icon: HugeIcons.strokeRoundedLockPassword, size: 16),
      ),
    );
  }
}

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _oldPwdController = TextEditingController();
  final _newPwdController = TextEditingController();
  final _confirmPwdController = TextEditingController();

  bool _updating = false;

  @override
  void dispose() {
    _oldPwdController.dispose();
    _newPwdController.dispose();
    _confirmPwdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: Text('me_password_title'.tr())),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        children: [
          _buildSectionTitle(context, 'me_password_title'.tr()),
          const SizedBox(height: 8),
          _buildTileSection(
            context,
            children: [
              _buildEditableTile(
                context,
                title: 'me_password_old'.tr(),
                value: _maskedValue(_oldPwdController.text),
                onTap: () => _editTextField(
                  title: 'me_password_old'.tr(),
                  controller: _oldPwdController,
                ),
              ),
              _buildTileDivider(context),
              _buildEditableTile(
                context,
                title: 'me_password_new'.tr(),
                value: _maskedValue(_newPwdController.text),
                onTap: () => _editTextField(
                  title: 'me_password_new'.tr(),
                  controller: _newPwdController,
                ),
              ),
              _buildTileDivider(context),
              _buildEditableTile(
                context,
                title: 'me_password_confirm'.tr(),
                value: _maskedValue(_confirmPwdController.text),
                onTap: () => _editTextField(
                  title: 'me_password_confirm'.tr(),
                  controller: _confirmPwdController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.tonalIcon(
              onPressed: _updating ? null : _updatePassword,
              icon: _updating
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onSecondaryContainer,
                      ),
                    )
                  : const HugeIcon(icon: HugeIcons.strokeRoundedLockSync01, size: 18),
              label: Text('me_password_submit'.tr()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildTileSection(
    BuildContext context, {
    required List<Widget> children,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainer,
      borderRadius: BorderRadius.circular(14),
      child: Column(children: children),
    );
  }

  Widget _buildTileDivider(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Divider(
      height: 1,
      indent: 14,
      endIndent: 14,
      color: cs.outlineVariant.withValues(alpha: 0.5),
    );
  }

  Widget _buildEditableTile(
    BuildContext context, {
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      minVerticalPadding: 14,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      title: Text(title, style: const TextStyle(fontSize: 14.5)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 4),
          HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 20, color: cs.outline),
        ],
      ),
      onTap: onTap,
    );
  }

  String _maskedValue(String text) {
    if (text.isEmpty) return '--';
    return '*' * text.length;
  }

  Future<void> _editTextField({
    required String title,
    required TextEditingController controller,
  }) async {
    final temp = TextEditingController(text: controller.text);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: temp,
            autofocus: true,
            obscureText: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(temp.text),
              child: Text('confirm'.tr()),
            ),
          ],
        );
      },
    );

    temp.dispose();

    if (result != null && mounted) {
      setState(() => controller.text = result.trim());
    }
  }

  Future<void> _updatePassword() async {
    if (_oldPwdController.text.isEmpty) {
      Toast.showToast('me_password_old_required'.tr(), type: ToastType.error);
      return;
    }
    if (_newPwdController.text.isEmpty) {
      Toast.showToast('me_password_new_required'.tr(), type: ToastType.error);
      return;
    }
    if (_newPwdController.text.length < 6) {
      Toast.showToast('me_password_new_len'.tr(), type: ToastType.error);
      return;
    }
    if (_confirmPwdController.text.isEmpty) {
      Toast.showToast(
        'me_password_confirm_required'.tr(),
        type: ToastType.error,
      );
      return;
    }
    if (_confirmPwdController.text != _newPwdController.text) {
      Toast.showToast(
        'me_password_confirm_mismatch'.tr(),
        type: ToastType.error,
      );
      return;
    }

    setState(() => _updating = true);
    try {
      final res = await DioClient().put(
        API.userProfileUpdatePassword,
        data: {
          'oldPassword': _oldPwdController.text,
          'newPassword': _newPwdController.text,
          'confirmPassword': _confirmPwdController.text,
        },
      );
      final ok = res.data is Map && res.data['code'] == 200;
      if (ok) {
        _oldPwdController.clear();
        _newPwdController.clear();
        _confirmPwdController.clear();
        Toast.showToast(
          'me_password_update_success'.tr(),
          type: ToastType.success,
        );
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        final msg =
            (res.data is Map ? res.data['msg']?.toString() : null) ?? '';
        Toast.showToast(
          msg.isNotEmpty ? msg : 'me_password_update_failed'.tr(),
          type: ToastType.error,
        );
      }
    } catch (_) {
      Toast.showToast('me_password_update_failed'.tr(), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }
}
