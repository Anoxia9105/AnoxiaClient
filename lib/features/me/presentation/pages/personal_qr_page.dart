import 'package:hugeicons/hugeicons.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:anoxia/common/constants/api.dart';
import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/common/utils/app_permission.dart';
import 'package:anoxia/framework/domain/user_info.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:anoxia/platform/shims/image_gallery_saver_plus_shim.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// 个人二维码页面
///
/// 展示用户的个人二维码，支持保存到相册和分享功能。

/// 个人二维码页面组件
///
/// 显示用户信息编码的二维码，提供保存到相册和分享按钮。
class PersonalQrPage extends StatefulWidget {
  const PersonalQrPage({super.key, required this.user});

  /// 用户信息
  final UserInfo user;

  @override
  State<PersonalQrPage> createState() => _PersonalQrPageState();
}

/// 二维码页面状态
///
/// 管理二维码的截取、保存和分享操作。
class _PersonalQrPageState extends State<PersonalQrPage> {
  /// 二维码区域 Key
  final GlobalKey _qrBoundaryKey = GlobalKey();

  /// 是否正在保存
  bool _saving = false;

  /// 是否正在分享
  bool _sharing = false;

  /// 截取二维码图片字节数据
  Future<Uint8List?> _captureQrBytes() async {
    final context = _qrBoundaryKey.currentContext;
    if (context == null) return null;

    final boundary = context.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  /// 保存二维码到相册
  ///
  /// 请求相册权限后将二维码图片保存到设备相册。
  Future<void> _saveToGallery() async {
    if (_saving) return;

    // Web 端“保存到相册”等价于浏览器下载，无需相册权限；
    // 原生端才需要走系统相册权限流程。
    if (!DeviceUtil.isWeb) {
      final granted = await _ensureGalleryPermission();
      if (!granted) {
        Toast.showToast(
          'gallery_permission_required'.tr(),
          type: ToastType.error,
        );
        return;
      }
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

  /// 确保相册写入权限
  Future<bool> _ensureGalleryPermission() async {
    return ensureGalleryWritePermission(context);
  }

  /// 分享二维码图片
  ///
  /// 原生端写入临时文件后调用系统分享；Web 端用 [XFile.fromData] 走 Web Share API，
  /// 不支持文件分享的浏览器回退为下载。
  Future<void> _shareQrImage() async {
    if (_sharing) return;

    setState(() => _sharing = true);
    try {
      final bytes = await _captureQrBytes();
      if (bytes == null) {
        Toast.showToast('me_qr_share_failed'.tr(), type: ToastType.error);
        return;
      }

      final baseName = 'anoxia_qr_${widget.user.userId}';
      final name = '$baseName.png';
      if (DeviceUtil.isWeb) {
        final xfile = XFile.fromData(
          bytes,
          name: name,
          mimeType: 'image/png',
        );
        final result = await SharePlus.instance.share(
          ShareParams(files: [xfile], text: 'me_my_qr'.tr()),
        );
        // 仅在浏览器“不支持/不可用”文件分享时回退为下载；用户主动取消（dismissed）
        // 或未知状态不应触发下载，避免产生非预期的文件落地。
        // 下载桩会自动追加 .png，这里传不带扩展名的 baseName 避免 xxx.png.png。
        if (result.status == ShareResultStatus.unavailable) {
          await ImageGallerySaverPlus.saveImage(
            bytes,
            quality: 100,
            name: baseName,
          );
        }
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}${Platform.pathSeparator}$name');
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
    // 二维码编码短链接而非 JSON：微信等外部扫码器可识别为链接，
    // 后端 /u/{userId} 提供名片落地页；App 内扫码由扫码页解析 URL 跳转。
    final qrData = '${API.qrUserBaseUrl}${widget.user.userId}';

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
                    'me_qr_hint'.tr(),
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (!DeviceUtil.isWeb) ...[
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
                                : const HugeIcon(icon: HugeIcons.strokeRoundedSave, size: 18),
                            label: Text('me_qr_save_image'.tr()),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
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
                              : const HugeIcon(icon: HugeIcons.strokeRoundedShare01, size: 18),
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
