import 'dart:convert';

import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/features/chat/presentation/call/call_room_page.dart';
import 'package:anoxia/features/chat/presentation/call/component/call_error_state.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:anoxia/framework/provider/chat/call/channel.dart';
import 'package:anoxia/framework/provider/chat/call/call_initial_media.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:anoxia/framework/theme/app_colors.dart';
import 'package:anoxia/framework/theme/app_theme.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:anoxia/platform/shims/desktop_multi_window_shim.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/platform/shims/window_manager_shim.dart';

import 'component/deesktop/call_desktop_app_bar.dart';

/// 通话窗口相位：振铃（1:1 呼出，未连接媒体）/ 连接（媒体建立中或已建立）
enum _CallWindowPhase { ringing, connecting }

/// 桌面端通话窗口页面
///
/// 作为独立窗口运行，用于桌面端通话功能。
/// 负责处理：
/// - 窗口参数解析（主题、标题、房间ID）
/// - 跨窗口通信（主题切换、语言切换、接听通知）
/// - 窗口关闭事件处理
/// - 房间令牌获取
///
/// 1:1 呼出时窗口先进入「振铃态」（不连接媒体），主窗口收到 CALL_ACCEPT
/// 后通过 callChannel 下发 `on_call_accepted`（携带新 token）再开始连接。
class WindowCallPage extends ConsumerStatefulWidget {
  /// 多窗口控制器
  final WindowController controller;

  const WindowCallPage({super.key, required this.controller});

  @override
  ConsumerState createState() => _CallWindowPageState();
}

class _CallWindowPageState extends ConsumerState<WindowCallPage>
    with WindowListener {
  /// 当前主题索引
  int _themeIndex = 0;

  /// 窗口标题
  String _title = '';

  /// 房间ID
  String _roomId = '';

  /// 预取/下发的通话 token（振铃态为空）
  String _prefetchedToken = '';
  bool _callSettingsInitialized = false;

  /// 通话窗口相位：1:1 呼出未接听时为振铃态
  _CallWindowPhase _phase = _CallWindowPhase.ringing;

  @override
  void initState() {
    super.initState();
    windowManager.setPreventClose(true);
    windowManager.addListener(this);
    debugLog('初始化通话页面,接收到参数>>>>>>${widget.controller.arguments}');

    final args = jsonDecode(widget.controller.arguments);
    _themeIndex = args['themeIndex'] ?? 0;
    _title = args['title'] ?? '';
    _roomId = args['roomId'] ?? '';
    _prefetchedToken = args['token']?.toString() ?? '';
    final initialMedia = CallInitialMedia.fromValue(args['initialMedia']);
    final isGroup = args['isGroup'] == true || args['isGroup'] == 'true';
    final isJoin = args['join'] == true || args['join'] == 'true';

    // 携带 token 或 join（群呼发起/加入进行中通话）→ 直接连接媒体；
    // 否则 = 1:1 呼出振铃，等主窗口下发 on_call_accepted。
    _phase = (_prefetchedToken.isNotEmpty || isJoin)
        ? _CallWindowPhase.connecting
        : _CallWindowPhase.ringing;

    // Riverpod forbids changing providers synchronously from initState because
    // the parent widget tree can still be building. Initialize them after the
    // first frame, and keep CallRoomPage out of the tree until they are ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(callInitialMediaProvider(_roomId).notifier).state = initialMedia;
      ref.read(callIsGroupProvider(_roomId).notifier).state = isGroup;
      setState(() => _callSettingsInitialized = true);
    });
    if (_phase == _CallWindowPhase.connecting) {
      ref.read(roomTokenProvider(_roomId));
    }

    Channel.callChannel.setMethodCallHandler((call) async {
      debugLog('CAll|>>> 收到数据$call');
      if (call.method == 'on_call_accepted') {
        // 主窗口收到对方 CALL_ACCEPT 后下发：振铃 → 连接
        final token =
            (call.arguments is Map ? call.arguments as Map : null)?['token']
                ?.toString() ??
            '';
        if (token.isEmpty) return;
        setState(() {
          _prefetchedToken = token;
          _phase = _CallWindowPhase.connecting;
        });
        return;
      }
      if (call.method == Channel.callChannelMethod) {
        final data = call.arguments as Map;
        setState(() {
          if (data.containsKey('themeIndex')) {
            _themeIndex = data['themeIndex'];
          }
          if (data.containsKey('locale')) {
            String localeCode = data['locale'];
            context.setLocale(Locale(localeCode));
          }
        });
      }
    });
  }

  @override
  Future<void> onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();

    if (isPreventClose) {
      await _notifyCloseAndExit();
    }
  }

  /// 通知主窗口窗口关闭（主窗口据此发 CALL_CANCEL / CALL_END）并退出。
  Future<void> _notifyCloseAndExit() async {
    try {
      await Channel.callChannel.invokeMethod('on_call_window_close');
    } catch (e) {
      debugLog('发送关闭消息失败', e);
    }
    await windowManager.setPreventClose(false);

    await windowManager.close();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    Channel.callChannel.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = AppTheme.getTheme(index: _themeIndex);

    return MaterialApp(
      title: _title,
      scaffoldMessengerKey: Toast.messengerKey,
      theme: themeData,
      builder: BotToastInit(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      navigatorObservers: [BotToastNavigatorObserver()],
      home: Container(
        decoration: BoxDecoration(
          gradient: themeData.extension<AppColors>()?.scaffoldGradient,
        ),
        child: Scaffold(
          appBar: CallDesktopAppbar(title: _title),
          body: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    // 1:1 呼出振铃态：不连接媒体，展示振铃页
    if (_phase == _CallWindowPhase.ringing) {
      return _DesktopCallRingingPage(
        title: _title,
        onCancel: _notifyCloseAndExit,
      );
    }

    if (!_callSettingsInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final tokenAsync = _prefetchedToken.isNotEmpty
        ? AsyncValue.data(_prefetchedToken)
        : ref.watch(roomTokenProvider(_roomId));
    return tokenAsync.when(
      data: (token) {
        debugLog('Token 获取成功（开始启动通话）: $token');
        return CallRoomPage(token: token, roomId: _roomId);
      },
      error: (err, stack) => CallErrorState(
        roomId: _roomId,
        title: _title,
        errorText: 'call_window_room_creation_failed'.tr(),
        detail: err.toString(),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

/// 桌面端呼出振铃页（1:1，窗口内展示）
///
/// 对方名称 + 「正在呼叫…」+ 取消（挂断）按钮。振铃期不连接媒体。
class _DesktopCallRingingPage extends StatelessWidget {
  const _DesktopCallRingingPage({
    required this.title,
    required this.onCancel,
  });

  final String title;
  final Future<void> Function() onCancel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary.withValues(alpha: 0.12),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedCall02,
              color: cs.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'call_calling'.tr(),
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
          ),
          const SizedBox(height: 36),
          FilledButton.icon(
            onPressed: onCancel,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE53945),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            ),
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedCallEnd01,
              size: 18,
              color: Colors.white,
            ),
            label: Text('call_cancel_call'.tr()),
          ),
        ],
      ),
    );
  }
}
