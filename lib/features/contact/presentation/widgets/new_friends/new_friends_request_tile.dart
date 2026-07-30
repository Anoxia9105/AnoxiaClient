import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:flutter/material.dart';

/// 好友请求列表项组件
///
/// 显示单个好友请求的头像、昵称、验证消息和时间
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
