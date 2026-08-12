import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/desktop/desktop_app_bar.dart';
import 'package:anoxia/common/widgets/app/app_background_layer.dart';
import 'package:anoxia/common/widgets/desktop/global_search_dialog.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:anoxia/framework/domain/app_background.dart';
import 'package:anoxia/framework/provider/theme/theme_controller.dart';
import 'package:anoxia/framework/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anoxia/platform/shims/hotkey_manager_shim.dart';

/// 应用通用 Scaffold 组件
/// 根据设备类型自动适配：
/// - 桌面端：带有应用栏和全局快捷键支持
/// - 移动端：简洁的 Scaffold，无应用栏
/// 提供全局快捷键（Ctrl/Cmd + K）触发全局搜索弹窗
/// 使用渐变背景和系统状态栏样式适配，提升整体视觉一致性
class AppScaffold extends ConsumerStatefulWidget {
  final Widget body;
  final Widget? title;
  final Widget? bottomNavigationBar;
  final bool hideAppBarLogo;
  final bool showDesktopHeaderEnhancements;
  final bool showWebNavigationBar;

  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.bottomNavigationBar,
    this.hideAppBarLogo = false,
    this.showDesktopHeaderEnhancements = false,
    this.showWebNavigationBar = false,
  });

  @override
  ConsumerState<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends ConsumerState<AppScaffold> {
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
      debugLog('hotkey_manager: 注册失败，错误信息为: $e');
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
    final PreferredSizeWidget? appBar;
    if (DeviceUtil.isRealDesktop()) {
      appBar = DesktopAppBar(
        hideAppBarLogo: widget.hideAppBarLogo,
        showHeaderEnhancements: widget.showDesktopHeaderEnhancements,
        title: widget.title,
      );
    } else if (DeviceUtil.isWeb && widget.showWebNavigationBar) {
      appBar = AppBar(automaticallyImplyLeading: true, title: widget.title);
    } else {
      appBar = null;
    }

    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    );

    final supportsBackground = DeviceUtil.supportsCustomBackground(context);
    final backgroundState = ref.watch(appBackgroundProvider);
    final candidateAsset = backgroundState.activeAsset;
    final activeAsset =
        supportsBackground &&
            (candidateAsset?.type != AppBackgroundMediaType.video ||
                DeviceUtil.supportsVideoBackground())
        ? candidateAsset
        : null;
    final baseTheme = Theme.of(context);
    final contentTheme = activeAsset == null
        ? baseTheme
        : _transparentContentTheme(baseTheme, backgroundState.surfaceOpacity);

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (activeAsset != null)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: AppBackgroundLayer(
                  key: ValueKey(activeAsset.id),
                  asset: activeAsset,
                ),
              ),
            Theme(
              data: contentTheme,
              child: Scaffold(
                backgroundColor: Colors.transparent,
                appBar: appBar,
                body: widget.body,
                bottomNavigationBar: widget.bottomNavigationBar,
              ),
            ),
          ],
        ),
      ),
    );
  }

  ThemeData _transparentContentTheme(ThemeData theme, double opacity) {
    final colors = theme.colorScheme;
    Color glass(Color color) => color.withValues(alpha: opacity);
    return theme.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: glass(colors.surface),
      cardColor: glass(colors.surface),
      colorScheme: colors.copyWith(
        surface: glass(colors.surface),
        surfaceContainerLowest: glass(colors.surfaceContainerLowest),
        surfaceContainerLow: glass(colors.surfaceContainerLow),
        surfaceContainer: glass(colors.surfaceContainer),
        surfaceContainerHigh: glass(colors.surfaceContainerHigh),
        surfaceContainerHighest: glass(colors.surfaceContainerHighest),
      ),
      cardTheme: theme.cardTheme.copyWith(color: glass(colors.surface)),
      dialogTheme: theme.dialogTheme.copyWith(
        backgroundColor: glass(colors.surface),
      ),
    );
  }
}
