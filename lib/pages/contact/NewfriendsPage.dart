import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/common/widgets/SkeletonBox.dart';
import 'package:anoxia/framework/provider/contact/contact_requests_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
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
      appBar: AppBar(title: Text('contact_new_friends_title'.tr())),
      body: requestAsync.when(
        data: (req) {
          return ListView.separated(
            itemBuilder: (context, index) {
              final request = req[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 1. 左侧头像
                    AvatarWidget(url: request.avatar, name: request.nickName),
                    const SizedBox(width: 12), // 间隔
                    /// 2. 中间内容区
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.nickName ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
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
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
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
        loading: () => const _NewFriendsSkeleton(),
        error: (err, stack) => Center(
          child: Text('${'contact_load_failed_with_error'.tr()}: $err'),
        ),
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
            tooltip: "contact_accept".tr(),
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
            tooltip: "contact_reject".tr(),
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
      return Text('contact_request_accepted'.tr());
    }
    return Text('contact_request_rejected'.tr());
  }
}

class _NewFriendsSkeleton extends StatelessWidget {
  const _NewFriendsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 8,
      padding: const EdgeInsets.symmetric(vertical: 6),
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final nickWidth = 75.0 + (index % 4) * 18;
        final remarkWidth = 140.0 + (index % 3) * 26;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonBox(width: 40, height: 40, radius: 8),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLine(width: nickWidth, height: 14),
                    const SizedBox(height: 8),
                    SkeletonLine(width: remarkWidth, height: 11),
                    const SizedBox(height: 6),
                    const SkeletonLine(width: 110, height: 10),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              index.isEven
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SkeletonBox(width: 28, height: 28, circle: true),
                        SizedBox(width: 8),
                        SkeletonBox(width: 28, height: 28, circle: true),
                      ],
                    )
                  : const SkeletonBox(width: 58, height: 26, radius: 14),
            ],
          ),
        );
      },
    );
  }
}
