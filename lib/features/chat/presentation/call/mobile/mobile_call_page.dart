import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/features/chat/presentation/call/call_room_page.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    // 核心：一进入通话页面，立刻初始化 Android 的后台前台服务环境
    if (DeviceUtil.isAndroid()) {
      _initAndroidBackgroundConfig();
    }
  }

  /// 封装 Android 后台保活初始化逻辑
  Future<void> _initAndroidBackgroundConfig() async {
    try {
      const androidConfig = FlutterBackgroundAndroidConfig(
        notificationTitle: '通话中',
        notificationText: '音视频服务正在后台安全运行',
        notificationImportance: AndroidNotificationImportance.normal,
        notificationIcon: AndroidResource(
          name: 'ic_launcher',
          defType: 'mipmap',
        ),
      );

      // 初始化后台服务包裹器
      bool hasPermissions = await FlutterBackground.initialize(
        androidConfig: androidConfig,
      );
      if (hasPermissions && !FlutterBackground.isBackgroundExecutionEnabled) {
        // 直接激活前台通知栏服务，确保麦克风流可以在切后台时不被系统强杀
        await FlutterBackground.enableBackgroundExecution();
      }
    } catch (e) {
      print('初始化 Android 后台服务失败: $e');
    }
  }

  /// 统一处理页面缩小（返回）的逻辑
  void _minimizeCall() {
    // 1. 修改全局状态为最小化（这将驱动应用内悬浮窗 flutter_floating 的展示）
    ref.read(mobileCallSessionControllerProvider.notifier).minimize();
    // 2. 安全退出当前全屏页面
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tokenAsync = ref.watch(roomTokenProvider(widget.roomId));

    return PopScope(
      canPop: false, // 阻止默认的销毁退出
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _minimizeCall(); // 触发缩小逻辑
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
        body: tokenAsync.when(
          data: (token) => CallRoomPage(token: token),
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
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
