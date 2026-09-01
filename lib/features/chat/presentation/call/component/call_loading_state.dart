import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 通话加载中状态组件
///
/// 通话初始化 / 等待加入期间的统一占位：「转圈 + 文案」。
/// 通话为全屏即时场景、布局不可预测，不使用骨架屏；
/// 各通话入口（房间页 / 悬浮窗 / 移动端页）统一复用本组件，保证观感一致。
class CallLoadingState extends StatelessWidget {
  /// 加载提示文案（默认「正在进入通话…」）
  final String? message;

  const CallLoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 14),
          Text(
            message ?? 'call_loading'.tr(),
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.w400,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
