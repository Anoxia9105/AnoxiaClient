import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/features/me/presentation/widgets/me_header_widgets.dart';
import 'package:anoxia/framework/domain/UserInfo.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 个人中心页面
///
/// 支持用户查看和编辑个人信息、修改密码等功能
class MyPage extends ConsumerStatefulWidget {
  const MyPage({super.key});

  @override
  ConsumerState<MyPage> createState() => _MyPageState();
}

class _MyPageState extends ConsumerState<MyPage>
    with SingleTickerProviderStateMixin {
  /// 个人资料表单 Key
  final _profileFormKey = GlobalKey<FormState>();
  /// 密码修改表单 Key
  final _pwdFormKey = GlobalKey<FormState>();

  /// 昵称编辑控制器
  final _nickController = TextEditingController();
  /// 邮箱编辑控制器
  final _emailController = TextEditingController();
  /// 手机号编辑控制器
  final _phoneController = TextEditingController();

  /// 旧密码编辑控制器
  final _oldPwdController = TextEditingController();
  /// 新密码编辑控制器
  final _newPwdController = TextEditingController();
  /// 确认密码编辑控制器
  final _confirmPwdController = TextEditingController();

  /// 性别（0=男，1=女，2=未知）
  String _sex = '2';
  /// 用户信息快照（用于检测变化）
  String? _boundUserSnapshot;
  /// 是否正在保存个人资料
  bool _savingProfile = false;
  /// 是否正在更新密码
  bool _updatingPwd = false;
  /// 是否显示旧密码
  bool _showOldPwd = false;
  /// 是否显示新密码
  bool _showNewPwd = false;
  /// 是否显示确认密码
  bool _showConfirmPwd = false;
  /// Tab 控制器
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nickController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _oldPwdController.dispose();
    _newPwdController.dispose();
    _confirmPwdController.dispose();
    super.dispose();
  }

  void _bindUser(UserInfo user) {
    final snapshot = [
      user.userId.toString(),
      user.nickName,
      user.email,
      user.phoneNumber,
      user.sex,
      user.avatar,
    ].join('|');
    if (_boundUserSnapshot == snapshot) return;
    _boundUserSnapshot = snapshot;
    _nickController.text = user.nickName;
    _emailController.text = user.email;
    _phoneController.text = user.phoneNumber;
    _sex = user.sex;
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text('me_page_title'.tr())),
      backgroundColor: Colors.transparent,
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
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                      child: Column(
                        children: [
                          MeProfileCard(user: user),
                          const SizedBox(height: 12),
                          MeTabSwitcher(controller: _tabController),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildProfileForm(context, user),
                          _buildPasswordForm(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileForm(BuildContext context, UserInfo user) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        Form(
          key: _profileFormKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: user.userName,
                enabled: false,
                decoration: _inputDeco(
                  context,
                  label: 'me_profile_username'.tr(),
                  icon: Icons.person_outline_rounded,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nickController,
                decoration: _inputDeco(
                  context,
                  label: 'me_profile_nickname'.tr(),
                  icon: Icons.badge_outlined,
                ),
                validator: (v) => (v ?? '').trim().isEmpty
                    ? 'me_profile_nickname_required'.tr()
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: _inputDeco(
                  context,
                  label: 'me_profile_email'.tr(),
                  icon: Icons.email_outlined,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: _inputDeco(
                  context,
                  label: 'me_profile_phone'.tr(),
                  icon: Icons.phone_outlined,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _sex,
                decoration: _inputDeco(
                  context,
                  label: 'me_profile_gender'.tr(),
                  icon: Icons.wc_outlined,
                ),
                items: [
                  DropdownMenuItem(
                    value: '0',
                    child: Text('contact_male'.tr()),
                  ),
                  DropdownMenuItem(
                    value: '1',
                    child: Text('contact_female'.tr()),
                  ),
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
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton.icon(
                  onPressed: _savingProfile ? null : _saveProfile,
                  icon: _savingProfile
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text('me_profile_save'.tr()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordForm(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        Form(
          key: _pwdFormKey,
          child: Column(
            children: [
              TextFormField(
                controller: _oldPwdController,
                obscureText: !_showOldPwd,
                decoration: _pwdDeco(
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
                decoration: _pwdDeco(
                  context,
                  label: 'me_password_new'.tr(),
                  visible: _showNewPwd,
                  onToggle: () => setState(() => _showNewPwd = !_showNewPwd),
                ),
                validator: (v) {
                  if ((v ?? '').isEmpty) {
                    return 'me_password_new_required'.tr();
                  }
                  if ((v ?? '').length < 6) return 'me_password_new_len'.tr();
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPwdController,
                obscureText: !_showConfirmPwd,
                decoration: _pwdDeco(
                  context,
                  label: 'me_password_confirm'.tr(),
                  visible: _showConfirmPwd,
                  onToggle: () =>
                      setState(() => _showConfirmPwd = !_showConfirmPwd),
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
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton.tonalIcon(
                  onPressed: _updatingPwd ? null : _updatePassword,
                  icon: _updatingPwd
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onSecondaryContainer,
                          ),
                        )
                      : const Icon(Icons.lock_reset_outlined, size: 18),
                  label: Text('me_password_submit'.tr()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDeco(
    BuildContext context, {
    required String label,
    required IconData icon,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 19),
      filled: true,
      fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.primary, width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  InputDecoration _pwdDeco(
    BuildContext context, {
    required String label,
    required bool visible,
    required VoidCallback onToggle,
  }) {
    return _inputDeco(
      context,
      label: label,
      icon: Icons.lock_outline_rounded,
    ).copyWith(
      suffixIcon: IconButton(
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
        Toast.showToast(
          'me_profile_save_success'.tr(),
          type: ToastType.success,
        );
      } else {
        final msg =
            (res.data is Map ? res.data['msg']?.toString() : null) ?? '';
        Toast.showToast(
          msg.isNotEmpty ? msg : 'me_profile_save_failed'.tr(),
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
        Toast.showToast(
          'me_password_update_success'.tr(),
          type: ToastType.success,
        );
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
      if (mounted) setState(() => _updatingPwd = false);
    }
  }
}
