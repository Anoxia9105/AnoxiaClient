import 'dart:convert';

import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/features/contact/presentation/pages/add_friend_page.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQrPage extends ConsumerStatefulWidget {
  const ScanQrPage({super.key});

  @override
  ConsumerState<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends ConsumerState<ScanQrPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _handling = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;

    final raw = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (raw == null || raw.isEmpty) return;

    _handling = true;
    await _controller.stop();
    if (!mounted) return;

    final card = _tryParseUserCard(raw);
    if (card != null) {
      final me = ref.read(authControllerProvider).value;
      final isSelf =
          me != null &&
          (card.userName == me.userName ||
              (card.userId != null && card.userId == me.userId));

      if (isSelf) {
        Toast.showToast(
          'chat_scan_cannot_add_self'.tr(),
          type: ToastType.warning,
        );
        _handling = false;
        await _controller.start();
        return;
      }

      Toast.showToast(
        'chat_scan_user_card_detected'.tr(args: [card.userName]),
        type: ToastType.success,
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AddFriendPage(initialKeyword: card.userName),
        ),
      );
      return;
    }

    Toast.showToast(
      '${'chat_scan_result'.tr()}: $raw',
      type: ToastType.success,
    );

    Navigator.of(context).pop(raw);
  }

  _UserCardPayload? _tryParseUserCard(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final map = decoded.cast<dynamic, dynamic>();
      final type = map['type']?.toString();
      if (type != 'user_card') return null;

      final userName = map['userName']?.toString().trim() ?? '';
      if (userName.isEmpty) return null;

      int? userId;
      final rawUserId = map['userId'];
      if (rawUserId is int) {
        userId = rawUserId;
      } else if (rawUserId != null) {
        userId = int.tryParse(rawUserId.toString());
      }

      return _UserCardPayload(userName: userName, userId: userId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('chat_scan_qr_code'.tr())),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Text(
                  'chat_scan_qr_code_hint'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCardPayload {
  const _UserCardPayload({required this.userName, this.userId});

  final String userName;
  final int? userId;
}
