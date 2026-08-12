import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../common/utils/device_util.dart';
import '../../../../framework/domain/app_background.dart';
import '../../../../framework/provider/theme/theme_controller.dart';
import 'settings_item_card.dart';

class SettingsBackgroundSection extends ConsumerWidget {
  const SettingsBackgroundSection({super.key});

  Future<void> _pickBackground(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
        'webp',
        'gif',
        if (DeviceUtil.supportsVideoBackground()) ...['mp4', 'webm'],
      ],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes == null ? null : Uint8List.fromList(file.bytes!);
    if (bytes == null || bytes.isEmpty) return;

    final extension = file.extension?.toLowerCase();
    final isVideo = extension == 'mp4' || extension == 'webm';
    final maxBytes = (isVideo ? 100 : 15) * 1024 * 1024;
    if (bytes.length > maxBytes) {
      if (context.mounted) {
        _showMessage(context, 'settings_bg_media_too_large'.tr());
      }
      return;
    }
    try {
      await ref.read(appBackgroundProvider.notifier).upload(bytes, file.name);
      if (context.mounted) {
        _showMessage(context, 'settings_bg_image_set_success'.tr());
      }
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, 'settings_bg_media_upload_failed'.tr());
      }
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appBackgroundProvider);
    final controller = ref.read(appBackgroundProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return SettingItemCard(
      title: 'settings_bg_image_title'.tr(),
      subtitle: 'settings_bg_media_subtitle'.tr(),
      icon: HugeIcons.strokeRoundedImage01,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.uploading
                      ? null
                      : () => _pickBackground(context, ref),
                  icon: state.uploading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const HugeIcon(
                          icon: HugeIcons.strokeRoundedUpload01,
                          size: 18,
                        ),
                  label: Text('settings_bg_media_upload'.tr()),
                ),
              ),
              if (state.activeAsset != null) ...[
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: controller.disable,
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    size: 18,
                  ),
                  label: Text('settings_bg_image_clear'.tr()),
                ),
              ],
            ],
          ),
          if (state.assets.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'settings_bg_media_library'.tr(),
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: state.assets.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final asset = state.assets[index];
                  return _BackgroundAssetTile(
                    asset: asset,
                    selected: asset.id == state.activeAssetId,
                    onSelect: () =>
                        controller.savePreference(activeAssetId: asset.id),
                    onDelete: () => controller.deleteAsset(asset.id),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'settings_bg_surface_opacity'.tr(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text('${(state.surfaceOpacity * 100).round()}%'),
            ],
          ),
          Slider(
            value: state.surfaceOpacity,
            min: AppBackgroundState.minSurfaceOpacity,
            max: AppBackgroundState.maxSurfaceOpacity,
            divisions: 51,
            label: '${(state.surfaceOpacity * 100).round()}%',
            onChanged: state.activeAsset == null
                ? null
                : controller.previewOpacity,
            onChangeEnd: state.activeAsset == null
                ? null
                : (_) => controller.savePreference(),
          ),
          Text(
            'settings_bg_surface_opacity_hint'.tr(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundAssetTile extends StatelessWidget {
  final AppBackgroundAsset asset;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  const _BackgroundAssetTile({
    required this.asset,
    required this.selected,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: asset.name,
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 132,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: asset.type == AppBackgroundMediaType.image
                    ? Image.network(asset.url, fit: BoxFit.cover)
                    : ColoredBox(
                        color: colors.surfaceContainerHighest,
                        child: Center(
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedVideo01,
                            color: colors.primary,
                            size: 28,
                          ),
                        ),
                      ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton.filledTonal(
                  tooltip: 'settings_bg_media_delete'.tr(),
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedDelete02,
                    size: 14,
                  ),
                ),
              ),
              Positioned(
                left: 6,
                right: 6,
                bottom: 5,
                child: Text(
                  asset.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    shadows: const [Shadow(blurRadius: 4)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
