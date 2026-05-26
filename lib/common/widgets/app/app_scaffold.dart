import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/desktop/DesktopAppBar.dart';
import 'package:anoxia/common/widgets/desktop/GlobalSearchDialog.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/framework/theme/AppColors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

/// 应用通用 Scaffold 组件
/// 根据设备类型自动适配：
/// - 桌面端：带有应用栏和全局快捷键支持
/// - 移动端：简洁的 Scaffold，无应用栏
/// 提供全局快捷键（Ctrl/Cmd + K）触发全局搜索弹窗
/// 使用渐变背景和系统状态栏样式适配，提升整体视觉一致性
class AppScaffold extends StatefulWidget {
  final Widget body;
  final Widget? bottomNavigationBar;
  final bool hideAppBarLogo;
  final bool showDesktopHeaderEnhancements;

  const AppScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
    this.hideAppBarLogo = false,
    this.showDesktopHeaderEnhancements = false,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  // 定义全局快捷键：Ctrl + K (或 Mac 上的 Cmd + K)
  final HotKey _searchHotKey = HotKey(
    key: PhysicalKeyboardKey.keyK,
    modifiers: [
      // 自动适配：Windows/Linux 下为 Control，Mac 下为 Meta(Cmd)
      DeviceUtil.isRealDesktop() && DeviceUtil.isMacOS()
          ? HotKeyModifier.meta
          : HotKeyModifier.control,
    ],
    scope: HotKeyScope.inapp,
  );

  /// 是否已经打开搜索弹窗，防止重复打开
  bool _isSearchDialogOpen = false;
  @override
  void initState() {
    super.initState();
    if (DeviceUtil.isRealDesktop()) {
      _initGlobalHotKey();
    }
  }

  /// 注册全局热键
  Future<void> _initGlobalHotKey() async {
    try {
      await hotKeyManager.register(
        _searchHotKey,
        keyDownHandler: (hotKey) {
          _openGlobalSearch();
        },
      );
    } catch (e) {
      log.error('hotkey_manager: 注册失败，错误信息为: $e');
    }
  }

  /// 触发打开搜索弹窗
  void _openGlobalSearch() {
    // 检查当前上下文是否还能安全弹窗
    if (!mounted) return;

    /// 如果已经打开搜索弹窗，则不再重复打开，避免多个弹窗叠加
    if (_isSearchDialogOpen) return;
    
    /// 上锁状态，直到弹窗关闭时才允许再次打开
    _isSearchDialogOpen = true;
    showDialog(context: context, builder: (_) => GlobalSearchDialog()).then((
      _,
    ) {
      /// 无论弹窗是正常关闭还是通过其他方式关闭，都重置状态，允许下次再次打开
      _isSearchDialogOpen = false;
    });
  }

  @override
  void dispose() {
    if (DeviceUtil.isRealDesktop()) {
      // 页面销毁时必须注销热键，防止内存泄漏
      hotKeyManager.unregister(_searchHotKey);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = Theme.of(context).extension<AppColors>()?.scaffoldGradient;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    );

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
        // 彻底移除了原先的 CallbackShortcuts 和 Focus 组件
        child: Scaffold(
          appBar: () {
            if (DeviceUtil.isRealDesktop()) {
              return DesktopAppBar(
                hideAppBarLogo: widget.hideAppBarLogo,
                showHeaderEnhancements: widget.showDesktopHeaderEnhancements,
              );
            }
            return null;
          }(),
          body: widget.body,
          bottomNavigationBar: widget.bottomNavigationBar,
        ),
      ),
    );
  }
}
