import 'package:easy_localization/easy_localization.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';

class ChatEmojiWidget extends StatelessWidget {
  final VoidCallback? closeSelected;
  final Function(String) onEmojiSelected;

  const ChatEmojiWidget({
    super.key,
    this.closeSelected,
    required this.onEmojiSelected,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return EmojiPicker(
      onEmojiSelected: (category, emoji) {
        if (closeSelected != null) {
          closeSelected!();
        }
        onEmojiSelected(emoji.emoji);
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
          indicatorColor: primaryColor,
          iconColorSelected: primaryColor,
          backspaceColor: primaryColor,
        ),
        bottomActionBarConfig: BottomActionBarConfig(
          enabled: true,
          customBottomActionBar: (config, state, showSearchView) {
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
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.black.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedSearch02,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'toolbar_search_emoji'.tr(),
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          },
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
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    focusNode: focusNode,
                    onChanged: onTextInputChanged,
                    decoration: InputDecoration(
                      hintText: 'emoji_search_hint'.tr(),
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
