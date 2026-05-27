import 'package:anoxia/common/constants/StorageKeys.dart';
import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/utils/SPUtil.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/features/chat/presentation/call/call_room_page.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pip/pip.dart';

/// 移动端全屏通话视图组件
///
/// 现嵌入在大厂全局浮层架构（GlobalCallOverlay）的全屏形态中，负责：
/// - 绑定与初始化系统底层画中画（PiP）事件
/// - 动态拉取房间令牌（Token）并同步至全局状态机
/// - 申请通话所需的蓝牙及外设权限
class MobileCallPage extends ConsumerStatefulWidget {
  /// 房间ID
  final String roomId;

  /// 通话标题
  final String title;

  const MobileCallPage({super.key, required this.roomId, required this.title});

  @override
  ConsumerState<MobileCallPage> createState() => _MobileCallPageState();
}

class _MobileCallPageState extends ConsumerState<MobileCallPage> {
  late final Pip _systemPip;

  @override
  void initState() {
    super.initState();
    _systemPip = Pip();

    // 异步检查并请求蓝牙外设权限
    _checkBluetoothPermissions();

    // 💡 核心闭环：在全局常驻浮层内安全初始化系统原生画中画（PiP）监控
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupSystemPiP();
    });
  }

  /// 初始化并绑定系统级画中画 (PiP)
  Future<void> _setupSystemPiP() async {
    try {
      final isSupported = await _systemPip.isSupported();
      if (isSupported) {
        await _systemPip.setup(
          const PipOptions(
            autoEnterEnabled: true, // 开启按 Home 键自动触发画中画
            aspectRatioX: 9,
            aspectRatioY: 16,
            controlStyle: 2,
            useExternalStateMonitor: true,
            externalStateMonitorInterval: 100,
          ),
        );

        await _systemPip.registerStateChangedObserver(
          PipStateChangedObserver(
            onPipStateChanged: (pipState, error) {
              final isPipStarted = pipState == PipState.pipStateStarted;
              if (mounted) {
                debugPrint('--- [大厂架构 PiP 状态同步]: $pipState ---');
                // 无缝同步原生画中画开启状态给 Riverpod 状态机
                ref
                    .read(mobileCallSessionControllerProvider.notifier)
                    .setPipMode(isPipStarted);
              }
              
              if (pipState == PipState.pipStateFailed) {
                debugPrint('--- [PiP 核心回调错误]: $error ---');
                _systemPip.dispose();
              }
            },
          ),
        );
      } else {
        Toast.showToast('当前设备不支持画中画功能，切后台后将无法继续通话');
      }
    } catch (e) {
      debugPrint('--- [PiP 初始化错误]: $e ---');
    }
  }

  /// 检查并请求蓝牙权限（仅 Android 移动端）
  Future<void> _checkBluetoothPermissions() async {
    if (!DeviceUtil.isAndroid()) return;

    final requested =
        SPUtil.instance.getBool(StorageKeys.kBluetoothPermissionRequestedKey) ??
        false;
    if (requested) return;

    bool hasPermanentlyDenied = false;

    var status = await Permission.bluetooth.request();
    if (status.isPermanentlyDenied) {
      log.warning('Bluetooth Permission disabled');
      hasPermanentlyDenied = true;
    }

    status = await Permission.bluetoothConnect.request();
    if (status.isPermanentlyDenied) {
      log.warning('Bluetooth Connect Permission disabled');
      hasPermanentlyDenied = true;
    }

    await SPUtil.instance.setBool(
      StorageKeys.kBluetoothPermissionRequestedKey,
      true,
    );

    if (hasPermanentlyDenied) {
      await openAppSettings();
    }
  }

  @override
  void dispose() {
    // 安全断开并销毁系统原生画中画监听
    _systemPip.unregisterStateChangedObserver();
    _systemPip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(mobileCallSessionControllerProvider);
    final token = session?.token;

    // ─── 状况 A：若全局缓存中已存在有效的 Token，直接交由 LiveKit 渲染 ───
    if (token != null && token.isNotEmpty) {
      return CallRoomPage(token: token);
    }

    // ─── 状况 B：首次进房，通过异步 Provider 触发业务层拉取 Token ───
    final tokenAsync = ref.watch(roomTokenProvider(widget.roomId));
    return tokenAsync.when(
      data: (newToken) {
        // 首次获取成功，立即将 Token 同步至全局状态机，确保单例闭环
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref
                .read(mobileCallSessionControllerProvider.notifier)
                .updateToken(newToken);
          }
        });

        return CallRoomPage(token: newToken);
      },
      error: (err, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('call_window_room_creation_failed'.tr()),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () =>
                  ref.invalidate(roomTokenProvider(widget.roomId)),
              child: Text('call_window_retry'.tr()),
            ),
          ],
        ),
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}