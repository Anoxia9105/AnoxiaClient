import 'package:anoxia/common/utils/sp_util.dart';
import 'package:flutter_riverpod/legacy.dart' as legacy;

/// 用户可选择的桌面端布局方式。
enum DesktopLayoutPreference {
  automatic('auto'),
  card('card'),
  flat('flat');

  const DesktopLayoutPreference(this.storageValue);

  final String storageValue;
}

/// 桌面端当前实际呈现的布局样式。
enum DesktopLayoutStyle { card, flat }

/// 自动布局切换到卡片模式所需的最小窗口宽度。
const double desktopCardLayoutBreakpoint = 1180;

DesktopLayoutPreference parseDesktopLayoutPreference(Object? value) {
  return DesktopLayoutPreference.values.firstWhere(
    (preference) => preference.storageValue == value,
    orElse: () => DesktopLayoutPreference.automatic,
  );
}

DesktopLayoutStyle resolveDesktopLayoutStyle(
  DesktopLayoutPreference preference, {
  required double availableWidth,
}) {
  return switch (preference) {
    DesktopLayoutPreference.card => DesktopLayoutStyle.card,
    DesktopLayoutPreference.flat => DesktopLayoutStyle.flat,
    DesktopLayoutPreference.automatic =>
      availableWidth >= desktopCardLayoutBreakpoint
          ? DesktopLayoutStyle.card
          : DesktopLayoutStyle.flat,
  };
}

class DesktopLayoutController
    extends legacy.StateNotifier<DesktopLayoutPreference> {
  static const String _storageKey = 'desktop_layout_preference';

  DesktopLayoutController() : super(_load());

  static DesktopLayoutPreference _load() {
    return parseDesktopLayoutPreference(
      SPUtil.instance.get(
        _storageKey,
        defValue: DesktopLayoutPreference.automatic.storageValue,
      ),
    );
  }

  void setPreference(DesktopLayoutPreference preference) {
    if (state == preference) return;
    state = preference;
    SPUtil.instance.set(_storageKey, preference.storageValue);
  }
}

final desktopLayoutProvider =
    legacy.StateNotifierProvider<
      DesktopLayoutController,
      DesktopLayoutPreference
    >((ref) => DesktopLayoutController());
