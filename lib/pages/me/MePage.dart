import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/framework/domain/UserInfo.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

class MyPage extends ConsumerStatefulWidget {
  const MyPage({super.key});

  @override
  ConsumerState<MyPage> createState() => _MyPageState();
}

class _MyPageState extends ConsumerState<MyPage> {
  final _profileFormKey = GlobalKey<FormState>();
  final _pwdFormKey = GlobalKey<FormState>();

  final _nickController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  final _oldPwdController = TextEditingController();
  final _newPwdController = TextEditingController();
  final _confirmPwdController = TextEditingController();

  String _sex = '2';
  int? _boundUserId;
  bool _savingProfile = false;
  bool _updatingPwd = false;
  bool _showOldPwd = false;
  bool _showNewPwd = false;
  bool _showConfirmPwd = false;

  @override
  void dispose() {
    _nickController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _oldPwdController.dispose();
    _newPwdController.dispose();
    _confirmPwdController.dispose();
    super.dispose();
  }

  void _bindUser(UserInfo user) {
    if (_boundUserId == user.userId) return;
    _boundUserId = user.userId;
    _nickController.text = user.nickName;
    _emailController.text = user.email;
    _phoneController.text = user.phoneNumber;
    _sex = user.sex;
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('me_page_title'.tr())),
      backgroundColor: colorScheme.surface,
      body: authAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text('chat_load_failed'.tr())),
        data: (user) {
          if (user == null) {
            return Center(child: Text('chat_initialization_failed'.tr()));
          }
          _bindUser(user);
          return SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                  children: [
                    _buildProfileOverview(context, user),
                    const SizedBox(height: 12),
                    _buildEditProfileCard(context, user),
                    const SizedBox(height: 12),
                    _buildUpdatePasswordCard(context),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileOverview(BuildContext context, UserInfo user) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.95),
            colorScheme.secondaryContainer.withValues(alpha: 0.88),
          ],
        ),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          AvatarWidget(url: user.avatar, name: user.nickName, size: 66),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nickName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${user.userName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      context,
                      icon: Icons.badge_outlined,
                      text: _sexText(user.sex),
                    ),
                    if (user.email.trim().isNotEmpty)
                      _buildInfoChip(
                        context,
                        icon: Icons.alternate_email_rounded,
                        text: user.email,
                      ),
                    if (user.phoneNumber.trim().isNotEmpty)
                      _buildInfoChip(
                        context,
                        icon: Icons.phone_outlined,
                        text: user.phoneNumber,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.75)),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditProfileCard(BuildContext context, UserInfo user) {
    final colorScheme = Theme.of(context).colorScheme;

    return _buildSectionCard(
      context,
      title: 'me_profile_edit_title'.tr(),
      subtitle: 'me_profile_edit_subtitle'.tr(),
      icon: HugeIcons.strokeRoundedUserEdit01,
      child: Form(
        key: _profileFormKey,
        child: Column(
          children: [
            TextFormField(
              initialValue: user.userName,
              enabled: false,
              decoration: _inputDecoration(
                context,
                label: 'me_profile_username'.tr(),
                icon: Icons.person_outline_rounded,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nickController,
              decoration: _inputDecoration(
                context,
                label: 'me_profile_nickname'.tr(),
                icon: Icons.badge_outlined,
              ),
              validator: (v) {
                if ((v ?? '').trim().isEmpty) {
                  return 'me_profile_nickname_required'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: _inputDecoration(
                context,
                label: 'me_profile_email'.tr(),
                icon: Icons.email_outlined,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: _inputDecoration(
                context,
                label: 'me_profile_phone'.tr(),
                icon: Icons.phone_outlined,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _sex,
              decoration: _inputDecoration(
                context,
                label: 'me_profile_gender'.tr(),
                icon: Icons.wc_outlined,
              ),
              items: [
                DropdownMenuItem(value: '0', child: Text('contact_male'.tr())),
                DropdownMenuItem(value: '1', child: Text('contact_female'.tr())),
                DropdownMenuItem(
                  value: '2',
                  child: Text('contact_unknown_gender'.tr()),
                ),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _sex = v);
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _savingProfile ? null : _saveProfile,
                icon: _savingProfile
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text('me_profile_save'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdatePasswordCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _buildSectionCard(
      context,
      title: 'me_password_title'.tr(),
      subtitle: 'me_password_subtitle'.tr(),
      icon: HugeIcons.strokeRoundedSquareLockPassword,
      child: Form(
        key: _pwdFormKey,
        child: Column(
          children: [
            TextFormField(
              controller: _oldPwdController,
              obscureText: !_showOldPwd,
              decoration: _pwdDecoration(
                context,
                label: 'me_password_old'.tr(),
                visible: _showOldPwd,
                onToggle: () => setState(() => _showOldPwd = !_showOldPwd),
              ),
              validator: (v) =>
                  (v ?? '').isEmpty ? 'me_password_old_required'.tr() : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _newPwdController,
              obscureText: !_showNewPwd,
              decoration: _pwdDecoration(
                context,
                label: 'me_password_new'.tr(),
                visible: _showNewPwd,
                onToggle: () => setState(() => _showNewPwd = !_showNewPwd),
              ),
              validator: (v) {
                if ((v ?? '').isEmpty) return 'me_password_new_required'.tr();
                if ((v ?? '').length < 6) return 'me_password_new_len'.tr();
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmPwdController,
              obscureText: !_showConfirmPwd,
              decoration: _pwdDecoration(
                context,
                label: 'me_password_confirm'.tr(),
                visible: _showConfirmPwd,
                onToggle: () => setState(() => _showConfirmPwd = !_showConfirmPwd),
              ),
              validator: (v) {
                if ((v ?? '').isEmpty) {
                  return 'me_password_confirm_required'.tr();
                }
                if (v != _newPwdController.text) {
                  return 'me_password_confirm_mismatch'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: _updatingPwd ? null : _updatePassword,
                icon: _updatingPwd
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      )
                    : const Icon(Icons.lock_reset_outlined, size: 18),
                label: Text('me_password_submit'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<List<dynamic>> icon,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.75)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: HugeIcon(icon: icon, color: colorScheme.primary, size: 18),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18),
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.75)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  InputDecoration _pwdDecoration(
    BuildContext context, {
    required String label,
    required bool visible,
    required VoidCallback onToggle,
  }) {
    return _inputDecoration(
      context,
      label: label,
      icon: Icons.lock_outline_rounded,
    ).copyWith(
      suffixIcon: IconButton(
        tooltip: visible ? 'hide' : 'show',
        onPressed: onToggle,
        icon: Icon(
          visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 18,
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() => _savingProfile = true);
    try {
      final res = await DioClient().put(
        API.userProfileUpdate,
        data: {
          'nickName': _nickController.text.trim(),
          'email': _emailController.text.trim(),
          'phonenumber': _phoneController.text.trim(),
          'sex': _sex,
        },
      );

      final ok = res.data is Map && res.data['code'] == 200;
      if (ok) {
        await ref.read(authControllerProvider.notifier).refreshUserInfo();
        Toast.showToast('me_profile_save_success'.tr(), type: ToastType.success);
      } else {
        Toast.showToast(
          (res.data is Map ? (res.data['msg']?.toString() ?? '') : '').isNotEmpty
              ? res.data['msg'].toString()
              : 'me_profile_save_failed'.tr(),
          type: ToastType.error,
        );
      }
    } catch (_) {
      Toast.showToast('me_profile_save_failed'.tr(), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _updatePassword() async {
    if (!_pwdFormKey.currentState!.validate()) return;

    setState(() => _updatingPwd = true);
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
        Toast.showToast('me_password_update_success'.tr(), type: ToastType.success);
      } else {
        Toast.showToast(
          (res.data is Map ? (res.data['msg']?.toString() ?? '') : '').isNotEmpty
              ? res.data['msg'].toString()
              : 'me_password_update_failed'.tr(),
          type: ToastType.error,
        );
      }
    } catch (_) {
      Toast.showToast('me_password_update_failed'.tr(), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _updatingPwd = false);
    }
  }

  String _sexText(String sex) {
    switch (sex) {
      case '0':
        return 'contact_male'.tr();
      case '1':
        return 'contact_female'.tr();
      default:
        return 'contact_unknown_gender'.tr();
    }
  }
}
