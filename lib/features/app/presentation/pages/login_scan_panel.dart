import 'dart:async';

import 'package:anoxia/common/widgets/skeleton_box.dart';
import 'package:anoxia/framework/provider/auth/scan_login_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// 扫码登录面板（桌面/Web）
///
/// 展示二维码并自动轮询登录状态；手机 App 扫码确认后自动完成登录。
class ScanLoginPanel extends ConsumerStatefulWidget {
  const ScanLoginPanel({super.key});

  @override
  ConsumerState<ScanLoginPanel> createState() => _ScanLoginPanelState();
}

class _ScanLoginPanelState extends ConsumerState<ScanLoginPanel> {
  /// 倒计时定时器（每秒递减）
  Timer? _ticker;

  /// 当前倒计时所属的 ticket，ticket 变化时重置倒计时
  String? _countdownFor;

  /// 剩余有效秒数
  int _remaining = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSession());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// 创建新的扫码登录会话
  Future<void> _startSession() async {
    try {
      await ref.read(scanLoginControllerProvider.notifier).start();
    } catch (_) {
      // 错误状态由下方 UI 展示，此处仅静默
    }
  }

  /// 启动倒计时
  void _beginCountdown(String ticket, int expiresIn) {
    _ticker?.cancel();
    setState(() {
      _countdownFor = ticket;
      _remaining = expiresIn;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining > 0) {
        setState(() => _remaining -= 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final session = ref.watch(scanLoginControllerProvider);

    return session.when(
      loading: () => _buildLoading(),
      error: (e, st) => _buildError(colorScheme),
      data: (session) {
        if (session == null) return _buildLoading();

        final ticket = session.ticket;
        if (_countdownFor != ticket.ticket) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _beginCountdown(ticket.ticket, ticket.expiresIn),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildQrCard(colorScheme, session),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'login_scan_countdown'.tr(
                    namedArgs: {'seconds': '$_remaining'},
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    color: _remaining <= 10
                        ? colorScheme.error
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: _startSession,
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedRefresh01,
                    size: 18,
                  ),
                  label: Text('login_scan_refresh'.tr()),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'login_scan_hint'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQrCard(ColorScheme colorScheme, ScanLoginSession session) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: QrImageView(
          data: session.ticket.qrContent,
          size: 200,
          padding: EdgeInsets.zero,
          backgroundColor: Colors.white,
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
    );
  }

  /// 加载中骨架屏（布局与二维码卡片一致）
  Widget _buildLoading() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        QrSkeleton(),
        SizedBox(height: 18),
        SkeletonLine(width: 120, height: 12),
        SizedBox(height: 14),
        SkeletonLine(width: 170, height: 10),
      ],
    );
  }

  Widget _buildError(ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HugeIcon(
          icon: HugeIcons.strokeRoundedAlertCircle,
          size: 48,
          color: colorScheme.error,
        ),
        const SizedBox(height: 12),
        Text(
          'login_scan_error'.tr(),
          style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _startSession,
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedRefresh01,
            size: 18,
          ),
          label: Text('login_scan_retry'.tr()),
        ),
      ],
    );
  }
}

/// 扫码登录骨架屏
///
/// 布局与真实二维码卡片一致：三个角落的寻像图形 + 中部数据模块占位。
class QrSkeleton extends StatelessWidget {
  const QrSkeleton({super.key});

  /// 模拟数据模块的位置（相对卡片内边距区域）
  static const List<Offset> _dots = [
    Offset(60, 60),
    Offset(88, 60),
    Offset(116, 60),
    Offset(60, 88),
    Offset(116, 88),
    Offset(60, 116),
    Offset(88, 116),
    Offset(116, 116),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 224,
      height: 224,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Stack(
        children: [
          const Positioned(left: 0, top: 0, child: QrFinderPattern()),
          const Positioned(right: 0, top: 0, child: QrFinderPattern()),
          const Positioned(left: 0, bottom: 0, child: QrFinderPattern()),
          for (final offset in _dots)
            Positioned(
              left: offset.dx,
              top: offset.dy,
              child: const SkeletonBox(width: 12, height: 12, radius: 3),
            ),
          const Positioned(right: 0, bottom: 0, child: QrAlignmentPattern()),
        ],
      ),
    );
  }
}

/// 二维码寻像图形（三个角落的“回”字占位）
class QrFinderPattern extends StatelessWidget {
  const QrFinderPattern({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SkeletonBox(width: 44, height: 44, radius: 8),
          SkeletonBox(width: 22, height: 22, radius: 4),
        ],
      ),
    );
  }
}

/// 二维码对齐图形（右下角小“回”字占位）
class QrAlignmentPattern extends StatelessWidget {
  const QrAlignmentPattern({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 27,
      height: 27,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SkeletonBox(width: 27, height: 27, radius: 6),
          SkeletonBox(width: 11, height: 11, radius: 3),
        ],
      ),
    );
  }
}
