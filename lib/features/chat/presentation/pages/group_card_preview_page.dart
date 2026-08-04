/// 群组卡片预览页面，用于在加入群组前预览群组信息。
///
/// 展示群组名称、头像、简介、管理员列表，并根据群组的加入策略和当前状态
/// 提供加入、申请加入或直接进入群组的操作入口。
import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/framework/domain/group_preview.dart';
import 'package:anoxia/framework/provider/chat/room/group_join_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/layout/layout_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 群组卡片预览页面组件。
///
/// 通过 [roomId] 获取群组预览信息，展示群组详情并根据用户状态提供相应操作。
class GroupCardPreviewPage extends ConsumerStatefulWidget {
  /// 群组房间 ID。
  final String roomId;

  const GroupCardPreviewPage({super.key, required this.roomId});

  @override
  ConsumerState<GroupCardPreviewPage> createState() =>
      _GroupCardPreviewPageState();
}

class _GroupCardPreviewPageState extends ConsumerState<GroupCardPreviewPage> {
  late Future<GroupPreview> _future = _preview();
  bool _busy = false;

  Future<GroupPreview> _preview() {
    return ref.read(groupJoinServiceProvider).preview(widget.roomId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('group_card_preview_title'.tr())),
    body: FutureBuilder<GroupPreview>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _Unavailable(
            onRetry: () => setState(() => _future = _preview()),
          );
        }
        final group = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: AvatarWidget(
                url: group.avatar,
                name: group.name,
                size: 96,
                borderRadius: 16,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              group.name,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'group_card_member_count'.tr(
                args: [group.memberCount.toString()],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ListTile(
              title: Text('group_card_description'.tr()),
              subtitle: Text(
                group.description.isEmpty
                    ? 'group_card_no_description'.tr()
                    : group.description,
              ),
            ),
            ListTile(
              title: Text('group_card_managers'.tr()),
              subtitle: Text(
                group.managers
                    .map((e) => e.name)
                    .where((e) => e.isNotEmpty)
                    .join('、'),
              ),
            ),
            const SizedBox(height: 24),
            if (!group.joinable)
              FilledButton(
                onPressed: null,
                child: Text('group_card_unavailable'.tr()),
              )
            else if (group.member)
              FilledButton(
                onPressed: () => _openRoom(group.roomId),
                child: Text('group_card_enter'.tr()),
              )
            else if (group.pendingRequest)
              FilledButton(
                onPressed: null,
                child: Text('group_card_pending'.tr()),
              )
            else
              FilledButton(
                onPressed: _busy ? null : () => _join(group),
                child: Text(
                  group.joinPolicy == 0
                      ? 'group_card_join'.tr()
                      : 'group_card_apply'.tr(),
                ),
              ),
          ],
        );
      },
    ),
  );

  /// 加入群组。
  ///
  /// 如果群组需要验证（[group.joinPolicy] != 0），会弹出验证信息输入对话框。
  /// 加入成功后自动跳转到群组聊天页面。
  Future<void> _join(GroupPreview group) async {
    var message = '';
    if (group.joinPolicy != 0) {
      final controller = TextEditingController();
      final result = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('group_card_verify_title'.tr()),
          content: TextField(
            controller: controller,
            maxLength: 200,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'group_card_verify_hint'.tr(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('dialog_cancel'.tr()),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: Text('add_friend_send'.tr()),
            ),
          ],
        ),
      );
      controller.dispose();
      if (result == null) return;
      message = result;
    }
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(groupJoinServiceProvider)
          .join(group.roomId, verificationMessage: message);
      if (!mounted) return;
      if (result == 'JOINED' || result == 'ALREADY_MEMBER') {
        await ref.read(roomListServiceProvider.notifier).refresh(silent: true);
        _openRoom(group.roomId);
      } else {
        setState(() => _future = _preview());
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('group_card_join_failed'.tr())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// 打开群组聊天房间。
  ///
  /// 设置当前活跃房间并跳转到聊天页面。
  void _openRoom(String roomId) {
    ref.read(activeRoomIdProvider.notifier).setActive(roomId);
    ref.read(layoutControllerProvider.notifier).setIndex(0);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

/// 群组不可用时的占位组件。
///
/// 展示群组不可用的提示信息，并提供重试按钮。
class _Unavailable extends StatelessWidget {
  /// 重试回调。
  final VoidCallback onRetry;

  const _Unavailable({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('group_card_unavailable'.tr()),
        TextButton(onPressed: onRetry, child: Text('retry'.tr())),
      ],
    ),
  );
}