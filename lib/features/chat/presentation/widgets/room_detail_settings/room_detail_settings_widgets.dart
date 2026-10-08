import 'package:anoxia/common/widgets/skeleton_box.dart';
import 'package:anoxia/common/widgets/vibrating_badge.dart';
import 'package:anoxia/framework/provider/chat/room/group_join_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 设置开关行：0.85 紧凑型 Switch，整行可点
///
/// leading 由调用方传入带底色的图标块（与 [RoomSettingTile] 对齐）。
class RoomSwitchTile extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const RoomSwitchTile({
    super.key,
    required this.leading,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      minVerticalPadding: 8,
      leading: leading,
      title: DefaultTextStyle.merge(
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        child: title,
      ),
      subtitle: subtitle == null
          ? null
          : DefaultTextStyle.merge(
              style: const TextStyle(fontSize: 11.5),
              child: subtitle!,
            ),
      trailing: Transform.scale(
        scale: 0.85,
        child: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      onTap: () => onChanged(!value),
    );
  }
}

/// 「入群申请」入口的待处理数量徽标
///
/// 进入设置页时静默刷新一次，数量变化时展示红点徽章。
class JoinRequestsBadge extends ConsumerStatefulWidget {
  final String roomId;

  const JoinRequestsBadge({super.key, required this.roomId});

  @override
  ConsumerState<JoinRequestsBadge> createState() => JoinRequestsBadgeState();
}

class JoinRequestsBadgeState extends ConsumerState<JoinRequestsBadge> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref
          .read(groupJoinRequestsServiceProvider(widget.roomId).notifier)
          .refresh(widget.roomId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = ref.watch(
      pendingGroupJoinRequestCountProvider(widget.roomId),
    );
    return VibratingBadge(count: pendingCount.value ?? 0, size: 16);
  }
}

/// 房间设置面板骨架屏
///
/// 模拟真实布局：成员卡片 + 若干设置行卡片（图标 + 标题 + 尾部箭头）。
class SettingsBodySkeleton extends StatelessWidget {
  const SettingsBodySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // 区块 0：成员行
        const SkeletonCard(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                SkeletonBox(width: 40, height: 40, circle: true),
                SizedBox(width: 12),
                Expanded(child: SkeletonBox(height: 14, radius: 5)),
                SkeletonBox(width: 18, height: 18, radius: 5),
              ],
            ),
          ),
        ),
        // 区块 1：资料/通知等设置行
        SkeletonCard(
          child: Column(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 56, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  child: Row(
                    children: [
                      const SkeletonBox(width: 22, height: 22, radius: 6),
                      const SizedBox(width: 14),
                      Expanded(
                        child: SkeletonLine(width: 96 - (i % 3) * 16, height: 13),
                      ),
                      const SkeletonBox(width: 14, height: 14, radius: 4),
                    ],
                  ),),
              ],
            ],
          ),
        ),
        // 区块 2：危险操作
        const SkeletonCard(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                SkeletonBox(width: 22, height: 22, radius: 6),
                SizedBox(width: 14),
                Expanded(child: SkeletonLine(width: 72, height: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 骨架卡片：与 [RoomCard] 同款圆角容器
class SkeletonCard extends StatelessWidget {
  final Widget child;

  const SkeletonCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(RadiusToken.xl),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}
