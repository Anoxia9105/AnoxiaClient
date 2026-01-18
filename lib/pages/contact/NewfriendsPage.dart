import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/framework/services/contact_requests_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

class NewFriendsPage extends ConsumerStatefulWidget {
  const NewFriendsPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _NewFriendsPageState();
}

class _NewFriendsPageState extends ConsumerState<NewFriendsPage> {
  @override
  Widget build(BuildContext context) {
    final requestAsync = ref.watch(contactRequestsServiceProvider);
    return Scaffold(
      appBar: AppBar(title: Text("新的朋友")),
      body: requestAsync.when(
        data: (req) {
          return ListView.separated(
            itemBuilder: (context, index) {
              final request = req[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 1. 左侧头像
                    AvatarWidget(
                      url: request.avatar,
                      name: request.nickName,
                    ),
                    const SizedBox(width: 12), // 间隔

                    /// 2. 中间内容区
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.nickName ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          // 备注文本
                          Text(
                            request.requestRemark ?? '',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          // 时间
                          Text(
                            request.createdAt.toString(),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                    /// 3. 右侧按钮区
                    const SizedBox(width: 8),
                    _buildStatusButtons(request.id ?? 0, request.status),
                  ],
                ),
              );
            },
            itemCount: req.length,
            separatorBuilder: (BuildContext context, int index) => Divider(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('加载失败: $err')),
      ),
    );
  }

  //0-待处理 1-已接受 2-已拒绝
  Widget _buildStatusButtons(int id, int? status) {
    if (status == null) return SizedBox.shrink();

    if (status == 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: "同意",
            onPressed: () => ref
                .read(contactRequestsServiceProvider.notifier)
                .acceptRequest(id, true),
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedCheckmarkCircle02,
              color: Theme.of(context).colorScheme.primary,
              strokeWidth: 3,
            ),
          ),
          IconButton(
            tooltip: "拒绝",
            onPressed: () => ref
                .read(contactRequestsServiceProvider.notifier)
                .acceptRequest(id, false),
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedCancelCircle,
              color: Colors.red,
              strokeWidth: 3,
            ),
          ),
        ],
      );
    }
    if (status == 1) {
      return Text("已同意");
    }
    return Text("已拒绝");
  }
}
