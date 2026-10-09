import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/common/widgets/call_button.dart';
import 'package:anoxia/framework/theme/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Windows 独立窗口和应用内呼出页共用展示，不在子窗口启动邀请/WS Provider。
class OutgoingCallView extends StatelessWidget {
  const OutgoingCallView({
    super.key,
    required this.title,
    required this.avatarUrl,
    required this.onCancel,
    this.onMinimize,
    this.speakerAction,
  });

  final String title;
  final String avatarUrl;
  final VoidCallback onCancel;
  final VoidCallback? onMinimize;
  final Widget? speakerAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          gradient: Theme.of(context).extension<AppColors>()?.scaffoldGradient,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxHeight < 440;
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              children: [
                                const Spacer(flex: 3),
                                const SizedBox(height: 24),
                                AvatarWidget(
                                  size: compact ? 80 : 120,
                                  url: avatarUrl,
                                  name: title,
                                ),
                                SizedBox(height: compact ? 16 : 28),
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colors.onSurface,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'call_calling'.tr(),
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Spacer(flex: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (speakerAction != null) ...[
                                      speakerAction!,
                                      const SizedBox(width: 56),
                                    ],
                                    CallActionButton.hangUp(
                                      label: 'call_cancel_call'.tr(),
                                      icon: HugeIcons.strokeRoundedCallEnd01,
                                      onPressed: onCancel,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 28),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (onMinimize != null)
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: IconButton.filledTonal(
                      tooltip: 'call_minimize_tooltip'.tr(),
                      onPressed: onMinimize,
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowDown01,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
