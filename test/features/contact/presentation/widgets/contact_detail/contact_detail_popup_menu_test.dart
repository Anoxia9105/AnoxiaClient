import 'package:anoxia/common/widgets/bubble_dialog.dart';
import 'package:anoxia/features/contact/presentation/widgets/contact_detail/contact_detail_popup_menu.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('popup menu stays inside its bubble and above the dialog', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: BotToastInit(),
        navigatorObservers: [BotToastNavigatorObserver()],
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => Dialog(
                      clipBehavior: Clip.antiAlias,
                      insetPadding: const EdgeInsets.all(24),
                      child: SizedBox(
                        width: 600,
                        height: 600,
                        child: Scaffold(
                          appBar: AppBar(
                            title: const Text('ContactDetail'),
                            actions: [
                              ContactDetailPopupMenuButton(
                                onEditRemark: () {},
                                onDelete: () {},
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('open dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open dialog'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final editRect = tester.getRect(
      find.text('contact_edit_remark'.tr()),
    );
    final deleteRect = tester.getRect(
      find.text('contact_delete'.tr()),
    );
    final bubbleRect = tester.getRect(find.byType(BubbleWidget));

    expect(bubbleRect.width, lessThanOrEqualTo(120.5));
    expect(editRect.width, lessThanOrEqualTo(bubbleRect.width));
    expect(deleteRect.width, lessThanOrEqualTo(bubbleRect.width));
    expect(editRect.left, greaterThanOrEqualTo(bubbleRect.left - 1));
    expect(editRect.right, lessThanOrEqualTo(bubbleRect.right + 1));
    expect(deleteRect.left, greaterThanOrEqualTo(bubbleRect.left - 1));
    expect(deleteRect.right, lessThanOrEqualTo(bubbleRect.right + 1));

    final editCenter = tester.getCenter(
      find.text('contact_edit_remark'.tr()),
    );
    final hit = tester.hitTestOnBinding(editCenter);
    expect(
      hit.path.any((entry) => entry.target is RenderParagraph),
      isTrue,
      reason: 'the bubble must be hit-testable on top of the dialog',
    );

    await tester.pumpWidget(const SizedBox());
  });
}
