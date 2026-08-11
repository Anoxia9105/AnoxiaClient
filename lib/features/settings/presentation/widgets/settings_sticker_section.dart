import 'package:anoxia/common/widgets/cached_network_image_view.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/framework/domain/sticker_pack.dart';
import 'package:anoxia/framework/provider/chat/sticker/custom_sticker_controller.dart';
import 'package:anoxia/framework/provider/chat/sticker/sticker_packs_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_item_card.dart';

/// 设置-自定义表情包区块
///
/// 允许用户上传自己的图片作为表情包，上传成功后会在聊天表情面板
/// 与聊天记录中展示，数据保存在服务端，跨平台/跨设备一致。
class SettingsStickerSection extends ConsumerStatefulWidget {
  const SettingsStickerSection({super.key});

  @override
  ConsumerState<SettingsStickerSection> createState() =>
      _SettingsStickerSectionState();
}

class _SettingsStickerSectionState extends ConsumerState<SettingsStickerSection> {
  Future<void> _handleUpload() async {
    final result = await ref
        .read(customStickerControllerProvider.notifier)
        .uploadStickers();
    if (!mounted) return;

    if (result.success) {
      Toast.showToast(
        'settings_sticker_upload_success'.tr(args: ['${result.addedCount}']),
        type: ToastType.success,
      );
      return;
    }
    if (result.errorKey != null) {
      Toast.showToast(result.errorKey!.tr(), type: ToastType.error);
    }
  }

  Future<void> _confirmDeletePack(StickerPack pack) async {
    final confirmed = await _showConfirmDialog(
      title: 'settings_sticker_delete_pack_title'.tr(),
      message: 'settings_sticker_delete_pack_desc'.tr(args: [pack.name]),
    );
    if (!confirmed || !mounted) return;

    final ok = await ref
        .read(customStickerControllerProvider.notifier)
        .deletePack(pack);
    if (!mounted) return;
    Toast.showToast(
      ok
          ? 'settings_sticker_delete_pack_success'.tr()
          : 'settings_sticker_delete_failed'.tr(),
      type: ok ? ToastType.success : ToastType.error,
    );
  }

  Future<void> _confirmDeleteSticker(Sticker sticker) async {
    final confirmed = await _showConfirmDialog(
      title: 'settings_sticker_delete_sticker_title'.tr(),
      message: 'settings_sticker_delete_sticker_desc'.tr(),
    );
    if (!confirmed || !mounted) return;

    final ok = await ref
        .read(customStickerControllerProvider.notifier)
        .deleteSticker(sticker.id);
    if (!mounted) return;
    Toast.showToast(
      ok
          ? 'settings_sticker_delete_success'.tr()
          : 'settings_sticker_delete_failed'.tr(),
      type: ok ? ToastType.success : ToastType.error,
    );
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        title: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text('confirm'.tr()),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stickerState = ref.watch(customStickerControllerProvider);
    final packsAsync = ref.watch(stickerPacksProvider);
    final customPacks = packsAsync.maybeWhen(
      data: (packs) => packs.where((p) => p.isCustom).toList(),
      orElse: () => const <StickerPack>[],
    );

    return SettingItemCard(
      title: 'settings_sticker_title'.tr(),
      subtitle: 'settings_sticker_subtitle'.tr(),
      icon: HugeIcons.strokeRoundedSticker,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: stickerState.uploading ? null : _handleUpload,
              icon: stickerState.uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const HugeIcon(
                      icon: HugeIcons.strokeRoundedUpload01,
                      size: 18,
                    ),
              label: Text(
                stickerState.uploading
                    ? 'settings_sticker_uploading'.tr()
                    : 'settings_sticker_upload'.tr(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'settings_sticker_upload_tip'.tr(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (stickerState.uploading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (customPacks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'settings_sticker_empty'.tr(),
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            )
          else
            for (final pack in customPacks) _buildPack(pack, stickerState),
        ],
      ),
    );
  }

  Widget _buildPack(StickerPack pack, CustomStickerState state) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (pack.iconUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CachedNetworkImageView(
                    imageUrl: pack.iconUrl,
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                  ),
                ),
              if (pack.iconUrl.isNotEmpty) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pack.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${pack.stickers.length}',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              IconButton(
                onPressed: state.deleting ? null : () => _confirmDeletePack(pack),
                tooltip: 'settings_sticker_delete_pack_title'.tr(),
                visualDensity: VisualDensity.compact,
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedDelete02,
                  size: 18,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final sticker in pack.stickers)
                _buildStickerItem(sticker, state),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStickerItem(Sticker sticker, CustomStickerState state) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          child: CachedNetworkImageView(
            imageUrl: sticker.imageUrl,
            width: 42,
            height: 42,
            fit: BoxFit.contain,
            placeholder: (context, url) => const SizedBox.shrink(),
            errorWidget: (context, url, error) => Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedSticker,
                size: 18,
                color: scheme.outline,
              ),
            ),
          ),
        ),
        Positioned(
          top: -5,
          right: -5,
          child: GestureDetector(
            onTap: state.deleting ? null : () => _confirmDeleteSticker(sticker),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: scheme.error,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.surface, width: 1.5),
              ),
              child: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
