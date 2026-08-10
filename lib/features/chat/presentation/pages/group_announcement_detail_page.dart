// 群组公告详情页面，显示群组的完整公告内容。
//
// 支持文本选择和滚动查看，当公告内容为空时显示占位提示。
import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 群组公告详情页面
///
/// 从 [currentRoomProvider] 中获取房间的公告描述内容，使用 [SelectableText] 展示，
/// 方便用户选择和复制文本。移动端 AppBar 标题居中显示。
class GroupAnnouncementDetailPage extends ConsumerWidget {
  /// 房间 ID
  final String roomId;

  const GroupAnnouncementDetailPage({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final content =
        ref.watch(currentRoomProvider(roomId))?.roomDescription?.trim() ?? '';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text('chat_group_announcement_detail'.tr()),
        centerTitle: DeviceUtil.isRealMobile(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: SelectableText(
          content.isEmpty ? 'chat_group_announcement_empty'.tr() : content,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.65),
        ),
      ),
    );
  }
}
