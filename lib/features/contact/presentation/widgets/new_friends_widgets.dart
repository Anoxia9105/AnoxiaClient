import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/common/widgets/SkeletonBox.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class NewFriendsRequestTile extends StatelessWidget {
  final String avatar;
  final String nickName;
  final String remark;
  final String createdAtText;
  final Widget trailing;

  const NewFriendsRequestTile({
    super.key,
    required this.avatar,
    required this.nickName,
    required this.remark,
    required this.createdAtText,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarWidget(url: avatar, name: nickName),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  remark,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  createdAtText,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

class NewFriendsStatusButtons extends StatelessWidget {
  final int? status;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const NewFriendsStatusButtons({
    super.key,
    required this.status,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (status == null) return const SizedBox.shrink();

    if (status == 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'contact_accept'.tr(),
            onPressed: onAccept,
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedCheckmarkCircle02,
              color: Theme.of(context).colorScheme.primary,
              strokeWidth: 3,
            ),
          ),
          IconButton(
            tooltip: 'contact_reject'.tr(),
            onPressed: onReject,
            icon: const HugeIcon(
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

class NewFriendsSkeleton extends StatelessWidget {
  const NewFriendsSkeleton({super.key});

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
