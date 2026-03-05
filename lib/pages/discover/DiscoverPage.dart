import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hugeicons/hugeicons.dart';

class DiscoverPage extends ConsumerWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      // appBar: AppBar(title: Text('ai_chat_title'.tr())),
      body: Center(child: Text('功能开发中，敬请期待...')),
    );
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
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
            pinned: true,
            floating: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () => _showSearch(context),
                tooltip: 'search'.tr(),
              ),
            ],
          ),

          // padding + content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 搜索栏
                _buildSearchBar(context),
                const SizedBox(height: 12),

                // 横幅卡片
                _buildBanner(context),
                const SizedBox(height: 16),

                // 功能网格
                _buildFeatureGrid(context),
                const SizedBox(height: 18),

                // 热门话题
                _buildSectionHeader(context, title: 'discover_hot_topics'.tr()),
                const SizedBox(height: 8),
                _buildHotTopics(context),
                const SizedBox(height: 18),

                // 最近文件（示例）
                _buildSectionHeader(
                  context,
                  title: 'discover_recent_files'.tr(),
                ),
                const SizedBox(height: 8),
                _buildRecentFiles(context),
                const SizedBox(height: 48),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => _showSearch(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, size: 20),
            const SizedBox(width: 8),
            Text(
              'discover_search_placeholder'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            const Icon(Icons.mic_none_rounded, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showFeatureDetail(context, title: 'discover_events'.tr()),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'discover_events_title'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'discover_events_subtitle'.tr(),
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.explore, size: 32, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    final features = <_FeatureItem>[
      _FeatureItem(
        key: 'discover_group_chat',
        icon: HugeIcons.strokeRoundedUser02,
      ),
      _FeatureItem(
        key: 'discover_nearby_people',
        icon: HugeIcons.strokeRoundedLocation01,
      ),
      _FeatureItem(
        key: 'discover_friend_recommendation',
        icon: HugeIcons.strokeRoundedUserAdd01,
      ),
      _FeatureItem(
        key: 'discover_hot_topics',
        icon: HugeIcons.strokeRoundedFire,
      ),
      _FeatureItem(
        key: 'discover_file_manager',
        icon: HugeIcons.strokeRoundedFolder01,
      ),
      _FeatureItem(
        key: 'discover_favorites',
        icon: HugeIcons.strokeRoundedBookmark01,
      ),
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: features.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, index) {
        final f = features[index];
        return _buildFeatureCard(context, f);
      },
    );
  }

  Widget _buildFeatureCard(BuildContext context, _FeatureItem item) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showFeatureDetail(context, title: item.title),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: item.icon,
                    size: 22,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, {required String title}) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Text(
          'discover_more'.tr(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildHotTopics(BuildContext context) {
    final topics = <String>[
      '#${'topic_1'.tr()}',
      '#${'topic_2'.tr()}',
      '#${'topic_3'.tr()}',
      '#${'topic_4'.tr()}',
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: topics.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final t = topics[index];
          return ActionChip(
            label: Text(t),
            onPressed: () => _showFeatureDetail(context, title: t),
          );
        },
      ),
    );
  }

  Widget _buildRecentFiles(BuildContext context) {
    final files = <Map<String, String>>[
      {'name': 'Design.pdf', 'meta': '2.1MB'},
      {'name': 'MeetingNotes.txt', 'meta': '14KB'},
      {'name': 'Vacation.jpg', 'meta': '1.4MB'},
    ];

    return Column(
      children: files.map((f) {
        return Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            leading: const Icon(Icons.insert_drive_file_outlined),
            title: Text(f['name'] ?? ''),
            subtitle: Text(f['meta'] ?? ''),
            trailing: const Icon(Icons.more_horiz),
            onTap: () => _showFeatureDetail(context, title: f['name'] ?? ''),
          ),
        );
      }).toList(),
    );
  }

  void _showSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'discover_search_placeholder'.tr(),
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showFeatureDetail(BuildContext context, {required String title}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('discover_feature_placeholder'.tr()),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('ok'.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem {
  final String key;
  final dynamic icon;
  _FeatureItem({required this.key, required this.icon});

  String get title => key.tr();
}
