import 'package:anoxia/features/chat/presentation/call/call_room_page.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  }

  @override
  void dispose() {
    _keepScreenOn(false);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(mobileCallSessionControllerProvider);

    final inPip = session?.isInPipMode ?? false;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),

      appBar: inPip
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF0D0F14),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              title: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              leading: IconButton(
                tooltip: 'call_minimize_tooltip'.tr(),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),

                /// 最小化
                onPressed: () {
                  ref
                      .read(mobileCallSessionControllerProvider.notifier)
                      .minimize();
                },
              ),
            ),

      body: _buildBody(session?.token),
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
