import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hugeicons/hugeicons.dart';

class DiscoverPage extends ConsumerWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // 头部标题
          SliverAppBar(
            backgroundColor: colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'sidebar_discover'.tr(),
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: false,
            pinned: true,
            floating: true,
          ),
          
          // 发现内容区域
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 群聊发现
                _buildSection(
                  context,
                  title: 'discover_group_chat'.tr(),
                  subtitle: 'discover_group_chat_subtitle'.tr(),
                  icon: HugeIcons.strokeRoundedUser02,
                  onTap: () {
                    // TODO: 跳转到群聊发现页面
                  },
                ),
                
                const SizedBox(height: 16),
                
                // 附近的人
                _buildSection(
                  context,
                  title: 'discover_nearby_people'.tr(),
                  subtitle: 'discover_nearby_people_subtitle'.tr(),
                  icon: HugeIcons.strokeRoundedLocation01,
                  onTap: () {
                    // TODO: 跳转到附近的人页面
                  },
                ),
                
                const SizedBox(height: 16),
                
                // 好友推荐
                _buildSection(
                  context,
                  title: 'discover_friend_recommendation'.tr(),
                  subtitle: 'discover_friend_recommendation_subtitle'.tr(),
                  icon: HugeIcons.strokeRoundedUserAdd01,
                  onTap: () {
                    // TODO: 跳转到好友推荐页面
                  },
                ),
                
                const SizedBox(height: 16),
                
                // 热门话题
                _buildSection(
                  context,
                  title: 'discover_hot_topics'.tr(),
                  subtitle: 'discover_hot_topics_subtitle'.tr(),
                  icon: HugeIcons.strokeRoundedFire,
                  onTap: () {
                    // TODO: 跳转到热门话题页面
                  },
                ),
                
                const SizedBox(height: 16),
                
                // 文件管理
                _buildSection(
                  context,
                  title: 'discover_file_manager'.tr(),
                  subtitle: 'discover_file_manager_subtitle'.tr(),
                  icon: HugeIcons.strokeRoundedFolder01,
                  onTap: () {
                    // TODO: 跳转到文件管理页面
                  },
                ),
                
                const SizedBox(height: 16),
                
                // 收藏夹
                _buildSection(
                  context,
                  title: 'discover_favorites'.tr(),
                  subtitle: 'discover_favorites_subtitle'.tr(),
                  icon: HugeIcons.strokeRoundedBookmark01,
                  onTap: () {
                    // TODO: 跳转到收藏夹页面
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<List<dynamic>> icon,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: HugeIcon(
              icon: icon,
              size: 20,
              color: colorScheme.primary,
            ),
          ),
        ),
        title: Text(
          title,
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}