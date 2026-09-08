import 'package:anoxia/features/announcement/presentation/widgets/announcement_dialog.dart';
import 'package:anoxia/framework/domain/announcement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('REQUIRED 公告不能通过系统返回关闭', (tester) async {
    final announcement = Announcement(
      id: 1,
      revision: 1,
      title: 'Required',
      content: 'Content',
      level: AnnouncementLevel.required,
      publishAt: DateTime(2026),
      expireAt: null,
      read: false,
      acknowledged: false,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) => AnnouncementDialog(
                announcement: announcement,
                onClose: () => Navigator.pop(dialogContext),
                onAcknowledge: () async => false,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Required'), findsOneWidget);
  });
}
