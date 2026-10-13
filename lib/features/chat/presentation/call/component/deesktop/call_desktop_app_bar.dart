import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/constants/desktop_window_chrome.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:anoxia/gen/assets.gen.dart';
import 'package:anoxia/platform/shims/window_manager_shim.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 桌面端通话应用栏组件
///
/// 提供通话窗口的标题栏，包含：
/// - 应用图标和标题
/// - 窗口控制按钮（最小化、最大化/还原、关闭）
/// - 可拖拽移动窗口的区域
class CallDesktopAppbar extends StatefulWidget implements PreferredSizeWidget {
  /// 标题文字
  final String title;

  const CallDesktopAppbar({super.key, required this.title});

  @override
  State<CallDesktopAppbar> createState() => _CallDesktopAppbarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CallDesktopAppbarState extends State<CallDesktopAppbar>
    with WindowListener {
  /// 窗口是否处于最大化状态
  bool _maximized = false;

  @override
  void initState() {
    super.initState();
    if (DeviceUtil.isMacOS()) return;
    windowManager.addListener(this);
    // 异步同步一次真实状态：监听注册前窗口可能已经处于最大化
    Future<void>.microtask(() async {
      final maximized = await windowManager.isMaximized();
      if (mounted) setState(() => _maximized = maximized);
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  /// 以真实状态为准做幂等 set（重复/成对事件不会翻转错位）
  @override
  void onWindowMaximize() {
    if (mounted) setState(() => _maximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => _maximized = false);
  }

  @override
  Widget build(BuildContext context) {
    final isMacOS = DeviceUtil.isMacOS();
    final logo = Center(
      child: Assets.images.appLogo.image(
        width: 24,
        height: 24,
        fit: BoxFit.contain,
        isAntiAlias: true,
        filterQuality: FilterQuality.high,
      ),
    );
    return AppBar(
      centerTitle: DeviceUtil.isRealMobile(),
      title: Text(
        widget.title,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
      ),
      leadingWidth: isMacOS ? macosWindowControlsInset : null,
      leading: isMacOS ? const SizedBox.shrink() : logo,
      elevation: 0,
      actions: isMacOS
          ? [SizedBox(width: 48, child: logo), const SizedBox(width: 8)]
          : [
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'header_minimize'.tr(),
                padding: EdgeInsets.zero,
                onPressed: () {
                  windowManager.minimize();
                },
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedSolidLine01,
                  size: 18,
                ),
              ),
              changeScreenMode(_maximized),
              IconButton(
                tooltip: 'header_closure'.tr(),
                padding: EdgeInsets.zero,
                hoverColor: Colors.red,
                onPressed: () {
                  windowManager.close();
                },
                style: ButtonStyle(
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(RadiusToken.sm),
                    ),
                  ),
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.hovered)) {
                      return Colors.white;
                    }
                    return null;
                  }),
                ),
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCancel01,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
            ],
      flexibleSpace: const DragToMoveArea(child: SizedBox.expand()),
    );
  }

  /// 构建窗口模式切换按钮
  ///
  /// 根据当前窗口状态显示最大化或还原图标。
  /// 按钮按下时按目标方向幂等 set（不翻转），事件到达后再校正，
  /// 双击标题栏 / Win+Up / 系统贴靠等旁路操作也能保持图标正确。
  Widget changeScreenMode(bool maximized) {
    if (maximized) {
      return IconButton(
        tooltip: 'header_reduction'.tr(),
        padding: EdgeInsets.zero,
        onPressed: () {
          setState(() => _maximized = false);
          windowManager.unmaximize();
        },
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedChangeScreenMode,
          size: 18,
        ),
      );
    }
    return IconButton(
      tooltip: 'header_maximize'.tr(),
      padding: EdgeInsets.zero,
      onPressed: () {
        setState(() => _maximized = true);
        windowManager.maximize();
      },
      icon: const HugeIcon(icon: HugeIcons.strokeRoundedSquare, size: 16),
    );
  }
}
