/// 功能页面欢迎/空状态面板组件。
///
/// 提供带进场动画的欢迎页，包含图标、标题、描述和功能特性卡片，
/// 用于聊天、联系人等功能页面的空状态展示。
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';

/// 欢迎页功能特性数据模型。
class WelcomeFeature {
  /// 功能特性图标。
  final List<List<dynamic>> icon;

  /// 功能特性标题的国际化键。
  final String titleKey;

  /// 功能特性描述的国际化键。
  final String descriptionKey;

  const WelcomeFeature({
    required this.icon,
    required this.titleKey,
    required this.descriptionKey,
  });
}

/// Reusable welcome and empty-state panel for feature pages.
class Welcome extends StatefulWidget {
  /// 欢迎页图标。
  final List<List<dynamic>> icon;

  /// 标题的国际化键。
  final String titleKey;

  /// 描述的国际化键。
  final String descriptionKey;

  /// 功能特性列表。
  final List<WelcomeFeature> features;

  /// 底部操作按钮。
  final Widget? action;

  /// 卡片最大宽度。
  final double maxWidth;

  const Welcome({
    super.key,
    this.icon = HugeIcons.strokeRoundedSparkles,
    this.titleKey = 'welcome_default_title',
    this.descriptionKey = 'welcome_default_description',
    this.features = const [],
    this.action,
    this.maxWidth = 560,
  });

  /// 聊天页欢迎面板的预设构造器。
  const Welcome.chat({super.key})
    : icon = HugeIcons.strokeRoundedChatting01,
      titleKey = 'welcome_chat_title',
      descriptionKey = 'welcome_chat_description',
      features = const [
        WelcomeFeature(
          icon: HugeIcons.strokeRoundedMessage01,
          titleKey: 'welcome_chat_feature_messages_title',
          descriptionKey: 'welcome_chat_feature_messages_description',
        ),
        WelcomeFeature(
          icon: HugeIcons.strokeRoundedCall02,
          titleKey: 'welcome_chat_feature_call_title',
          descriptionKey: 'welcome_chat_feature_call_description',
        ),
        WelcomeFeature(
          icon: HugeIcons.strokeRoundedFileAttachment,
          titleKey: 'welcome_chat_feature_files_title',
          descriptionKey: 'welcome_chat_feature_files_description',
        ),
      ],
      action = null,
      maxWidth = 620;

  /// 联系人页欢迎面板的预设构造器。
  const Welcome.contacts({super.key})
    : icon = HugeIcons.strokeRoundedUserGroup,
      titleKey = 'welcome_contacts_title',
      descriptionKey = 'welcome_contacts_description',
      features = const [
        WelcomeFeature(
          icon: HugeIcons.strokeRoundedUserAdd01,
          titleKey: 'welcome_contacts_feature_add_title',
          descriptionKey: 'welcome_contacts_feature_add_description',
        ),
        WelcomeFeature(
          icon: HugeIcons.strokeRoundedUserMultiple,
          titleKey: 'welcome_contacts_feature_groups_title',
          descriptionKey: 'welcome_contacts_feature_groups_description',
        ),
        WelcomeFeature(
          icon: HugeIcons.strokeRoundedUserAccount,
          titleKey: 'welcome_contacts_feature_profile_title',
          descriptionKey: 'welcome_contacts_feature_profile_description',
        ),
      ],
      action = null,
      maxWidth = 620;

  @override
  State<Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> with TickerProviderStateMixin {
  // 进场动画：图标 -> 标题 -> 描述 -> 卡片，依次淡入上滑
  late final AnimationController _enterCtrl;
  // 图标呼吸/漂浮动画，循环播放
  late final AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  Animation<double> _fade(double start, double end) {
    return CurvedAnimation(
      parent: _enterCtrl,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
  }

  Animation<Offset> _slide(double start, double end) {
    return Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _enterCtrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 32.h),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.maxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 图标：淡入缩放 + 循环漂浮
              FadeTransition(
                opacity: _fade(0.0, 0.5),
                child: ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _enterCtrl,
                    curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
                  ),
                  child: AnimatedBuilder(
                    animation: _floatCtrl,
                    builder: (context, child) {
                      final dy = -4 * (_floatCtrl.value - 0.5) * 2;
                      return Transform.translate(
                        offset: Offset(0, dy),
                        child: child,
                      );
                    },
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primary.withValues(alpha: 0.85),
                            colorScheme.primary.withValues(alpha: 0.55),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.28),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: HugeIcon(
                          icon: widget.icon,
                          size: 38,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              FadeTransition(
                opacity: _fade(0.15, 0.65),
                child: SlideTransition(
                  position: _slide(0.15, 0.65),
                  child: Text(
                    widget.titleKey.tr(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      height: 1.2,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              FadeTransition(
                opacity: _fade(0.25, 0.75),
                child: SlideTransition(
                  position: _slide(0.25, 0.75),
                  child: Text(
                    widget.descriptionKey.tr(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.55,
                    ),
                  ),
                ),
              ),
              if (widget.features.isNotEmpty) ...[
                SizedBox(height: 28.h),
                _FeatureGrid(features: widget.features, enterCtrl: _enterCtrl),
              ],
              if (widget.action != null) ...[
                SizedBox(height: 28.h),
                FadeTransition(
                  opacity: _fade(0.55, 1.0),
                  child: SlideTransition(
                    position: _slide(0.55, 1.0),
                    child: widget.action!,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  final List<WelcomeFeature> features;
  final AnimationController enterCtrl;

  const _FeatureGrid({required this.features, required this.enterCtrl});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 520;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < features.length; i++)
              SizedBox(
                width: isNarrow ? constraints.maxWidth : 188,
                child: _FeatureItem(
                  feature: features[i],
                  enterCtrl: enterCtrl,
                  // 每张卡片依次错开进场，形成层次感
                  start: 0.4 + i * 0.12,
                  end: 0.75 + i * 0.12,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FeatureItem extends StatefulWidget {
  final WelcomeFeature feature;
  final AnimationController enterCtrl;
  final double start;
  final double end;

  const _FeatureItem({
    required this.feature,
    required this.enterCtrl,
    required this.start,
    required this.end,
  });

  @override
  State<_FeatureItem> createState() => _FeatureItemState();
}

class _FeatureItemState extends State<_FeatureItem> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final end = widget.end.clamp(0.0, 1.0);
    final start = widget.start.clamp(0.0, end - 0.01);

    final fade = CurvedAnimation(
      parent: widget.enterCtrl,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: widget.enterCtrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );

    final scale = _pressed
        ? 0.97
        : _hovered
        ? 1.03
        : 1.0;

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                constraints: const BoxConstraints(minHeight: 116),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _hovered
                      ? colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.7,
                        )
                      : colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.42,
                        ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _hovered
                        ? colorScheme.primary.withValues(alpha: 0.4)
                        : colorScheme.outlineVariant,
                  ),
                  boxShadow: _hovered
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.14),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HugeIcon(
                      icon: widget.feature.icon,
                      size: 22,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.feature.titleKey.tr(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.feature.descriptionKey.tr(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}