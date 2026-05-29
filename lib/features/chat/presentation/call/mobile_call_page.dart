import 'package:anoxia/common/constants/StorageKeys.dart';
import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/utils/SPUtil.dart';
import 'package:anoxia/features/chat/presentation/call/call_room_page.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pip/pip.dart';

/// 移动端通话页面
///
/// 提供移动端专属的音视频通话界面，支持：
/// - 全屏通话模式
/// - 保持屏幕常亮
/// - 蓝牙权限检查
/// - PiP模式适配
///
/// [roomId] 通话房间 ID
/// [title] 通话标题（房间名称或对方昵称）
class MobileCallPage extends ConsumerStatefulWidget {
  final String roomId;
  final String title;

  const MobileCallPage({super.key, required this.roomId, required this.title});

  @override
  ConsumerState<MobileCallPage> createState() => _MobileCallPageState();
}

class _MobileCallPageState extends ConsumerState<MobileCallPage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    _keepScreenOn(true);
    _checkBluetoothPermissions();
  }

  @override
  void dispose() {
    // 恢复息屏
    _keepScreenOn(false);
    super.dispose();
  }

  Future<void> _keepScreenOn(bool on) async {
    try {
      const channel = MethodChannel('screen_control');
      await channel.invokeMethod('setKeepScreenOn', on);
    } catch (e) {
      debugPrint('setKeepScreenOn error: $e');
    }
  }

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

    final inPip = session?.isInPipMode ?? false;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,

      appBar: inPip
          ? null
          : AppBar(
              title: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              leading: IconButton(
                icon: const Icon(Icons.fullscreen_exit),

                /// 最小化
                onPressed: () {
                  ref
                      .read(mobileCallSessionControllerProvider.notifier)
                      .minimize();
                },
              ),

              // 右上角挂断按钮（非 PiP 时显示）
              actions: [
                IconButton(
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCallRinging03,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                  onPressed: () async {
                    // 优先释放 PiP 插件，防止原生残留
                    try {
                      await Pip().dispose();
                    } catch (e) {
                      debugPrint('PiP dispose error: $e');
                    }

                    // 结束全局会话状态
                    ref
                        .read(mobileCallSessionControllerProvider.notifier)
                        .end();

                    // 如果已有 token，尝试断开房间连接（异步）
                    if (token != null && token.isNotEmpty) {
                      try {
                        ref
                            .read(roomControllerProvider(token).notifier)
                            .leave();
                      } catch (e) {
                        debugPrint('Leave room error: $e');
                      }
                    }
                  },
                ),
              ],
            ),

      body: _buildBody(token),
    );
  }

  Widget _buildBody(String? token) {
    /// 已存在Token
    if (token != null && token.isNotEmpty) {
      return CallRoomPage(token: token);
    }

    /// 首次拉取Token
    final tokenAsync = ref.watch(roomTokenProvider(widget.roomId));

    return tokenAsync.when(
      data: (newToken) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          ref
              .read(mobileCallSessionControllerProvider.notifier)
              .updateToken(newToken);
        });

        return CallRoomPage(token: newToken);
      },

      error: (err, stack) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              Text('call_window_room_creation_failed'.tr()),

              const SizedBox(height: 12),

              FilledButton(
                onPressed: () {
                  ref.invalidate(roomTokenProvider(widget.roomId));
                },

                child: Text('call_window_retry'.tr()),
              ),
            ],
          ),
        );
      },

      loading: () {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      },
    );
  }
}
