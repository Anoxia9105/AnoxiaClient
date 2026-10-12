import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/common/utils/static_avatar_image.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/features/me/presentation/widgets/avatar_crop_editor.dart';
import 'package:anoxia/framework/provider/core/room_repository_provider.dart';
import 'package:cross_file/cross_file.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 创建群聊时选择、裁剪并上传头像，失败时保留上一张可用头像。
class GroupAvatarPicker extends ConsumerStatefulWidget {
  const GroupAvatarPicker({
    super.key,
    required this.onChanged,
    required this.onBusyChanged,
    this.disabled = false,
    this.initialUrl,
    this.onSave,
    this.allowRemove = true,
  });
  final ValueChanged<String?> onChanged;
  final ValueChanged<bool> onBusyChanged;
  final bool disabled;
  final String? initialUrl;
  final Future<bool> Function(String url)? onSave;
  final bool allowRemove;
  @override
  ConsumerState<GroupAvatarPicker> createState() => _GroupAvatarPickerState();
}

class _GroupAvatarPickerState extends ConsumerState<GroupAvatarPicker> {
  late String? _url = widget.initialUrl;
  bool _busy = false;

  Future<void> _pick() async {
    if (_busy || widget.disabled) return;
    setState(() => _busy = true);
    widget.onBusyChanged(true);
    try {
      final selected = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
        withData: true,
      );
      if (!mounted || selected == null) return;
      final bytes = selected.files.single.bytes;
      if (bytes == null || bytes.isEmpty) return;
      if (!isStaticAvatarImage(bytes)) {
        Toast.showToast('avatar_static_only'.tr(), type: ToastType.warning);
        return;
      }
      final editorKey = GlobalKey<AvatarCropEditorState>();
      var cropping = false;
      final cropped = await showDialog<XFile>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            final size = (MediaQuery.sizeOf(context).width - 96).clamp(
              160.0,
              280.0,
            );
            return AlertDialog(
              title: Text('group_avatar_choose'.tr()),
              content: SingleChildScrollView(
                child: AvatarCropEditor(
                  key: editorKey,
                  imageBytes: bytes,
                  size: size,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('cancel'.tr()),
                ),
                FilledButton(
                  onPressed: cropping
                      ? null
                      : () async {
                          setDialogState(() => cropping = true);
                          final croppedBytes = await editorKey.currentState
                              ?.cropSquare();
                          if (!context.mounted) return;
                          if (croppedBytes == null) {
                            setDialogState(() => cropping = false);
                            Toast.showToast(
                              'me_avatar_crop_failed'.tr(),
                              type: ToastType.error,
                            );
                            return;
                          }
                          Navigator.pop(
                            context,
                            XFile.fromData(
                              croppedBytes,
                              name: 'group-avatar.jpg',
                              mimeType: 'image/jpeg',
                            ),
                          );
                        },
                  child: Text('dialog_done'.tr()),
                ),
              ],
            );
          },
        ),
      );
      if (!mounted || cropped == null) return;
      final url = await ref
          .read(roomRepositoryProvider)
          .uploadGroupAvatar(cropped);
      if (!mounted) return;
      if (url == null || url.isEmpty) throw StateError('avatar upload failed');
      if (widget.onSave != null && !await widget.onSave!(url)) {
        if (mounted) {
          Toast.showToast(
            'chat_operation_retry_failed'.tr(),
            type: ToastType.error,
          );
        }
        return;
      }
      if (!mounted) return;
      setState(() => _url = url);
      widget.onChanged(_url);
    } catch (_) {
      if (mounted) {
        Toast.showToast('me_avatar_upload_failed'.tr(), type: ToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        widget.onBusyChanged(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _busy || widget.disabled ? null : _pick,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  AvatarWidget(
                    size: 64,
                    url: _url ?? '',
                    name: 'group_chat'.tr(),
                  ),
                  if (_busy)
                    const SizedBox.square(
                      dimension: 28,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  if (!_busy)
                    const Positioned(
                      right: 0,
                      bottom: 0,
                      child: Icon(Icons.add_a_photo_outlined, size: 20),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'group_avatar_choose'.tr(),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'avatar_static_hint'.tr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (_url != null && widget.allowRemove)
                IconButton(
                  tooltip: 'group_avatar_remove'.tr(),
                  onPressed: _busy || widget.disabled
                      ? null
                      : () {
                          setState(() => _url = null);
                          widget.onChanged(null);
                        },
                  icon: const Icon(Icons.close, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
