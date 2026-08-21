// 群组入群申请管理页面，用于查看和处理群组的入群申请。
//
// 展示所有待处理、已批准和已拒绝的入群申请，管理员可以批准或拒绝申请。
import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/skeleton_box.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:hugeicons/hugeicons.dart';
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
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedRefresh),
              label: Text('chat_operation_retry_failed'.tr()),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const _JoinRequestsSkeleton();
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
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedCancel01,
                          ),
                          onPressed: () => _handle(row, false),
                        ),
                        IconButton(
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedTick01,
                          ),
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
      // 同步刷新红点徽标
      ref
          .read(groupJoinRequestsServiceProvider(widget.roomId).notifier)
          .refresh(widget.roomId);
      _reload();
    } catch (_) {
      if (mounted) {
        Toast.showToast(
          'chat_operation_retry_failed'.tr(),
          type: ToastType.error,
        );
      }
    }
  }
}

/// 入群申请列表骨架屏
///
/// 模拟真实布局：头像 + 昵称/验证消息 + 尾部操作按钮。
class _JoinRequestsSkeleton extends StatelessWidget {
  const _JoinRequestsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 6,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) => _JoinRequestTileSkeleton(variant: i % 3),
    );
  }
}

/// 单条入群申请骨架
class _JoinRequestTileSkeleton extends StatelessWidget {
  /// 行内文案宽度变体，避免每行完全一致
  final int variant;

  const _JoinRequestTileSkeleton({required this.variant});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const SkeletonBox(width: 42, height: 42, circle: true),
      title: SkeletonLine(width: 96 + variant * 14, height: 13),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: SkeletonLine(width: 150 - variant * 22, height: 11),
      ),
      trailing: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SkeletonBox(width: 22, height: 22, radius: 6, margin: EdgeInsets.only(right: 10)),
          SkeletonBox(width: 22, height: 22, radius: 6),
        ],
      ),
    );
  }
}
