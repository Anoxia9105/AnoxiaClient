import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/features/me/presentation/widgets/avatar_crop_editor.dart';
import 'package:anoxia/framework/provider/core/upload_repository_provider.dart';
import 'package:cross_file/cross_file.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// 创建群聊时选择、裁剪并上传头像，失败时保留上一张可用头像。
class GroupAvatarPicker extends ConsumerStatefulWidget {
  const GroupAvatarPicker({
    super.key,
    required this.onChanged,
    required this.onBusyChanged,
    this.disabled = false,
  });
  final ValueChanged<String?> onChanged;
  final ValueChanged<bool> onBusyChanged;
  final bool disabled;
  @override
  ConsumerState<GroupAvatarPicker> createState() => _GroupAvatarPickerState();
}

class _GroupAvatarPickerState extends ConsumerState<GroupAvatarPicker> {
  String? _url;
  bool _busy = false;

  Future<void> _pick() async {
    if (_busy || widget.disabled) return;
    setState(() => _busy = true);
    widget.onBusyChanged(true);
    try {
      final selected = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (!mounted || selected == null) return;
      final bytes = selected.files.single.bytes;
      if (bytes == null || bytes.isEmpty) return;
      final editorKey = GlobalKey<AvatarCropEditorState>();
      final cropped = await showDialog<XFile>(
        context: context,
        builder: (context) {
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
                onPressed: () {
                  final croppedBytes = editorKey.currentState?.cropSquare();
                  if (croppedBytes == null) return;
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
      );
      if (!mounted || cropped == null) return;
      final results = await ref
          .read(uploadRepositoryProvider)
          .uploadFiles([cropped], clientFileIds: [const Uuid().v4()]);
      if (!mounted) return;
      final result = results.single;
      if (!result.isSuccess || result.url == null || result.url!.isEmpty) {
        throw StateError('avatar upload failed');
      }
      setState(() => _url = result.url);
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
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Stack(
        alignment: Alignment.center,
        children: [
          AvatarWidget(size: 48, url: _url ?? '', name: 'group_chat'.tr()),
          if (_busy)
            const SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
      const SizedBox(width: 12),
      Expanded(
        child: TextButton.icon(
          onPressed: _busy || widget.disabled ? null : _pick,
          icon: const Icon(Icons.add_a_photo_outlined, size: 18),
          label: Text('group_avatar_choose'.tr()),
        ),
      ),
      if (_url != null)
        IconButton(
          tooltip: 'group_avatar_remove'.tr(),
          onPressed: _busy || widget.disabled
              ? null
              : () {
                  setState(() => _url = null);
                  widget.onChanged(null);
                },
          icon: const Icon(Icons.close, size: 18),
        ),
    ],
  );
}
