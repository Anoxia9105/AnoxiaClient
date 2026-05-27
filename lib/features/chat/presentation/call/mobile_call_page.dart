import 'package:anoxia/common/constants/StorageKeys.dart';
import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/utils/SPUtil.dart';
import 'package:anoxia/features/chat/presentation/call/call_room_page.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

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
  @override
  void initState() {
    super.initState();
    // 异步检查并请求蓝牙外设权限
    _checkBluetoothPermissions();
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
              onPressed: () => ref.invalidate(roomTokenProvider(widget.roomId)),
              child: Text('call_window_retry'.tr()),
            ),
          ],
        ),
      ),
      loading: () =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}
