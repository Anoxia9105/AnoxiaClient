import 'package:anoxia/common/widgets/cached_network_image_view.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/domain/sticker_pack.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:anoxia/framework/provider/chat/sticker/sticker_packs_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'chat_emoji_widgets.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

export 'chat_emoji_widgets.dart'
    show MyCustomSearchView, MyCustomSearchViewState;

/// 聊天表情选择器组件
///
/// 提供 Emoji 选择功能，支持搜索、皮肤色调选择与自定义表情包（贴图）。
/// 分类栏末尾为表情包入口，点击后切换为表情包视图（微信式）。
/// [showSearch] 为 false 时不显示底部搜索框（手机端）。
class ChatEmojiWidget extends ConsumerStatefulWidget {
  final VoidCallback? closeSelected;
  final Function(String) onEmojiSelected;

  /// 表情包内贴图点按回调（用于发送）
  final ValueChanged<Sticker> onStickerSelected;

  /// 是否显示底部搜索框，手机端传 false 隐藏
  final bool showSearch;

  /// 选中后是否回调 [closeSelected] 关闭面板
  ///
  /// 桌面端弹层默认 true（选中即收起弹层）；
  /// 手机端传 false 保持面板打开，可连续选择（微信式），键盘保持隐藏。
  final bool closeOnSelect;

  const ChatEmojiWidget({
    super.key,
    this.closeSelected,
    required this.onEmojiSelected,
    required this.onStickerSelected,
    this.showSearch = true,
    this.closeOnSelect = true,
  });

  @override
  ConsumerState<ChatEmojiWidget> createState() => _ChatEmojiWidgetState();
}

