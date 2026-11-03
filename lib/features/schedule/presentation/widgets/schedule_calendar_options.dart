import 'dart:math' as math;
import 'package:anoxia/common/widgets/bubble_dialog.dart';
import 'package:anoxia/framework/theme/composer_frame.dart';
import 'package:anoxia/framework/domain/schedule_holiday.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ScheduleCalendarOptions extends StatelessWidget {
  final ScheduleHolidayRegion region;
  final bool showLunar;
  final ValueChanged<ScheduleHolidayRegion> onRegionChanged;
  final ValueChanged<bool> onLunarChanged;

  const ScheduleCalendarOptions({
    super.key,
    required this.region,
    required this.showLunar,
    required this.onRegionChanged,
    required this.onLunarChanged,
  });

  @override
  Widget build(BuildContext context) => IconButton(
    key: const ValueKey('schedule-calendar-options'),
    tooltip: 'schedule_calendar_options'.tr(),
    icon: const Icon(Icons.tune),
    onPressed: () => _show(context),
  );

  Future<void> _show(BuildContext context) async {
    final anchor = context.findRenderObject();
    if (anchor is! RenderBox || !anchor.hasSize) return;
    final result = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (popupContext, _, _) => LayoutBuilder(
        builder: (popupContext, constraints) {
          if (!anchor.attached || !anchor.hasSize) {
            return const SizedBox.shrink();
          }
          final media = MediaQuery.of(popupContext);
          const edge = 12.0;
          const arrowLength = 10.0;
          final screen = Size(
            constraints.maxWidth,
            constraints.maxHeight -
                math.max(media.padding.bottom, media.viewInsets.bottom),
          );
          final width = math.min(280.0, screen.width - 2 * edge);
          if (width < 64) return const SizedBox.shrink();
          final rect = anchor.localToGlobal(Offset.zero) & anchor.size;
          final placement = resolveAnchoredBubblePlacement(
            targetRect: rect,
            screenSize: screen,
            bubbleWidth: width,
            estimatedHeight: 258,
            preferRightArrow: true,
            arrowInset: 22,
            safeTop: media.padding.top,
          );
          final colors = Theme.of(context).colorScheme;
          return Stack(
            children: [
              Positioned(
                left: placement.left,
                width: width,
                top: placement.showBelow ? placement.anchorY : null,
                bottom: placement.showBelow
                    ? null
                    : constraints.maxHeight - placement.anchorY,
                child: InheritedTheme.captureAll(
                  context,
                  BubbleWidget(
                    arrowDirection: placement.arrowDirection,
                    arrowOffset: placement.arrowOffset,
                    arrowLength: arrowLength,
                    borderRadius: ComposerFrame.radius,
                    border: ComposerFrame.side(colors),
                    backgroundColor: colors.surfaceContainerLow,
                    shadows: [
                      BoxShadow(
                        color: colors.shadow.withValues(alpha: .16),
                        blurRadius: 18,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    contentBuilder: (_) => Material(
                      color: Colors.transparent,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: math.max(
                            0,
                            placement.maxHeight - arrowLength,
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                dense: true,
                                title: Text('schedule_holiday_region'.tr()),
                              ),
                              for (final item in ScheduleHolidayRegion.values)
                                _option(
                                  popupContext,
                                  item.name,
                                  'schedule_region_${item.name}'.tr(),
                                  item == region,
                                ),
                              const Divider(height: 1),
                              _option(
                                popupContext,
                                'lunar',
                                'schedule_show_lunar'.tr(),
                                showLunar,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
    if (!context.mounted || result == null) return;
    if (result == 'lunar') {
      onLunarChanged(!showLunar);
    } else {
      onRegionChanged(ScheduleHolidayRegion.values.byName(result));
    }
  }

  Widget _option(
    BuildContext context,
    String value,
    String label,
    bool selected,
  ) => ListTile(
    dense: true,
    selected: selected,
    leading: Icon(
      selected ? Icons.check_rounded : Icons.circle_outlined,
      size: 16,
    ),
    title: Text(label),
    onTap: () => Navigator.of(context).pop(value),
  );
}

String scheduleHolidayName(String name) {
  const names = {
    '元旦': 'new_year',
    '春节': 'spring_festival',
    '清明节': 'qingming',
    '劳动节': 'labour_day',
    '端午节': 'dragon_boat',
    '中秋节': 'mid_autumn',
    '国庆节': 'national_day',
    '元日': 'jp_new_year',
    '成人の日': 'coming_of_age',
    '建国記念の日': 'foundation',
    '天皇誕生日': 'emperor_birthday',
    '春分の日': 'vernal_equinox',
    '昭和の日': 'showa',
    '憲法記念日': 'constitution',
    'みどりの日': 'greenery',
    'こどもの日': 'children',
    '海の日': 'marine',
    '山の日': 'mountain',
    '敬老の日': 'respect_aged',
    '秋分の日': 'autumn_equinox',
    'スポーツの日': 'sports',
    '文化の日': 'culture',
    '勤労感謝の日': 'labour_thanks',
    '休日': 'jp_holiday',
  };
  final key = names[name];
  return key == null ? name : 'schedule_holiday_$key'.tr();
}
