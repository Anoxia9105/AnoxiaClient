import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../common/utils/device_util.dart';
import '../../../../common/widgets/cached_network_image_view.dart';
import '../../../../common/widgets/toast.dart';
import '../../../../domain/repositories/app_background_repository.dart';
import '../../../../framework/domain/app_background.dart';
import '../../../../framework/provider/theme/theme_controller.dart';
import 'background_video_thumbnail.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

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
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) return;

    final extension = file.extension?.toLowerCase();
    final isVideo = extension == 'mp4' || extension == 'webm';
    final maxBytes = (isVideo ? 100 : 15) * 1024 * 1024;
    if (bytes.length > maxBytes) {
      if (context.mounted) {
        Toast.showToast(
          'settings_bg_media_too_large'.tr(),
          type: ToastType.error,
        );
      }
      return;
    }
    try {
      await ref.read(appBackgroundProvider.notifier).upload(bytes, file.name);
      if (context.mounted) {
        Toast.showToast(
          'settings_bg_image_set_success'.tr(),
          type: ToastType.success,
        );
      }
    } catch (error) {
      if (context.mounted) {
        Toast.showToast(
          error is AppBackgroundException
              ? (error.isLocalizationKey ? error.message.tr() : error.message)
              : 'settings_bg_media_upload_failed'.tr(),
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appBackgroundProvider);
    final controller = ref.read(appBackgroundProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
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
                label: Text(
                  state.uploading
                      ? (state.uploadProgress ?? 0) >=
                                AppBackgroundState.transferProgressWeight
                            ? 'settings_bg_media_saving'.tr()
                            : 'settings_bg_media_uploading'.tr(
                                args: [
                                  '${((state.uploadProgress ?? 0) * 100).round()}',
                                ],
                              )
                      : 'settings_bg_media_upload'.tr(),
                ),
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
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: state.uploading
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(RadiusToken.pill),
                    child: LinearProgressIndicator(
                      value:
                          (state.uploadProgress ?? 0) >=
                              AppBackgroundState.transferProgressWeight
                          ? null
                          : state.uploadProgress,
                      minHeight: 6,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
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
          LayoutBuilder(
            builder: (context, constraints) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: constraints.maxWidth >= 720 ? 4 : 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 16 / 9,
              ),
              itemCount: state.assets.length,
              itemBuilder: (context, index) {
                final asset = state.assets[index];
                return _BackgroundAssetTile(
                  key: ValueKey(asset.id),
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
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
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
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _BackgroundAssetTile extends StatelessWidget {
  final AppBackgroundAsset asset;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  const _BackgroundAssetTile({
    super.key,
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
      label: asset.displayName,
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(RadiusToken.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(RadiusToken.md),
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(RadiusToken.md),
                child: asset.type == AppBackgroundMediaType.image
                    ? Image(
                        image: appCachedNetworkImageProvider(asset.url),
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                        isAntiAlias: true,
                        gaplessPlayback: true,
                      )
                    : BackgroundVideoThumbnail(url: asset.url),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 34,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xB3000000)],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: IconButton.filled(
                  tooltip: 'settings_bg_media_delete'.tr(),
                  onPressed: onDelete,
                  constraints: const BoxConstraints.tightFor(
                    width: 36,
                    height: 36,
                  ),
                  padding: EdgeInsets.zero,
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedDelete02,
                    size: 16,
                  ),
                ),
              ),
              if (selected)
                Positioned(
                  top: 8,
                  left: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedTick02,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 6,
                right: 6,
                bottom: 5,
                child: Text(
                  asset.displayName,
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
