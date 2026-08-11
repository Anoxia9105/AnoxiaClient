import 'dart:typed_data';
import 'package:anoxia/framework/provider/theme/theme_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_item_card.dart';

/// 设置-背景图区块
///
/// 提供自定义背景图（皮肤）功能，仅桌面端和 Web 端显示。
class SettingsBackgroundSection extends ConsumerWidget {
  const SettingsBackgroundSection({super.key});

  Future<void> _pickBackground(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    Uint8List? bytes;
    if (file.bytes != null && file.bytes!.isNotEmpty) {
      bytes = Uint8List.fromList(file.bytes!);
    }

    if (bytes == null || bytes.isEmpty) return;

    await ref.read(backgroundImageProvider.notifier).setFromBytes(bytes);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('settings_bg_image_set_success'.tr())),
      );
    }
  }

  Future<void> _clearBackground(WidgetRef ref) async {
    await ref.read(backgroundImageProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasBackground =
        ref.watch(backgroundImageProvider) != null;

    return SettingItemCard(
      title: 'settings_bg_image_title'.tr(),
      subtitle: 'settings_bg_image_subtitle'.tr(),
      icon: HugeIcons.strokeRoundedImage01,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _pickBackground(context, ref),
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedImageAdd01,
                size: 18,
              ),
              label: Text('settings_bg_image_pick'.tr()),
            ),
          ),
          if (hasBackground) ...[
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _clearBackground(ref),
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedDelete02,
                  size: 18,
                ),
                label: Text('settings_bg_image_clear'.tr()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
