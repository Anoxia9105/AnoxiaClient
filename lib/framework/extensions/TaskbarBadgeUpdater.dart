import 'package:windows_taskbar/windows_taskbar.dart';
import 'package:anoxia/gen/assets.gen.dart';

class TaskbarBadgeUpdater {
  static int? _lastCount;

  static Future<void> updateBadge(int count) async {
    if (count == _lastCount) return;
    _lastCount = count;

    if (count <= 0) {
      WindowsTaskbar.resetOverlayIcon();
      return;
    }

    String assetPath;
    if (count > 9) {
      assetPath = Assets.images.badge.badgeMore;
    } else {
      final badges = [
        Assets.images.badge.badge1,
        Assets.images.badge.badge2,
        Assets.images.badge.badge3,
        Assets.images.badge.badge4,
        Assets.images.badge.badge5,
        Assets.images.badge.badge6,
        Assets.images.badge.badge7,
        Assets.images.badge.badge8,
        Assets.images.badge.badge9,
      ];
      assetPath = badges[count - 1];
    }

    try {
      // 3. 设置角标
      WindowsTaskbar.setOverlayIcon(ThumbnailToolbarAssetIcon(assetPath));
    } catch (e) {
      print("任务栏角标更新失败: $e");
    }
  }
}
