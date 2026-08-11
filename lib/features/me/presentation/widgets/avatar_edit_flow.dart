import 'dart:typed_data';
import 'package:hugeicons/hugeicons.dart';

import 'package:anoxia/common/constants/api.dart';
import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/framework/domain/user_info.dart';
import 'package:anoxia/framework/network/dio_client.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:cross_file/cross_file.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'avatar_crop_editor.dart';

/// 头像上传回调
///
/// [success] 是否上传成功（成功时宿主页面负责刷新用户信息并关闭自身）
typedef AvatarEditCallback = Future<void> Function(bool success);

/// 头像编辑流程组件（选择图片 → 裁剪预览 → 上传）
///
/// 桌面端对话框与移动端页面共用，纯 Flutter 实现，Web/Wasm 全平台兼容。
class AvatarEditFlow extends ConsumerStatefulWidget {
  const AvatarEditFlow({
    super.key,
    required this.editorSize,
    required this.onDone,
  });

  /// 裁剪预览区边长（正方形）
  final double editorSize;

  /// 流程结束回调
  final AvatarEditCallback onDone;

  @override
  ConsumerState<AvatarEditFlow> createState() => _AvatarEditFlowState();
}

class _AvatarEditFlowState extends ConsumerState<AvatarEditFlow> {
  final GlobalKey<AvatarCropEditorState> _editorKey =
      GlobalKey<AvatarCropEditorState>();

  Uint8List? _pickedBytes;
  bool _picking = false;
  bool _uploading = false;

  Future<void> _pickImage() async {
    if (_picking || _uploading) return;
    _picking = true;
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final bytes = result.files.single.bytes;
      if (bytes == null || bytes.isEmpty) return;
      if (!mounted) return;
      setState(() {
        _pickedBytes = bytes;
      });
    } catch (_) {
      if (mounted) {
        Toast.showToast(
          'me_avatar_load_failed'.tr(),
          type: ToastType.error,
        );
      }
    } finally {
      _picking = false;
    }
  }

  Future<void> _confirm() async {
    final editor = _editorKey.currentState;
    if (editor == null || _uploading) return;

    final bytes = editor.cropSquare();
    if (bytes == null) {
      Toast.showToast(
        'me_avatar_crop_failed'.tr(),
        type: ToastType.error,
      );
      return;
    }

    setState(() => _uploading = true);
    try {
      final file = XFile.fromData(
        bytes,
        name: 'avatar.jpg',
        mimeType: 'image/jpeg',
      );
      final res = await DioClient().uploadFile(
        API.userAvatarUpload,
        file: file,
        fileField: 'file',
      );
      final ok = res.data is Map && res.data['code'] == 200;
      if (ok) {
        Toast.showToast(
          'me_avatar_upload_success'.tr(),
          type: ToastType.success,
        );
        await widget.onDone(true);
        return;
      }
      final msg = (res.data is Map ? res.data['msg']?.toString() : null) ?? '';
      Toast.showToast(
        msg.isNotEmpty ? msg : 'me_avatar_upload_failed'.tr(),
        type: ToastType.error,
      );
    } catch (_) {
      Toast.showToast(
        'me_avatar_upload_failed'.tr(),
        type: ToastType.error,
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _pickedBytes;
    final user = ref.watch(authControllerProvider).when(
          data: (u) => u,
          loading: () => null,
          error: (_, _) => null,
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (bytes == null)
          _buildPickPrompt(user)
        else ...[
          AvatarCropEditor(
            key: _editorKey,
            imageBytes: bytes,
            size: widget.editorSize,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _uploading ? null : _pickImage,
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedImage01, size: 18),
                  label: Text('me_avatar_reselect'.tr()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _uploading ? null : _confirm,
                  icon: _uploading
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const HugeIcon(icon: HugeIcons.strokeRoundedTick01, size: 18),
                  label: Text('me_avatar_confirm'.tr()),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPickPrompt(UserInfo? user) {
    return SizedBox(
      height: widget.editorSize,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AvatarWidget(url: user?.avatar, name: user?.nickName, size: 88),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _pickImage,
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedGalleryHorizontalEnd, size: 18),
            label: Text('me_avatar_choose'.tr()),
          ),
        ],
      ),
    );
  }
}
