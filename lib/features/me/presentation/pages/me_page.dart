import 'package:anoxia/common/constants/api.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/common/widgets/skeleton_box.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/framework/domain/user_info.dart';
import 'package:anoxia/framework/network/dio_client.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'change_password_page.dart';
import 'avatar_edit_dialog.dart';
import 'avatar_edit_page.dart';
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
        centerTitle: DeviceUtil.isMobile(context),
        title: Text('me_page_title'.tr()),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: authAsync.when(
        loading: () => const _MePageSkeleton(),
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
            _buildAvatarTile(context),
            _buildTileDivider(context),
            _buildEditableTile(
              context,
              title: 'me_profile_nickname'.tr(),
              value: _nickController.text,
              icon: HugeIcons.strokeRoundedBadge,
              onTap: () => _editTextItem(
                context,
                title: 'me_profile_nickname'.tr(),
                initialValue: _nickController.text,
                requiredMessage: 'me_profile_nickname_required'.tr(),
                maxLength: 30,
                onSave: (value) => _saveProfile(nickName: value),
                onApplied: (value) => _nickController.text = value,
              ),
            ),
            _buildTileDivider(context),
            _buildEditableTile(
              context,
              title: 'me_profile_email'.tr(),
              value: _emailController.text,
              icon: HugeIcons.strokeRoundedMail01,
              onTap: () => _editTextItem(
                context,
                title: 'me_profile_email'.tr(),
                initialValue: _emailController.text,
                keyboardType: TextInputType.emailAddress,
                maxLength: 50,
                onSave: (value) => _saveProfile(email: value),
                onApplied: (value) => _emailController.text = value,
              ),
            ),
            _buildTileDivider(context),
            _buildEditableTile(
              context,
              title: 'me_profile_phone'.tr(),
              value: _phoneController.text,
              icon: HugeIcons.strokeRoundedCall,
              onTap: () => _editTextItem(
                context,
                title: 'me_profile_phone'.tr(),
                initialValue: _phoneController.text,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                onSave: (value) => _saveProfile(phoneNumber: value),
                onApplied: (value) => _phoneController.text = value,
              ),
            ),
            _buildTileDivider(context),
            _buildEditableTile(
              context,
              title: 'me_profile_gender'.tr(),
              value: _genderLabel(),
              icon: HugeIcons.strokeRoundedToilet01,
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
              icon: HugeIcons.strokeRoundedLock,
              onTap: () {
                if (!DeviceUtil.isMobile(context)) {
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
          Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _editAvatar(context),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AvatarWidget(url: user.avatar, name: user.nickName, size: 48),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cs.surfaceContainer,
                          width: 1.5,
                        ),
                      ),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedCamera02,
                        size: 13,
                        color: cs.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedQrCode01),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarTile(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      minVerticalPadding: 10,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      leading: const HugeIcon(icon: HugeIcons.strokeRoundedUserCircle, size: 22),
      title: Text('me_avatar'.tr(), style: const TextStyle(fontSize: 14.5)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'me_avatar_change'.tr(),
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5),
          ),
          const SizedBox(width: 4),
          HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 20, color: cs.outline),
        ],
      ),
      onTap: () => _editAvatar(context),
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
    required List<List<dynamic>> icon,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      minVerticalPadding: 14,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: HugeIcon(icon: icon, size: 20, color: cs.onSurfaceVariant),
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
          HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 20, color: cs.outline),
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
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final String? result;
    if (!DeviceUtil.isMobile(context)) {
      result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => MeProfileItemEditDialog.text(
          title: title,
          initialValue: initialValue,
          requiredMessage: requiredMessage,
          keyboardType: keyboardType,
          maxLength: maxLength,
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
            maxLength: maxLength,
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
    if (!DeviceUtil.isMobile(context)) {
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

  /// 打开头像编辑（桌面端对话框，移动端全屏页面）
  Future<void> _editAvatar(BuildContext context) async {
    final bool ok;
    if (!DeviceUtil.isMobile(context)) {
      ok =
          await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (_) => const AvatarEditDialog(),
          ) ??
          false;
    } else {
      ok =
          await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AvatarEditPage()),
          ) ??
          false;
    }
    if (ok && mounted) {
      await ref.read(authControllerProvider.notifier).refreshUserInfo();
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

    if (effectiveNick.length > 30) {
      Toast.showToast('me_profile_nickname_length'.tr(), type: ToastType.error);
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

/// 「我的」页骨架屏
///
/// 模拟真实布局：顶部资料卡 + 分组标题 + 设置行卡片。
class _MePageSkeleton extends StatelessWidget {
  const _MePageSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        _ProfileCardSkeleton(),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: SkeletonLine(width: 96, height: 13),
        ),
        const SizedBox(height: 8),
        const _TileSectionSkeleton(rows: 4),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: SkeletonLine(width: 72, height: 13),
        ),
        const SizedBox(height: 8),
        const _TileSectionSkeleton(rows: 1),
      ],
    );
  }
}

/// 顶部资料卡骨架（头像 + 昵称/用户名 + 二维码入口）
class _ProfileCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          SkeletonBox(width: 48, height: 48, circle: true),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SkeletonLine(width: 120, height: 15),
                SizedBox(height: 6),
                SkeletonLine(width: 90, height: 11),
              ],
            ),
          ),
          SkeletonBox(width: 24, height: 24, radius: 6, margin: EdgeInsets.only(left: 8)),
        ],
      ),
    );
  }
}

/// 设置行卡片骨架（图标 + 标题 + 值 + 箭头）
class _TileSectionSkeleton extends StatelessWidget {
  final int rows;

  const _TileSectionSkeleton({required this.rows});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainer,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          for (var i = 0; i < rows; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 50,
                endIndent: 14,
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: Row(
                children: [
                  const SkeletonBox(width: 20, height: 20, radius: 5),
                  const SizedBox(width: 16),
                  const SkeletonLine(width: 64, height: 13),
                  const Spacer(),
                  SkeletonBox(width: 88 - (i % 3) * 18, height: 12, radius: 4),
                  const SizedBox(width: 8),
                  const SkeletonBox(width: 18, height: 18, radius: 5),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
