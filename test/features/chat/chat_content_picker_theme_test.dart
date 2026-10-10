import 'package:anoxia/features/chat/presentation/widgets/chatinput/mobile/chat_content_picker.dart';
import 'package:anoxia/framework/domain/chat_contact_vo.dart';
import 'package:anoxia/framework/provider/chat/favorite/chat_favorite_service.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Contacts extends ContactListService {
  @override
  Future<Map<int, ChatContactVO>> build() async => {};
}

void main() {
  for (final brightness in Brightness.values) {
    for (final favorites in [true, false]) {
      testWidgets('更多面板选择页绘制主题背景 $favorites $brightness', (tester) async {
        final theme = ThemeData(
          brightness: brightness,
        ).copyWith(scaffoldBackgroundColor: Colors.transparent);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              chatFavoriteListProvider.overrideWith((ref) async => []),
              contactListServiceProvider.overrideWith(_Contacts.new),
            ],
            child: MaterialApp(
              theme: theme,
              home: ChatContentPicker(favorites: favorites),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, theme.colorScheme.surface);
        expect(scaffold.backgroundColor!.a, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
