import 'package:anoxia/features/announcement/presentation/widgets/announcement_dialog.dart';
import 'package:anoxia/framework/domain/announcement.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Announcement makeAnnouncement({
  AnnouncementLevel level = AnnouncementLevel.normal,
  String title = 'Title',
  String content = 'Content',
}) => Announcement(
  id: 1,
  revision: 1,
  title: title,
  content: content,
  level: level,
  publishAt: DateTime(2026, 9, 8),
  expireAt: null,
  read: false,
  acknowledged: false,
);

void main() {
  Future<void> pumpDialog(
    WidgetTester tester, {
    required Announcement announcement,
    required Future<bool> Function() onAcknowledge,
    VoidCallback? onClose,
    int? queueIndex,
    int? queueTotal,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              final route = AnnouncementDialog.buildRoute(
                context,
                (dialogContext) => AnnouncementDialog(
                  announcement: announcement,
                  onClose: onClose ?? () => Navigator.pop(dialogContext),
                  onAcknowledge: onAcknowledge,
                  queueIndex: queueIndex,
                  queueTotal: queueTotal,
                ),
                dismissible:
                    announcement.level != AnnouncementLevel.required,
              );
              Navigator.of(context).push(route);
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('REQUIRED 公告不能通过系统返回关闭', (tester) async {
    await pumpDialog(
      tester,
      announcement: makeAnnouncement(level: AnnouncementLevel.required),
      onAcknowledge: () async => false,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Title'), findsOneWidget);
  });

  testWidgets('普通公告展示「知道了」按钮，点击触发 onClose', (tester) async {
    var closed = 0;
    await pumpDialog(
      tester,
      announcement: makeAnnouncement(),
      onClose: () => closed++,
      onAcknowledge: () async => true,
    );

    expect(find.text('announcement_got_it'.tr()), findsOneWidget);
    expect(find.text('announcement-acknowledge'), findsNothing);

    await tester.tap(find.text('announcement_got_it'.tr()));
    await tester.pumpAndSettle();
    expect(closed, 1);
  });

  testWidgets('需确认公告展示徽章，确认失败后出现错误条并切换为重试', (
    tester,
  ) async {
    var acknowledged = 0;
    Future<bool> onAcknowledge() async {
      acknowledged++;
      return acknowledged > 1;
    }
    await pumpDialog(
      tester,
      announcement: makeAnnouncement(level: AnnouncementLevel.required),
      onAcknowledge: onAcknowledge,
    );

    expect(find.text('announcement_required_badge'.tr()), findsOneWidget);
    expect(find.text('announcement_acknowledge'.tr()), findsOneWidget);

    await tester.tap(find.byKey(const Key('announcement-acknowledge')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('announcement-ack-error')), findsOneWidget);
    expect(find.text('announcement_retry'.tr()), findsOneWidget);

    await tester.tap(find.byKey(const Key('announcement-acknowledge')));
    await tester.pumpAndSettle();
    expect(acknowledged, 2);
  });

  testWidgets('传入队列参数时展示 n/m 队列指示', (tester) async {
    await pumpDialog(
      tester,
      announcement: makeAnnouncement(),
      onClose: () {},
      onAcknowledge: () async => true,
      queueIndex: 0,
      queueTotal: 3,
    );

    expect(find.text('1/3'), findsOneWidget);
  });

  testWidgets('不传队列参数或仅一条时不展示队列指示', (tester) async {
    await pumpDialog(
      tester,
      announcement: makeAnnouncement(),
      onClose: () {},
      onAcknowledge: () async => true,
      queueTotal: 1,
    );

    expect(find.text('1/1'), findsNothing);
  });

  testWidgets('窄屏移动端需确认公告头部不横向溢出', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(320, 480)),
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                final route = AnnouncementDialog.buildRoute(
                  context,
                  (dialogContext) => AnnouncementDialog(
                    announcement: makeAnnouncement(
                      level: AnnouncementLevel.required,
                      title:
                          'This is a very long announcement title that keeps going and going and on',
                    ),
                    onClose: () => Navigator.pop(dialogContext),
                    onAcknowledge: () async => true,
                  ),
                  dismissible: false,
                );
                Navigator.of(context).push(route);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('announcement_required_badge'.tr()), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('矮窗桌面端卡片整体不超出窗口高度', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(800, 300)),
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                final route = AnnouncementDialog.buildRoute(
                  context,
                  (dialogContext) => AnnouncementDialog(
                    announcement: makeAnnouncement(
                      level: AnnouncementLevel.required,
                      content: List.generate(20, (i) => 'line $i')
                          .join('\n'),
                    ),
                    onClose: () => Navigator.pop(dialogContext),
                    onAcknowledge: () async => true,
                  ),
                  dismissible: false,
                );
                Navigator.of(context).push(route);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('announcement-acknowledge')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('队列圆点最多渲染 10 个，n/m 数字保持真实值', (tester) async {
    await pumpDialog(
      tester,
      announcement: makeAnnouncement(),
      onClose: () {},
      onAcknowledge: () async => true,
      queueIndex: 15,
      queueTotal: 20,
    );

    expect(find.text('16/20'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).shape == BoxShape.circle,
      ),
      findsNWidgets(10),
    );
  });

  testWidgets('移动端 buildRoute 返回底部面板路由', (tester) async {
    late Route<void> route;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: Builder(
            builder: (context) {
              route = AnnouncementDialog.buildRoute(
                context,
                (_) => const SizedBox.shrink(),
                dismissible: true,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    expect(route, isA<ModalBottomSheetRoute<void>>());
  });

  testWidgets('桌面端 buildRoute 返回居中弹窗路由', (tester) async {
    late Route<void> route;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            route = AnnouncementDialog.buildRoute(
              context,
              (_) => const SizedBox.shrink(),
              dismissible: true,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(route, isA<DialogRoute<void>>());
  });
}
