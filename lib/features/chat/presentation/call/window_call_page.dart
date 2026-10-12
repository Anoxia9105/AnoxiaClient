import 'package:anoxia/features/chat/presentation/call/component/outgoing_call_view.dart';
import 'dart:convert';
import 'dart:async';

import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/features/chat/presentation/call/call_room_page.dart';
import 'package:anoxia/features/chat/presentation/call/component/call_error_state.dart';
import 'package:anoxia/features/chat/presentation/call/component/call_loading_state.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:anoxia/framework/network/dio_client.dart';
import 'package:anoxia/framework/provider/chat/call/channel.dart';
import 'package:anoxia/framework/provider/chat/call/call_initial_media.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:anoxia/framework/provider/chat/call/call_connection_warmup.dart';
import 'package:anoxia/framework/theme/app_colors.dart';
import 'package:anoxia/framework/theme/app_theme.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:anoxia/platform/shims/desktop_multi_window_shim.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
/// 后通过 callChannel 下发 `on_call_accepted`，再拉取 token 并开始连接。
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
  String _windowSession = '';
  String _avatarUrl = '';
  CallInitialMedia _initialMedia = CallInitialMedia.audio;

  /// 预取/下发的通话 token（振铃态为空）
  String _prefetchedToken = '';

  /// 当前正在使用的通话 token（振铃态为空，用于关闭前断开媒体）
  String _activeToken = '';
  bool _callSettingsInitialized = false;

  /// 是否已进入关闭流程（避免重复清理媒体 / 重复关窗）
  bool _closing = false;
  bool _closeFailed = false;

  /// 通话窗口相位：1:1 呼出未接听时为振铃态
  _CallWindowPhase _phase = _CallWindowPhase.ringing;

  @override
  void initState() {
    super.initState();
    ref.read(callConnectionWarmupProvider).start();
    windowManager.setPreventClose(true);
    windowManager.addListener(this);

    final args = jsonDecode(widget.controller.arguments);
    _themeIndex = args['themeIndex'] ?? 0;
    _title = args['title'] ?? '';
    _roomId = args['roomId'] ?? '';
    _windowSession = args['session']?.toString() ?? '';
    // 多引擎的 TokenManager/SharedPreferences 缓存不会随主窗口登录刷新。
    // HTTP 始终从主窗口领取当前凭据；不写持久化，不放入窗口参数或日志。
    DioClient().configureAuth(
      tokenLoader: () async {
        if (!mounted || _closing) throw StateError('通话窗口已关闭');
        final token = await Channel.callChannel.invokeMethod(
          Channel.callWindowAuthMethod,
          {'roomId': _roomId, 'session': _windowSession},
        );
        if (!mounted || _closing) throw StateError('通话窗口已关闭');
        if (token is! String || token.isEmpty) {
          throw StateError('api_login_expired'.tr());
        }
        return token;
      },
      // 子窗口不独立登出或写回凭据；主窗口负责账号生命周期。
      onUnauthorized: () async {},
    );
    _avatarUrl = args['avatarUrl']?.toString() ?? '';
    _prefetchedToken = args['token']?.toString() ?? '';
    _initialMedia = CallInitialMedia.fromValue(args['initialMedia']);
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
      if (!mounted || _closing) return;
      ref.read(callInitialMediaProvider(_roomId).notifier).state =
          _initialMedia;
      ref.read(callIsGroupProvider(_roomId).notifier).state = isGroup;
      setState(() => _callSettingsInitialized = true);
    });
    if (_phase == _CallWindowPhase.connecting) {
      _activeToken = _prefetchedToken;
    }

    unawaited(_registerCallChannel());
  }

  Future<void> _registerCallChannel() async {
    try {
      await Channel.callChannel.setMethodCallHandler((call) async {
        if (!mounted || _closing) return null;
        if (call.method == Channel.callAcceptedMethod) {
          return _applyAcceptance(
            Map<String, dynamic>.from(call.arguments as Map),
          );
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
      if (!mounted || _closing) return;
      final pending = await Channel.callChannel.invokeMethod(
        Channel.callWindowReadyMethod,
        {'roomId': _roomId, 'session': _windowSession},
      );
      if (pending is Map) _applyAcceptance(Map<String, dynamic>.from(pending));
    } catch (e, st) {
      debugLog('通话窗口就绪握手失败', e, st);
    }
  }

  bool _applyAcceptance(Map<String, dynamic> payload) {
    if (!mounted || _closing) return false;
    if (payload['roomId'] != _roomId || payload['session'] != _windowSession) {
      return false;
    }
    final token = payload['token']?.toString() ?? '';
    _initialMedia = CallInitialMedia.fromValue(payload['initialMedia']);
    if (_callSettingsInitialized) {
      ref.read(callInitialMediaProvider(_roomId).notifier).state =
          _initialMedia;
    }
    setState(() {
      _prefetchedToken = token;
      _activeToken = token;
      _phase = _CallWindowPhase.connecting;
    });
    return true;
  }

  @override
  Future<void> onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();

    if (isPreventClose) {
      await _notifyCloseAndExit();
    }
  }

  /// 先通知主窗口结束通话，再清理媒体并退出。
  ///
  /// **必须在关窗之前断开 LiveKit 媒体连接**：桌面端子窗口销毁时
  /// desktop_multi_window 会直接释放该窗口的 FlutterViewController（引擎），
  /// 而 WebRTC 的原生对象（PeerConnection、采集/播放设备）仍被引擎线程持有，
  /// 带着活跃的通话会话销毁引擎会让原生侧在析构过程中崩溃——由于桌面端所有
  /// 窗口同进程，表现为整个应用闪退。对方挂断场景尤其明显：主窗口收到
  /// CALL_END 后直接关掉本窗口，此前没有任何媒体清理动作。
  Future<void> _notifyCloseAndExit() async {
    if (_closing || !mounted) return;
    // 先进入关闭态，防止系统关闭事件和挂断按钮同时触发两套清理流程。
    setState(() => _closing = true);

    // CALL_END 不能等待媒体清理：disconnect 可能耗时较长，甚至释放失败。
    // 先让对端立即结束通话，媒体清理完成后再通知主窗口清除窗口状态。
    try {
      await Channel.callChannel.invokeMethod(Channel.callWindowEndingMethod);
    } catch (e) {
      debugLog('发送通话结束消息失败', e);
    }

    try {
      // 等待关闭态卸载通话组件，触发视频 renderer 的 dispose，再断开媒体。
      await WidgetsBinding.instance.endOfFrame;
      await _teardownCallMedia();
    } catch (e, st) {
      debugLog('通话资源释放失败，保留窗口引擎', e, st);
      if (mounted) setState(() => _closeFailed = true);
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: e,
          stack: st,
          library: 'anoxia call teardown',
        ),
      );
      return;
    }

    try {
      await Channel.callChannel.invokeMethod(Channel.callWindowCloseMethod);
    } catch (e) {
      debugLog('发送关闭消息失败', e);
    }
    await windowManager.setPreventClose(false);

    await windowManager.close();
  }

  /// 等待媒体完全释放。不能超时后继续关窗：timeout 不会取消原生操作。
  ///
  /// 振铃态（未连接媒体）时直接返回——这里绝不能无条件 read
  /// roomControllerProvider，否则会触发一次新的建连。
  Future<void> _teardownCallMedia() async {
    final token = _activeToken;
    if (token.isEmpty || !mounted) return;
    final container = ProviderScope.containerOf(context, listen: false);
    final provider = roomControllerProvider(token);
    if (!container.exists(provider)) return;
    await container.read(provider.notifier).leave();
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
    // 清理期间不再挂载媒体组件，也不允许重试建连。
    if (_closing) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            (_closeFailed ? 'call_cleanup_failed' : 'call_ending').tr(),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // 1:1 呼出振铃态：不连接媒体，展示振铃页
    if (_phase == _CallWindowPhase.ringing) {
      return OutgoingCallView(
        title: _title,
        avatarUrl: _avatarUrl,
        onCancel: () => _notifyCloseAndExit(),
      );
    }

    if (!_callSettingsInitialized) {
      return const CallLoadingState();
    }

    final tokenAsync = _prefetchedToken.isNotEmpty
        ? AsyncValue.data(_prefetchedToken)
        : ref.watch(roomTokenProvider(_roomId));
    return tokenAsync.when(
      data: (token) {
        _activeToken = token;
        return NotificationListener<CallRetryTokenNotification>(
          onNotification: (notification) {
            if (!_closing) {
              setState(() {
                _prefetchedToken = notification.token;
                _activeToken = notification.token;
              });
            }
            return true;
          },
          child: CallRoomPage(token: token, roomId: _roomId),
        );
      },
      error: (err, stack) => CallErrorState(
        roomId: _roomId,
        title: _title,
        errorText: 'call_window_room_creation_failed'.tr(),
        detail: err.toString(),
        onCancel: _notifyCloseAndExit,
      ),
      loading: () => const CallLoadingState(),
    );
  }
}
