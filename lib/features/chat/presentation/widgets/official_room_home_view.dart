import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';

/// 官方虚拟房间中间区（纯展示）
///
/// 替代消息流与输入框：展示欢迎信息，并引导用户打开右侧帮助面板。
class OfficialRoomHomeView extends ConsumerWidget {
  const OfficialRoomHomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.primary.withValues(alpha: 0.92),
                  color.primary.withValues(alpha: 0.6),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedMegaphone01,
              size: 44,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'official_room_welcome_title'.tr(),
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'official_room_welcome_desc'.tr(),
            style: textTheme.bodyMedium?.copyWith(
              color: color.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () {
              ref.read(chatRightPanelVisibleProvider.notifier).state = true;
            },
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedInformationCircle,
              size: 18,
            ),
            label: Text('official_room_open_help'.tr()),
          ),
        ],
      ),
    );
  }
}
