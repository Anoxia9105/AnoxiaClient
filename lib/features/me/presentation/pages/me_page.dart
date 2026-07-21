import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/framework/domain/UserInfo.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'change_password_page.dart';
import 'me_profile_item_edit_page.dart';
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
        centerTitle: DeviceUtil.isRealMobile(),
        title: Text('me_page_title'.tr()),
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        _buildTopProfileRow(context, user),
        const SizedBox(height: 16),
        _buildSectionTitle(context, 'me_profile_edit_title'.tr()),
        const SizedBox(height: 8),
        _buildTileSection(
          context,
          children: [
            _buildEditableTile(
              context,
              title: 'me_profile_nickname'.tr(),
              value: _nickController.text,
              icon: Icons.badge_outlined,
              onTap: () => _editTextItem(
                context,
                title: 'me_profile_nickname'.tr(),
                initialValue: _nickController.text,
                requiredMessage: 'me_profile_nickname_required'.tr(),
                onSave: (value) => _saveProfile(nickName: value),
                onApplied: (value) => _nickController.text = value,
              ),
            ),
            _buildTileDivider(context),
            _buildEditableTile(
              context,
              title: 'me_profile_email'.tr(),
              value: _emailController.text,
              icon: Icons.email_outlined,
              onTap: () => _editTextItem(
                context,
                title: 'me_profile_email'.tr(),
                initialValue: _emailController.text,
                keyboardType: TextInputType.emailAddress,
                onSave: (value) => _saveProfile(email: value),
                onApplied: (value) => _emailController.text = value,
              ),
            ),
            _buildTileDivider(context),
            _buildEditableTile(
              context,
              title: 'me_profile_phone'.tr(),
              value: _phoneController.text,
              icon: Icons.phone_outlined,
              onTap: () => _editTextItem(
                context,
                title: 'me_profile_phone'.tr(),
                initialValue: _phoneController.text,
                keyboardType: TextInputType.phone,
                onSave: (value) => _saveProfile(phoneNumber: value),
                onApplied: (value) => _phoneController.text = value,
              ),
            ),
            _buildTileDivider(context),
            _buildEditableTile(
              context,
              title: 'me_profile_gender'.tr(),
              value: _genderLabel(),
              icon: Icons.wc_outlined,
              onTap: () => _editSelectItem(
                context,
                title: 'me_profile_gender'.tr(),
                initialValue: _sex,
                options: [
                  MeProfileEditOption(value: '0', label: 'contact_male'.tr()),
                  MeProfileEditOption(value: '1', label: 'contact_female'.tr()),
                  MeProfileEditOption(
                    value: '2',
                    label: 'contact_unknown_gender'.tr(),
                  ),
                ],
                onSave: (value) => _saveProfile(sex: value),
                onApplied: (value) => _sex = value,
              ),
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
              value: 'common_go_edit'.tr(),
              icon: Icons.lock_outline_rounded,
              onTap: () {
                if (DeviceUtil.isRealDesktop()) {
                  showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const ChangePasswordDialog(),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordPage(),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopProfileRow(BuildContext context, UserInfo user) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          AvatarWidget(
            url: user.avatar,
            name: user.nickName,
            size: 48,
            borderRadius: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.nickName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${'me_profile_username'.tr()}: ${user.userName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'me_my_qr'.tr(),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PersonalQrPage(user: user)),
              );
            },
            icon: const Icon(Icons.qr_code_2_rounded),
          ),
        ],
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

  Future<void> _editTextItem(
    BuildContext context, {
    required String title,
    required String initialValue,
    required Future<bool> Function(String value) onSave,
    required void Function(String value) onApplied,
    String? requiredMessage,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final String? result;
    if (DeviceUtil.isRealDesktop()) {
      result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => MeProfileItemEditDialog.text(
          title: title,
          initialValue: initialValue,
          requiredMessage: requiredMessage,
          keyboardType: keyboardType,
          onSave: onSave,
        ),
      );
    } else {
      result = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => MeProfileItemEditPage.text(
            title: title,
            initialValue: initialValue,
            requiredMessage: requiredMessage,
            keyboardType: keyboardType,
            onSave: onSave,
          ),
        ),
      );
    }
    if (result != null && mounted) {
      setState(() => onApplied(result!));
    }
  }

  Future<void> _editSelectItem(
    BuildContext context, {
    required String title,
    required String initialValue,
    required List<MeProfileEditOption> options,
    required Future<bool> Function(String value) onSave,
    required void Function(String value) onApplied,
  }) async {
    final String? result;
    if (DeviceUtil.isRealDesktop()) {
      result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => MeProfileItemEditDialog.select(
          title: title,
          initialValue: initialValue,
          options: options,
          onSave: onSave,
        ),
      );
    } else {
      result = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => MeProfileItemEditPage.select(
            title: title,
            initialValue: initialValue,
            options: options,
            onSave: onSave,
          ),
        ),
      );
    }
    if (result != null && mounted) {
      setState(() => onApplied(result!));
    }
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

  Future<bool> _saveProfile({
    String? nickName,
    String? email,
    String? phoneNumber,
    String? sex,
  }) async {
    if (_savingProfile) return false;

    final effectiveNick = (nickName ?? _nickController.text).trim();
    final effectiveEmail = (email ?? _emailController.text).trim();
    final effectivePhone = (phoneNumber ?? _phoneController.text).trim();
    final effectiveSex = sex ?? _sex;

    if (effectiveNick.isEmpty) {
      Toast.showToast(
        'me_profile_nickname_required'.tr(),
        type: ToastType.error,
      );
      return false;
    }

    setState(() => _savingProfile = true);
    try {
      final res = await DioClient().put(
        API.userProfileUpdate,
        data: {
          'nickName': effectiveNick,
          'email': effectiveEmail,
          'phonenumber': effectivePhone,
          'sex': effectiveSex,
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
      return ok;
    } catch (_) {
      Toast.showToast('me_profile_save_failed'.tr(), type: ToastType.error);
      return false;
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }
}
