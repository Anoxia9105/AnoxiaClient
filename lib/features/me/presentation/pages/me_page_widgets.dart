import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/common/widgets/skeleton_box.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 「我的」页骨架屏
///
/// 模拟真实布局：顶部资料卡 + 分组标题 + 设置行卡片。
class MePageSkeleton extends StatelessWidget {
  const MePageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: const [
        ProfileCardSkeleton(),
        SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: SkeletonLine(width: 96, height: 13),
        ),
        SizedBox(height: 8),
        TileSectionSkeleton(rows: 4),
        SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: SkeletonLine(width: 72, height: 13),
        ),
        SizedBox(height: 8),
        TileSectionSkeleton(rows: 1),
      ],
    );
  }
}

/// 顶部资料卡骨架（头像 + 昵称/用户名 + 二维码入口）
class ProfileCardSkeleton extends StatelessWidget {
  const ProfileCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(RadiusToken.xl),
      ),
      child: const Row(
        children: [
          SkeletonBox(width: 48, height: 48, circle: true),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SkeletonLine(width: 120, height: 15),
                SizedBox(height: 6),
                SkeletonLine(width: 90, height: 11),
              ],
            ),
          ),
          SkeletonBox(width: 24, height: 24, radius: 6, margin: EdgeInsets.only(left: 8)),
        ],
      ),
    );
  }
}

/// 设置行卡片骨架（图标 + 标题 + 值 + 箭头）
class TileSectionSkeleton extends StatelessWidget {
  final int rows;

  const TileSectionSkeleton({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainer,
      borderRadius: BorderRadius.circular(RadiusToken.xl),
      child: Column(
        children: [
          for (var i = 0; i < rows; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 50,
                endIndent: 14,
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: Row(
                children: [
                  const SkeletonBox(width: 20, height: 20, radius: 5),
                  const SizedBox(width: 16),
                  const SkeletonLine(width: 64, height: 13),
                  const Spacer(),
                  SkeletonBox(width: 88 - (i % 3) * 18, height: 12, radius: 4),
                  const SizedBox(width: 8),
                  const SkeletonBox(width: 18, height: 18, radius: 5),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 分组卡片容器
///
/// 对应原 [_MyPageState._buildTileSection] 的 presentational 抽取
class MeTileSection extends StatelessWidget {
  final List<Widget> children;

  const MeTileSection({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainer,
      borderRadius: BorderRadius.circular(RadiusToken.xl),
      child: Column(children: children),
    );
  }
}

/// 分组标题
///
/// 对应原 [_MyPageState._buildSectionTitle]
class MeSectionTitle extends StatelessWidget {
  final String text;

  const MeSectionTitle({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// 列表分割线
///
/// 对应原 [_MyPageState._buildTileDivider]
class MeTileDivider extends StatelessWidget {
  const MeTileDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Divider(
      height: 1,
      indent: 50,
      endIndent: 14,
      color: cs.outlineVariant.withValues(alpha: 0.5),
    );
  }
}

/// 可编辑行（带图标、标题、值、右箭头）
///
/// 对应原 [_MyPageState._buildEditableTile]
class MeEditableTile extends StatelessWidget {
  final String title;
  final String value;
  final List<List<dynamic>> icon;
  final VoidCallback onTap;

  const MeEditableTile({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      minVerticalPadding: 14,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: HugeIcon(icon: icon, size: 20, color: cs.onSurfaceVariant),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              value.isEmpty ? '--' : value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 4),
          HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 20, color: cs.outline),
        ],
      ),
      onTap: onTap,
    );
  }
}

/// 头像行（展示头像占位与修改入口）
///
/// 对应原 [_MyPageState._buildAvatarTile]
class MeAvatarTile extends StatelessWidget {
  final VoidCallback onTap;

  const MeAvatarTile({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      minVerticalPadding: 10,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      leading: const HugeIcon(icon: HugeIcons.strokeRoundedUserCircle, size: 22),
      title: Text('me_avatar'.tr(), style: const TextStyle(fontSize: 14)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'me_avatar_change'.tr(),
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(width: 4),
          HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 20, color: cs.outline),
        ],
      ),
      onTap: onTap,
    );
  }
}
