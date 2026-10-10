import 'package:anoxia/features/chat/presentation/widgets/chatinput/mobile/chat_content_picker.dart';
import 'package:anoxia/framework/domain/chat_favorite.dart';
import 'package:anoxia/framework/provider/chat/favorite/chat_favorite_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('收藏可搜索，取消确认不发送，确认后返回完整收藏', (tester) async {
    final favorite = ChatFavorite.fromJson({
      'id': 1,
      'msgId': 'm1',
      'content': 'hello world',
      'favoriteType': 'TEXT',
    });
    Object? result;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatFavoriteListProvider.overrideWith((ref) async => [favorite]),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await Navigator.push<Object>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChatContentPicker(favorites: true),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('hello world'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'missing');
    await tester.pump();
    expect(find.text('hello world'), findsNothing);
    await tester.enterText(find.byType(TextField), 'HELLO');
    await tester.pump();
    await tester.tap(find.text('hello world'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('cancel'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    await tester.tap(find.text('hello world'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('chat_share_send'));
    await tester.pumpAndSettle();
    expect(result, same(favorite));
  });
}
