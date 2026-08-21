import 'package:anoxia/features/chat/presentation/call/call_room_page.dart';
import 'package:anoxia/features/chat/presentation/call/component/call_error_state.dart';
import 'package:anoxia/features/chat/presentation/call/component/call_loading_state.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:anoxia/framework/theme/app_colors.dart';
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
    if (!DeviceUtil.isWeb) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
      _keepScreenOn(true);
    }
  }

  @override
  void dispose() {
    if (!DeviceUtil.isWeb) {
      _keepScreenOn(false);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
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
    // 通话外壳跟随应用主题（scaffoldGradient），手机端不再硬编码深色背景。
    final scaffold = Scaffold(
      backgroundColor: Colors.transparent,

      appBar: inPip
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              title: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              leading: IconButton(
                tooltip: 'call_minimize_tooltip'.tr(),
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowDown01,
                  size: 24,
                ),

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
    return Container(
      decoration: BoxDecoration(
        // 全页统一由这一层渐变绘制（AppBar 透明透出），
        // 兜底色防止主题扩展缺失时页面变透明。
        color: Theme.of(context).colorScheme.surface,
        gradient: Theme.of(context).extension<AppColors>()?.scaffoldGradient,
      ),
      child: scaffold,
    );
  }

  Widget _buildBody(String? token) {
    /// 已存在Token
    if (token != null && token.isNotEmpty) {
      return CallRoomPage(token: token, roomId: widget.roomId);
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

        return CallRoomPage(token: newToken, roomId: widget.roomId);
      },

      error: (err, stack) {
        return CallErrorState(
          roomId: widget.roomId,
          title: widget.title,
          errorText: 'call_window_room_creation_failed'.tr(),
          detail: err.toString(),
        );
      },

      loading: () => const CallLoadingState(),
    );
  }
}
