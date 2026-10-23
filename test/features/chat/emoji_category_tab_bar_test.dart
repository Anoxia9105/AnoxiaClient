import 'package:anoxia/features/chat/presentation/widgets/chatinput/chat_emoji_widgets.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final showStickers in [false, true]) {
    testWidgets('自定义分类栏在贴图入口为 $showStickers 时保持分类按钮', (tester) async {
      final pages = PageController();
      addTearDown(pages.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: DefaultTabController(
            length: 2,
            child: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 288,
                    child: EmojiCategoryTabBar(
                      tabController: DefaultTabController.of(context),
                      pageController: pages,
                      categories: const [
                        CategoryEmoji(Category.RECENT, []),
                        CategoryEmoji(Category.SMILEYS, []),
                      ],
                      onStickerTap: showStickers ? () {} : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('emoji_category_0')), findsOneWidget);
      expect(find.byKey(const ValueKey('emoji_category_1')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('emoji_category_sticker')),
        showStickers ? findsOneWidget : findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
