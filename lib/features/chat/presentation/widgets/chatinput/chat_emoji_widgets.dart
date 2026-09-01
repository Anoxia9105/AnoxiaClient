import 'package:anoxia/common/widgets/skeleton_box.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 表情分类 Tab 栏（HugeIcons 定制）
///
/// 选中项以主题色胶囊高亮，未选中为弱化灰；末尾为表情包入口。
class EmojiCategoryTabBar extends StatefulWidget {
  const EmojiCategoryTabBar({
    super.key,
    required this.tabController,
    required this.pageController,
    required this.categories,
    required this.onStickerTap,
  });

  final TabController tabController;
  final PageController pageController;
  final List<CategoryEmoji> categories;
  final VoidCallback onStickerTap;

  @override
  State<EmojiCategoryTabBar> createState() => _EmojiCategoryTabBarState();
}

class _EmojiCategoryTabBarState extends State<EmojiCategoryTabBar> {
  /// 各分类对应的 HugeIcons 图标
  static const Map<Category, List<List<dynamic>>> _categoryIcons = {
    Category.RECENT: HugeIcons.strokeRoundedClock01,
    Category.SMILEYS: HugeIcons.strokeRoundedHappy,
    Category.ANIMALS: HugeIcons.strokeRoundedOctopus,
    Category.FOODS: HugeIcons.strokeRoundedIceCream01,
    Category.TRAVEL: HugeIcons.strokeRoundedAirplane01,
    Category.ACTIVITIES: HugeIcons.strokeRoundedFootball,
    Category.OBJECTS: HugeIcons.strokeRoundedBulb,
    Category.SYMBOLS: HugeIcons.strokeRoundedAt,
    Category.FLAGS: HugeIcons.strokeRoundedFlag01,
  };

  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.tabController.index;
    widget.tabController.addListener(_onTabChanged);
  }

  @override
  void didUpdateWidget(covariant EmojiCategoryTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabController != widget.tabController) {
      oldWidget.tabController.removeListener(_onTabChanged);
      _selectedIndex = widget.tabController.index;
      widget.tabController.addListener(_onTabChanged);
    }
  }

  void _onTabChanged() {
    if (!mounted) return;
    setState(() {
      _selectedIndex = widget.tabController.index;
    });
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final iconSize = narrow ? 18.0 : 20.0;
    return Container(
      height: 44,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final (index, categoryEmoji) in widget.categories.indexed)
              _buildTab(context, index, categoryEmoji.category, iconSize),
            _buildStickerButton(context, iconSize),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    int index,
    Category category,
    double iconSize,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final selected = index == _selectedIndex;
    final icon = _categoryIcons[category] ?? HugeIcons.strokeRoundedHappy;
    return InkWell(
      key: ValueKey('emoji_category_$index'),
      borderRadius: BorderRadius.circular(RadiusToken.lg),
      onTap: () {
        widget.pageController.jumpToPage(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: iconSize == 18 ? 7 : 9,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(RadiusToken.lg),
        ),
        child: HugeIcon(
          icon: icon,
          size: iconSize,
          color: selected
              ? scheme.primary
              : scheme.onSurfaceVariant.withValues(alpha: 0.55),
        ),
      ),
    );
  }

  /// 表情包入口按钮（分类栏末尾）
  Widget _buildStickerButton(BuildContext context, double iconSize) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      key: const ValueKey('emoji_category_sticker'),
      borderRadius: BorderRadius.circular(RadiusToken.lg),
      onTap: widget.onStickerTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: iconSize == 18 ? 7 : 9,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(RadiusToken.lg),
        ),
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedSticker,
          size: iconSize,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

class MyCustomSearchView extends SearchView {
  const MyCustomSearchView(
    super.config,
    super.state,
    super.showEmojiView, {
    super.key,
  });

  @override
  MyCustomSearchViewState createState() => MyCustomSearchViewState();
}

class MyCustomSearchViewState extends SearchViewState<MyCustomSearchView> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final emojiSize = widget.config.emojiViewConfig.getEmojiSize(
          constraints.maxWidth,
        );
        final emojiBoxSize = widget.config.emojiViewConfig.getEmojiBoxSize(
          constraints.maxWidth,
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: widget.showEmojiView,
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowLeft01,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    focusNode: focusNode,
                    onChanged: onTextInputChanged,
                    style: const TextStyle(fontSize: 14.0),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'emoji_search_hint'.tr(),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 4.0,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: emojiBoxSize,
              child: results.isEmpty
                  ? Center(
                      child: Text(
                        'emoji_not_found'.tr(),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        return buildEmoji(
                          results[index],
                          emojiSize,
                          emojiBoxSize,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// 表情包贴图网格骨架屏
class StickerGridSkeleton extends StatelessWidget {
  const StickerGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 80,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: 28,
      itemBuilder: (_, i) => const SkeletonBox(width: 64, height: 64, radius: 10),
    );
  }
}
