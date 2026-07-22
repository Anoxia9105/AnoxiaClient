import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/framework/provider/chat/room/group_join_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class GroupJoinRequestsPage extends StatefulWidget {
  final String roomId;
  const GroupJoinRequestsPage({super.key, required this.roomId});
  @override
  State<GroupJoinRequestsPage> createState() => _GroupJoinRequestsPageState();
}

class _GroupJoinRequestsPageState extends State<GroupJoinRequestsPage> {
  late Future<List<Map<String, dynamic>>> _future = GroupJoinService.requests(
    widget.roomId,
  );
  void _reload() =>
      setState(() => _future = GroupJoinService.requests(widget.roomId));
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('group_join_requests_title'.tr())),
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
  Future<void> _handle(Map<String, dynamic> row, bool approved) async {
    try {
      await GroupJoinService.handleRequest(
        int.parse(row['id'].toString()),
        approved,
      );
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
