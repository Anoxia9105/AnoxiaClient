import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/domain/user_vo.dart';
import 'package:anoxia/framework/provider/contact/user_search_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 发送好友申请对话框
///
/// 展示目标用户简要信息并提供验证消息输入
class AddFriendDialog extends ConsumerStatefulWidget {
  final UserVO user;

  const AddFriendDialog({super.key, required this.user});

  /// 显示对话框并返回发送结果。
  ///
  /// 返回 `true` 表示发送成功，`false` 表示发送失败，`null` 表示用户取消。
  static Future<bool?> show(BuildContext context, UserVO user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AddFriendDialog(user: user),
    );
    return result;
  }

  @override
  ConsumerState<AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends ConsumerState<AddFriendDialog> {
  final TextEditingController _remarkController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final user = widget.user;

return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 8,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.14),
      backgroundColor: colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'add_friend_request_title'.tr(),
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'close'.tr(),
                    onPressed: _isSending
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    AvatarWidget(
                      url: user.avatar,
                      name: user.nickName,
                      size: 52,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.nickName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'add_friend_username'.tr(args: [user.userName]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if ((user.phonenumber ?? '').isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'add_friend_phone'.tr(
                                args: [user.phonenumber!],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'add_friend_verify_label'.tr(),
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'add_friend_verify_optional'.tr(),
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _remarkController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'add_friend_verify_hint'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHigh,
                ),
                minLines: 3,
                maxLines: 4,
                maxLength: 100,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isSending
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('add_friend_cancel'.tr()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSending ? null : _send,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSending
                          ? SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : Text('add_friend_send'.tr()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _send() async {
    setState(() => _isSending = true);
    final success = await ref
        .read(userSearchServiceProvider.notifier)
        .sendContactRequest(
          widget.user.userId,
          _remarkController.text.trim(),
        );
    if (!mounted) return;

    Navigator.of(context).pop(success);
  }
}
