import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/utils/SPUtil.dart';
import 'package:anoxia/features/chat/presentation/call/call_room_page.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

/// SharedPreferences 存储 Key：蓝牙权限是否已申请
const String _kBluetoothPermissionRequestedKey =
    'bluetooth_permission_requested_v1';

/// 移动端通话页面
///
/// 作为移动端通话功能的入口页面，负责：
/// - 获取房间令牌
/// - 显示通话房间内容
/// - 处理加载和错误状态
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
    //  进页面后，异步安全检查并请求蓝牙耳机权限
    _checkBluetoothPermissions();
  }

  /// 检查并请求蓝牙权限（仅 Android 移动端）
  Future<void> _checkBluetoothPermissions() async {
    // 1. Web 和非 Android 平台直接跳过
    if (!DeviceUtil.isAndroid()) return;

    // 2. 检查本地缓存，避免每次进房间都无脑弹窗
    final requested =
        SPUtil.instance.getBool(_kBluetoothPermissionRequestedKey) ?? false;
    if (requested) return;

    bool hasPermanentlyDenied = false;

    // 3. 请求蓝牙基础权限
    var status = await Permission.bluetooth.request();
    if (status.isPermanentlyDenied) {
      log.warning('Bluetooth Permission disabled');
      hasPermanentlyDenied = true;
    }

    // 4. 请求 Android 12+ 必需的蓝牙连接权限
    status = await Permission.bluetoothConnect.request();
    if (status.isPermanentlyDenied) {
      log.warning('Bluetooth Connect Permission disabled');
      hasPermanentlyDenied = true;
    }

    // 5. 记录已请求状态
    await SPUtil.instance.setBool(_kBluetoothPermissionRequestedKey, true);

    // 6. 若被用户拉黑（永久拒绝），引导用户前往系统设置
    if (hasPermanentlyDenied) {
      await openAppSettings();
    }
  }

  /// 统一处理页面缩小（返回）的逻辑
  void _minimizeCall() {
    // 1. 修改全局状态为最小化（这将驱动应用内悬浮窗 flutter_floating 的展示）
    ref.read(mobileCallSessionControllerProvider.notifier).minimize();
    // 2. 安全退出当前全屏页面
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    // 💡 1. 拿到全局的通话会话状态
    final session = ref.watch(mobileCallSessionControllerProvider);

    // 💡 2. 核心防御：如果全局已经有缓存的 Token 了，直接无缝直出房间，绝不重新拉取
    if (session != null && session.token != null && session.token!.isNotEmpty) {
      return _buildScaffoldContent(
        context,
        CallRoomPage(token: session.token!),
      );
    }

    // 💡 3. 只有全局没有缓存时（第一次进入），才走异步 Provider 流程
    final tokenAsync = ref.watch(roomTokenProvider(widget.roomId));
    return tokenAsync.when(
      data: (token) {
        // 💡 首次获取成功，赶紧同步到全局状态机中，防止下一次返回再进来时穿透
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          ref
              .read(mobileCallSessionControllerProvider.notifier)
              .updateToken(token);
        });

        return _buildScaffoldContent(context, CallRoomPage(token: token));
      },
      error: (err, stack) => _buildScaffoldContent(
        context,
        Center(
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
      ),
      loading: () => _buildScaffoldContent(
        context,
        const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  /// 💡 抽离出骨架包裹，避免由于 AsyncValue 切换造成整个 Scaffold 树结构闪烁
  Widget _buildScaffoldContent(BuildContext context, Widget bodyChild) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _minimizeCall();
      },
      child: Scaffold(
        backgroundColor: DeviceUtil.isRealDesktop()
            ? Colors.transparent
            : Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: Text(
            widget.title.isEmpty ? 'appbar_start_meeting'.tr() : widget.title,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: _minimizeCall,
          ),
        ),
        body: bodyChild,
      ),
    );
  }
}
