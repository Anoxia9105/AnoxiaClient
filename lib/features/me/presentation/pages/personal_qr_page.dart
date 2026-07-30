import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/common/utils/AppPermission.dart';
import 'package:anoxia/framework/domain/user_info.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class PersonalQrPage extends StatefulWidget {
  const PersonalQrPage({super.key, required this.user});

  final UserInfo user;

  @override
  State<PersonalQrPage> createState() => _PersonalQrPageState();
}

class _PersonalQrPageState extends State<PersonalQrPage> {
  final GlobalKey _qrBoundaryKey = GlobalKey();
  bool _saving = false;
  bool _sharing = false;

  Future<Uint8List?> _captureQrBytes() async {
    final context = _qrBoundaryKey.currentContext;
    if (context == null) return null;

    final boundary = context.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _saveToGallery() async {
    if (_saving) return;

    final granted = await _ensureGalleryPermission();
    if (!granted) {
      Toast.showToast(
        'gallery_permission_required'.tr(),
        type: ToastType.error,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final bytes = await _captureQrBytes();
      if (bytes == null) {
        Toast.showToast('me_qr_save_failed'.tr(), type: ToastType.error);
        return;
      }

      final name =
          'anoxia_qr_${widget.user.userId}_${DateTime.now().millisecondsSinceEpoch}';
      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: 100,
        name: name,
      );
      final ok =
          result is Map &&
          (result['isSuccess'] == true || result['isSuccess'] == 1);

      Toast.showToast(
        ok ? 'me_qr_save_success'.tr() : 'me_qr_save_failed'.tr(),
        type: ok ? ToastType.success : ToastType.error,
      );
    } catch (_) {
      Toast.showToast('me_qr_save_failed'.tr(), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _ensureGalleryPermission() async {
    return ensureGalleryWritePermission(context);
  }

  Future<void> _shareQrImage() async {
    if (_sharing) return;

    setState(() => _sharing = true);
    try {
      final bytes = await _captureQrBytes();
      if (bytes == null) {
        Toast.showToast('me_qr_share_failed'.tr(), type: ToastType.error);
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}${Platform.pathSeparator}anoxia_qr_${widget.user.userId}.png',
      );
      await file.writeAsBytes(bytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'me_my_qr'.tr()),
      );
    } catch (_) {
      Toast.showToast('me_qr_share_failed'.tr(), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final qrData = jsonEncode({
      'type': 'user_card',
      'userId': widget.user.userId,
      'userName': widget.user.userName,
      'nickName': widget.user.nickName,
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: Text('me_my_qr'.tr())),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RepaintBoundary(
                    key: _qrBoundaryKey,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 180,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Colors.black,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.user.nickName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ID: ${widget.user.userId}',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'me_qr_hint'.tr(),
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: _saving ? null : _saveToGallery,
                          icon: _saving
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: cs.onSecondaryContainer,
                                  ),
                                )
                              : const Icon(Icons.save_alt_rounded, size: 18),
                          label: Text('me_qr_save_image'.tr()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _sharing ? null : _shareQrImage,
                          icon: _sharing
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: cs.onPrimary,
                                  ),
                                )
                              : const Icon(Icons.share_outlined, size: 18),
                          label: Text('me_qr_share_image'.tr()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
