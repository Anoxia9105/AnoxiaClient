import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/framework/domain/UserInfo.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'change_password_page.dart';
import 'personal_qr_page.dart';

/// 个人中心页面
///
/// 支持用户查看和编辑个人信息、修改密码等功能
class MyPage extends ConsumerStatefulWidget {
  const MyPage({super.key});

  @override
  ConsumerState<MyPage> createState() => _MyPageState();
}

class _MyPageState extends ConsumerState<MyPage> {
  /// 昵称编辑控制器
  final _nickController = TextEditingController();

  /// 邮箱编辑控制器
  final _emailController = TextEditingController();

  /// 手机号编辑控制器
  final _phoneController = TextEditingController();

  /// 性别（0=男，1=女，2=未知）
  String _sex = '2';

  /// 用户信息快照（用于检测变化）
  String? _boundUserSnapshot;

  /// 是否正在保存个人资料
  bool _savingProfile = false;

  @override
  void dispose() {
    _nickController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
      appBar: AppBar(
        title: Text('me_page_title'.tr()),
        actions: [
          authAsync.maybeWhen(
            data: (user) {
              if (user == null) return const SizedBox.shrink();
              return IconButton(
                tooltip: '我的二维码',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PersonalQrPage(user: user),
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code_2_rounded),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
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
                child: _buildProfileForm(context, user),
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
        _buildSectionTitle(context, 'me_profile_edit_title'.tr()),
        const SizedBox(height: 8),
        _buildTileSection(
          context,
          children: [
            _buildReadonlyTile(
              context,
              title: 'me_profile_username'.tr(),
              value: user.userName,
              icon: Icons.person_outline_rounded,
            ),
            _buildTileDivider(context),
            _buildEditableTile(
              context,
              title: 'me_profile_nickname'.tr(),
              value: _nickController.text,
              icon: Icons.badge_outlined,
              onTap: () => _editTextField(
                title: 'me_profile_nickname'.tr(),
                controller: _nickController,
                validator: (v) => (v ?? '').trim().isEmpty
                    ? 'me_profile_nickname_required'.tr()
                    : null,
              ),
            ),
            _buildTileDivider(context),
            _buildEditableTile(
              context,
              title: 'me_profile_email'.tr(),
              value: _emailController.text,
              icon: Icons.email_outlined,
              onTap: () => _editTextField(
                title: 'me_profile_email'.tr(),
                controller: _emailController,
              ),
            ),
            _buildTileDivider(context),
            _buildEditableTile(
              context,
              title: 'me_profile_phone'.tr(),
              value: _phoneController.text,
              icon: Icons.phone_outlined,
              onTap: () => _editTextField(
                title: 'me_profile_phone'.tr(),
                controller: _phoneController,
              ),
            ),
            _buildTileDivider(context),
            _buildEditableTile(
              context,
              title: 'me_profile_gender'.tr(),
              value: _genderLabel(),
              icon: Icons.wc_outlined,
              onTap: _selectGender,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionTitle(context, 'me_password_title'.tr()),
        const SizedBox(height: 8),
        _buildTileSection(
          context,
          children: [
            _buildEditableTile(
              context,
              title: 'me_password_submit'.tr(),
              value: '前往修改',
              icon: Icons.lock_outline_rounded,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
                );
              },
            ),
          ],
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
    );
  }

  Widget _buildTileSection(
    BuildContext context, {
    required List<Widget> children,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: children),
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

  Widget _buildReadonlyTile(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      minVerticalPadding: 14,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: Icon(icon, size: 20, color: cs.onSurfaceVariant),
      title: Text(title, style: const TextStyle(fontSize: 14.5)),
      trailing: Text(
        value.isEmpty ? '--' : value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: cs.onSurfaceVariant),
      ),
    );
  }

  Widget _buildEditableTile(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      minVerticalPadding: 14,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: Icon(icon, size: 20, color: cs.onSurfaceVariant),
      title: Text(title, style: const TextStyle(fontSize: 14.5)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              value.isEmpty ? '--' : value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, size: 20, color: cs.outline),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildTileDivider(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Divider(
      height: 1,
      indent: 50,
      endIndent: 14,
      color: cs.outlineVariant.withValues(alpha: 0.5),
    );
  }

  String _genderLabel() {
    switch (_sex) {
      case '0':
        return 'contact_male'.tr();
      case '1':
        return 'contact_female'.tr();
      default:
        return 'contact_unknown_gender'.tr();
    }
  }

  Future<void> _selectGender() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('contact_male'.tr()),
                onTap: () => Navigator.of(ctx).pop('0'),
              ),
              ListTile(
                title: Text('contact_female'.tr()),
                onTap: () => Navigator.of(ctx).pop('1'),
              ),
              ListTile(
                title: Text('contact_unknown_gender'.tr()),
                onTap: () => Navigator.of(ctx).pop('2'),
              ),
            ],
          ),
        );
      },
    );
    if (selected != null && mounted) {
      setState(() => _sex = selected);
    }
  }

  Future<void> _editTextField({
    required String title,
    required TextEditingController controller,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) async {
    final temp = TextEditingController(text: controller.text);
    String? error;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setInnerState) {
            return AlertDialog(
              title: Text(title),
              content: TextField(
                controller: temp,
                autofocus: true,
                obscureText: obscureText,
                decoration: InputDecoration(errorText: error),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('cancel'.tr()),
                ),
                TextButton(
                  onPressed: () {
                    final check = validator?.call(temp.text);
                    if (check != null) {
                      setInnerState(() => error = check);
                      return;
                    }
                    Navigator.of(ctx).pop(temp.text);
                  },
                  child: Text('confirm'.tr()),
                ),
              ],
            );
          },
        );
      },
    );

    temp.dispose();

    if (result != null && mounted) {
      setState(() => controller.text = result.trim());
    }
  }

  Future<void> _saveProfile() async {
    if (_nickController.text.trim().isEmpty) {
      Toast.showToast(
        'me_profile_nickname_required'.tr(),
        type: ToastType.error,
      );
      return;
    }
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
}