class _ChatEmojiWidgetState extends ConsumerState<ChatEmojiWidget> {
  bool _showStickers = false;
  int _selectedPackIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (_showStickers) {
      return _buildStickerView();
    }
    return EmojiPicker(
      onEmojiSelected: (category, emoji) {
        if (widget.closeOnSelect && widget.closeSelected != null) {
          widget.closeSelected!();
        }
        widget.onEmojiSelected(emoji.emoji);
      },
      config: Config(
        locale: context.locale,
        height: 500.h,
        checkPlatformCompatibility: true,
        emojiViewConfig: const EmojiViewConfig(
          columns: 8,
          emojiSizeMax: 24,
          backgroundColor: Colors.transparent,
          gridPadding: EdgeInsets.all(4),
        ),
        viewOrderConfig: const ViewOrderConfig(
          top: EmojiPickerItem.categoryBar,
          middle: EmojiPickerItem.searchBar,
          bottom: EmojiPickerItem.emojiView,
        ),
        skinToneConfig: SkinToneConfig(
          dialogBackgroundColor:
              Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : Colors.black87,
        ),
        categoryViewConfig: CategoryViewConfig(
          backgroundColor: Colors.transparent,
          customCategoryView: (config, state, tabController, pageController) {
            return EmojiCategoryTabBar(
              tabController: tabController,
              pageController: pageController,
              categories: state.categoryEmoji,
              onStickerTap: () {
                ref.invalidate(stickerPacksProvider);
                setState(() {
                  _showStickers = true;
                });
              },
            );
          },
        ),
        bottomActionBarConfig: BottomActionBarConfig(
          enabled: widget.showSearch,
          customBottomActionBar: widget.showSearch
              ? (config, state, showSearchView) {
                  return GestureDetector(
                    onTap: () => showSearchView(),
                    child: Container(
                      height: 30,
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        vertical: 5,
                        horizontal: 10,
                      ),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.white.withValues(alpha: 0.4)
                            : Colors.black.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(RadiusToken.md),
                        border: Border.all(
                          color:
                              Theme.of(context).brightness == Brightness.light
                              ? Colors.black.withValues(alpha: 0.1)
                              : Colors.white.withValues(alpha: 0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedSearch02,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'toolbar_search_emoji'.tr(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              : null,
        ),
        searchViewConfig: SearchViewConfig(
          customSearchView: (config, state, showEmojiView) {
            return SizedBox(
              height: 300.h,
              child: MyCustomSearchView(config, state, showEmojiView),
            );
          },
        ),
      ),
    );
  }

  // ==================== 表情包视图 ====================

  Widget _buildStickerView() {
    final packsAsync = ref.watch(stickerPacksProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _showStickers = false;
                });
              },
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowLeft01,
                size: 20,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: packsAsync.maybeWhen(
                data: (packs) => _buildPackSelector(packs),
                orElse: () => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
        Expanded(
          child: packsAsync.when(
            loading: () => const StickerGridSkeleton(),
            // error: (error, stackTrace) => _buildLoadError(),
            error: (error, stackTrace) {
              debugLog('加载表情包失败: $error', error, stackTrace);
              return _buildLoadError();
            },
            data: (packs) => _buildStickerGrid(packs),
          ),
        ),
      ],
    );
  }

  /// 表情包选择条（横向滚动，选中项高亮）
  Widget _buildPackSelector(List<StickerPack> packs) {
    if (packs.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (index, pack) in packs.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(
                borderRadius: BorderRadius.circular(RadiusToken.xl),
                onTap: () {
                  setState(() {
                    _selectedPackIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: index == _selectedPackIndex
                        ? scheme.primary.withValues(alpha: 0.14)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(RadiusToken.xl),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(RadiusToken.sm),
                        child: CachedNetworkImageView(
                          imageUrl: pack.iconUrl,
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                          memCacheWidth: 48,
                          memCacheHeight: 48,
                          placeholder: (context, url) => Container(
                            width: 24,
                            height: 24,
                            color: scheme.surfaceContainerHigh,
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            color: scheme.surfaceContainerHigh,
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedSticker,
                              size: 14,
                              color: scheme.outline,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 72),
                        child: Text(
                          pack.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: index == _selectedPackIndex
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                            fontWeight: index == _selectedPackIndex
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 贴图网格
  Widget _buildStickerGrid(List<StickerPack> packs) {
    if (packs.isEmpty) {
      return Center(
        child: Text(
          'emoji_sticker_empty'.tr(),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    final index = _selectedPackIndex >= packs.length
        ? packs.length - 1
        : _selectedPackIndex;
    final pack = packs[index];
    final stickers = pack.stickers;
    if (stickers.isEmpty) {
      return Center(
        child: Text(
          'emoji_sticker_empty'.tr(),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    final dpr = MediaQuery.of(context).devicePixelRatio;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 80,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: stickers.length,
      itemBuilder: (context, i) {
        final sticker = stickers[i];
        final size = _resolveStickerSize(sticker);
        return InkWell(
          borderRadius: BorderRadius.circular(RadiusToken.lg),
          onTap: () {
            if (widget.closeOnSelect && widget.closeSelected != null) {
              widget.closeSelected!();
            }
            widget.onStickerSelected(sticker);
          },
          child: Center(
            child: CachedNetworkImageView(
              imageUrl: sticker.imageUrl,
              width: size.width,
              height: size.height,
              fit: BoxFit.contain,
              memCacheWidth: (size.width * dpr).round(),
              memCacheHeight: (size.height * dpr).round(),
              preferWebHtmlElement: sticker.isGif,
              placeholder: (context, url) => Container(
                width: size.width,
                height: size.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(RadiusToken.md),
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: size.width,
                height: size.height,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(RadiusToken.md),
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedSticker,
                  size: 20,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              filterQuality: FilterQuality.medium,
            ),
          ),
        );
      },
    );
  }

  /// 加载失败视图（提供重试）
  Widget _buildLoadError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'emoji_sticker_load_failed'.tr(),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              ref.invalidate(stickerPacksProvider);
            },
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedRefresh01,
              size: 16,
            ),
            label: Text('emoji_sticker_retry'.tr()),
          ),
        ],
      ),
    );
  }

  /// 面板内贴图尺寸：默认 56×56，按宽高等比缩放，最大边 64px，最小边 36px
  Size _resolveStickerSize(Sticker sticker) {
    const maxSide = 64.0;
    const minSide = 36.0;
    const defaultSide = 56.0;

    final rawWidth = sticker.width;
    final rawHeight = sticker.height;
    if (rawWidth == null ||
        rawHeight == null ||
        rawWidth <= 0 ||
        rawHeight <= 0) {
      return const Size(defaultSide, defaultSide);
    }

    final aspect = rawWidth / rawHeight;
    if (aspect >= 1) {
      return Size(maxSide, (maxSide / aspect).clamp(minSide, maxSide));
    }
    return Size((maxSide * aspect).clamp(minSide, maxSide), maxSide);
  }
}
