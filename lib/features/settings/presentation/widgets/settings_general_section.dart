import 'package:anoxia/framework/provider/setting/hide_official_room_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

/// 设置页「通用」分区
///
/// 目前包含「隐藏官方虚拟房间」开关。
class SettingsGeneralSection extends ConsumerWidget {
  const SettingsGeneralSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(hideOfficialRoomProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: ListTile(
        leading: const HugeIcon(
          icon: HugeIcons.strokeRoundedMegaphone01,
          size: 22,
        ),
        title: Text('settings_hide_official_room'.tr()),
        subtitle: Text('settings_hide_official_room_desc'.tr()),
        trailing: Transform.scale(
          scale: 0.85,
          child: Switch.adaptive(
            value: hidden,
            onChanged: (value) {
              ref.read(hideOfficialRoomProvider.notifier).setHidden(value);
            },
          ),
        ),
        onTap: () {
          ref.read(hideOfficialRoomProvider.notifier).setHidden(!hidden);
        },
      ),
    );
  }
}
