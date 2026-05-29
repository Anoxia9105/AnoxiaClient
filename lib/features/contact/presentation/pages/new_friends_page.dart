import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/features/contact/presentation/widgets/new_friends_widgets.dart';
import 'package:anoxia/framework/provider/contact/contact_requests_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 新好友请求页面
///
/// 显示待处理的好友请求列表，支持：
/// - 展示好友请求（头像、昵称、验证消息、时间）
/// - 接受好友请求
/// - 拒绝好友请求
/// - 加载状态显示
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
      backgroundColor: DeviceUtil.isRealDesktop()
          ? Colors.transparent
          : Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: Text('contact_new_friends_title'.tr())),
      body: requestAsync.when(
        data: (req) {
          return ListView.separated(
            itemBuilder: (context, index) {
              final request = req[index];
              return NewFriendsRequestTile(
                avatar: request.avatar ?? '',
                nickName: request.nickName ?? '',
                remark: request.requestRemark ?? '',
                createdAtText: request.createdAt.toString(),
                trailing: NewFriendsStatusButtons(
                  status: request.status,
                  onAccept: () => ref
                      .read(contactRequestsServiceProvider.notifier)
                      .acceptRequest(request.id ?? 0, true),
                  onReject: () => ref
                      .read(contactRequestsServiceProvider.notifier)
                      .acceptRequest(request.id ?? 0, false),
                ),
              );
            },
            itemCount: req.length,
            separatorBuilder: (BuildContext context, int index) =>
                const Divider(),
          );
        },
        loading: () => const NewFriendsSkeleton(),
        error: (err, stack) => Center(
          child: Text('${'contact_load_failed_with_error'.tr()}: $err'),
        ),
      ),
    );
  }
}
