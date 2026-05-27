import 'package:anoxia/common/constants/StorageKeys.dart';
import 'package:anoxia/common/constants/app_key.dart';
import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/utils/SPUtil.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/features/chat/presentation/call/call_room_page.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_floating/floating/assist/floating_edge_type.dart';
import 'package:flutter_floating/floating/floating_overlay.dart';
import 'package:flutter_floating/floating/manager/floating_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pip/pip.dart';

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
  late final Pip _systemPip;

  @override
  void initState() {
    super.initState();
    _systemPip = Pip();

    _checkBluetoothPermissions();

    // 💡 核心修复：在外层页面注册系统画中画，保障切桌面时始终有效
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupSystemPiP();
    });
  }

  Future<void> _setupSystemPiP() async {
    try {
      final isSupported = await _systemPip.isSupported();
      if (isSupported) {
        await _systemPip.setup(
          const PipOptions(
            autoEnterEnabled: true,
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
              if (mounted) {
                ref
                    .read(mobileCallSessionControllerProvider.notifier)
                    .setPipMode(pipState == PipState.pipStateStarted);
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
    // 1. Web 和非 Android 平台直接跳过
    if (!DeviceUtil.isAndroid()) return;

    // 2. 检查本地缓存，避免每次进房间都无脑弹窗
    final requested =
        SPUtil.instance.getBool(StorageKeys.kBluetoothPermissionRequestedKey) ??
        false;
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
    await SPUtil.instance.setBool(
      StorageKeys.kBluetoothPermissionRequestedKey,
      true,
    );

    // 6. 若被用户拉黑（永久拒绝），引导用户前往系统设置
    if (hasPermanentlyDenied) {
      await openAppSettings();
    }
  }

  /// 统一处理页面缩小（返回）的逻辑
  void _minimizeCall() {
    // 修改全局状态为最小化（这将驱动应用内悬浮窗 flutter_floating 的展示）
    ref.read(mobileCallSessionControllerProvider.notifier).minimize();
  }

  @override
  void dispose() {
    _systemPip.unregisterStateChangedObserver();
    _systemPip.dispose();
    super.dispose();
  }

  /// 💡 核心修复：仅改变全局状态，绝对不调用 Navigator.pop()
  void _minimizeToInAppFloating() {
    final session = ref.read(mobileCallSessionControllerProvider);
    // 防御：若连基本会话都未建立（比如连 Token 都没拿到），直接真正退出
    if (session == null || session.token == null) {
      Navigator.of(context).pop();
      return;
    }

    // 1. 修改状态改变 UI（骨架页将变为隐形 SizedBox.shrink()）
    ref.read(mobileCallSessionControllerProvider.notifier).minimize();

    // 2. 唤起应用内悬浮窗
    if (!floatingManager.containsFloating(AppKey.floatingKey)) {
      floatingManager.createFloating(
        AppKey.floatingKey,
        FloatingOverlay(
          const Center(
            child: Icon(Icons.call, color: Colors.greenAccent, size: 32),
          ),
          slideType: FloatingEdgeType.onRightAndTop,
          right: 16,
          top: 150,
        ),
      );
    }
    floatingManager.getFloating(AppKey.floatingKey).open(context);
  }

  @override
  Widget build(BuildContext context) {
    //  拿到全局的通话会话状态
    final session = ref.watch(mobileCallSessionControllerProvider);

    final isInPipMode = session?.isInPipMode ?? false;
    // 监视应用内小窗状态
    final isMinimized = session?.minimized ?? false;

    // ─── 🎬 状况 A：手机点击 Home 键，进入系统画中画模式 ───
    if (isInPipMode && session?.token != null) {
      return CallRoomPage(token: session!.token!);
    }
    // ─── 📱 状况 B：用户在应用内点击“缩小”，进入应用内小窗 ───
    if (isMinimized) {
      // 保持页面活着！返回一个空组件。
      // 这样页面存活在路由栈中，用户此时按 Home 键，Android 依然能完美捕获信号切入桌面 PiP！
      return const SizedBox.shrink();
    }
    // ─── 📺 状况 C：正常全屏通话状态 ───
    if (session != null && session.token != null && session.token!.isNotEmpty) {
      return _buildScaffoldContent(
        context,
        CallRoomPage(token: session.token!),
      );
    }

    // 首次进入拉取 Token 流程
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

  ///  抽离出骨架包裹，避免由于 AsyncValue 切换造成整个 Scaffold 树结构闪烁
  Widget _buildScaffoldContent(BuildContext context, Widget bodyChild) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _minimizeToInAppFloating(); // 拦截系统物理返回键或手势返回，同样走应用内缩小
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(
            widget.title.isEmpty ? 'appbar_start_meeting'.tr() : widget.title,
          ),
          leading: IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedMinimizeScreen,
              size: 22,
            ),
            onPressed: _minimizeToInAppFloating,
          ),
        ),
        body: bodyChild,
      ),
    );
  }
}
