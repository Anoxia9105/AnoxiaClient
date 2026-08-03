/// 群组入群申请管理页面，用于查看和处理群组的入群申请。
///
/// 展示所有待处理、已批准和已拒绝的入群申请，管理员可以批准或拒绝申请。
import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/framework/provider/chat/room/group_join_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 群组入群申请管理页面。
///
/// 通过 [roomId] 指定目标群组，加载并展示该群组的入群申请列表。
class GroupJoinRequestsPage extends ConsumerStatefulWidget {
  /// 群组房间 ID。
  final String roomId;

  const GroupJoinRequestsPage({super.key, required this.roomId});

  @override
  ConsumerState<GroupJoinRequestsPage> createState() =>
      _GroupJoinRequestsPageState();
}

class _GroupJoinRequestsPageState extends ConsumerState<GroupJoinRequestsPage> {
  late Future<List<Map<String, dynamic>>> _future = _requests();

  Future<List<Map<String, dynamic>>> _requests() {
    return ref.read(groupJoinServiceProvider).requests(widget.roomId);
  }

  /// 重新加载入群申请列表。
  void _reload() => setState(() => _future = _requests());

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).colorScheme.surface,
    appBar: AppBar(
      title: Text('group_join_requests_title'.tr()),
      centerTitle: DeviceUtil.isRealMobile(),
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: TextButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              label: Text('chat_operation_retry_failed'.tr()),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snapshot.data!;
        if (rows.isEmpty) {
          return Center(child: Text('group_join_requests_empty'.tr()));
        }
        return ListView.separated(
          itemCount: rows.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final row = rows[i];
            final pending = row['status'] == 0;
            return ListTile(
              leading: AvatarWidget(
                url: row['avatar']?.toString(),
                name: row['nickName']?.toString(),
                size: 42,
              ),
              title: Text(row['nickName']?.toString() ?? ''),
              subtitle: Text(
                row['verificationMessage']?.toString().isNotEmpty == true
                    ? row['verificationMessage'].toString()
                    : 'group_join_requests_no_message'.tr(),
              ),
              trailing: pending
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => _handle(row, false),
                        ),
                        IconButton(
                          icon: const Icon(Icons.check),
                          onPressed: () => _handle(row, true),
                        ),
                      ],
                    )
                  : Text(
                      row['status'] == 1
                          ? 'group_join_requests_approved'.tr()
                          : 'group_join_requests_rejected'.tr(),
                    ),
            );
          },
        );
      },
    ),
  );

  /// 处理入群申请（批准或拒绝）。
  ///
  /// [row] 申请数据行，[approved] 为 true 表示批准，false 表示拒绝。
  Future<void> _handle(Map<String, dynamic> row, bool approved) async {
    try {
      await ref
          .read(groupJoinServiceProvider)
          .handleRequest(int.parse(row['id'].toString()), approved);
      _reload();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('chat_operation_retry_failed'.tr())),
        );
      }
    }
  }
}