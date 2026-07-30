import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupAnnouncementDetailPage extends ConsumerWidget {
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
