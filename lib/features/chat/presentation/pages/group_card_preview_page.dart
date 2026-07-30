import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/framework/domain/group_preview.dart';
import 'package:anoxia/framework/provider/chat/room/group_join_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/layout/layout_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupCardPreviewPage extends ConsumerStatefulWidget {
  final String roomId;
  const GroupCardPreviewPage({super.key, required this.roomId});
  @override
  ConsumerState<GroupCardPreviewPage> createState() =>
      _GroupCardPreviewPageState();
}

class _GroupCardPreviewPageState extends ConsumerState<GroupCardPreviewPage> {
  late Future<GroupPreview> _future = GroupJoinService.preview(widget.roomId);
  bool _busy = false;

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
            onRetry: () => setState(
              () => _future = GroupJoinService.preview(widget.roomId),
            ),
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
            maxLength: 100,
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
      final result = await GroupJoinService.join(
        group.roomId,
        verificationMessage: message,
      );
      if (!mounted) return;
      if (result == 'JOINED' || result == 'ALREADY_MEMBER') {
        await ref.read(roomListServiceProvider.notifier).refresh(silent: true);
        _openRoom(group.roomId);
      } else {
        setState(() => _future = GroupJoinService.preview(group.roomId));
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

  void _openRoom(String roomId) {
    ref.read(activeRoomIdProvider.notifier).setActive(roomId);
    ref.read(layoutControllerProvider.notifier).setIndex(0);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class _Unavailable extends StatelessWidget {
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
