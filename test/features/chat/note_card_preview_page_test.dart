import 'dart:async';

import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/framework/domain/note_doc.dart';
import 'package:anoxia/framework/domain/note_tree.dart';
import 'package:anoxia/framework/domain/user_info.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/layout/layout_controller.dart';
import 'package:anoxia/framework/provider/note/note_open_provider.dart';
import 'package:anoxia/framework/provider/note/note_tag_provider.dart';
import 'package:anoxia/framework/provider/note/note_tree_provider.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:anoxia/features/chat/presentation/pages/note_card_preview_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthController extends AuthController {
  final UserInfo? _user;

  _FakeAuthController(this._user);

  @override
  Future<UserInfo?> build() async => _user;
}

class _FakeTagService extends NoteTagService {
  @override
  Future<List<NoteTag>> build() => Future.value(const []);
}

class _FakeTreeService extends NoteTreeService {
  @override
  FutureOr<NoteTree> build() => const NoteTree(folders: [], rootNotes: []);

  @override
  Future<NoteDoc> openNote(int noteId) async => NoteDoc(
    id: noteId,
    folderId: null,
    title: '购物清单',
    content: '[]',
    plainText: '',
    createdAt: null,
    updatedAt: null,
  );
}

final _user = UserInfo(
  userId: 42,
  userName: 'test_user',
  nickName: '测试用户',
  email: '',
  phoneNumber: '',
  sex: '2',
  avatar: '',
);

/// 模拟服务端 REST 历史接口的卡片数据（properties 为 List[{key,value}]）
CardPayload _serverNoteCard({bool escapedNewlines = false}) {
  final content = escapedNewlines ? r'第一行\n第二行\n第三行' : '第一行\n第二行\n第三行';
  return CardPayload.fromJson({
    'cardType': 'note',
    'entityId': '7',
    'title': '购物清单',
    'summary': '第一行 第二行 第三行',
    'properties': [
      {'key': 'content', 'value': content},
      {'key': 'ownerId', 'value': '42'},
      {'key': 'updatedAt', 'value': '1750000000000'},
    ],
  });
}

Widget _app(ProviderContainer container, Widget home) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      scaffoldMessengerKey: Toast.messengerKey,
      home: home,
    ),
  );
}

void main() {
  testWidgets('服务端 List 格式 properties 的记事本内容按多行渲染', (tester) async {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuthController(_user)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _app(container, NoteCardPreviewPage(card: _serverNoteCard())),
    );
    await tester.pumpAndSettle();

    // 内容完整多行渲染（而非回退到单行摘要）
    expect(find.text('购物清单'), findsOneWidget);
    expect(find.textContaining('第一行'), findsOneWidget);
    expect(find.textContaining('第二行'), findsOneWidget);
    expect(find.textContaining('第三行'), findsOneWidget);
    // 单行摘要不应出现在内容区
    expect(find.text('第一行 第二行 第三行'), findsNothing);
  });

  testWidgets('字面 \\n 双编码内容被还原为多行', (tester) async {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuthController(_user)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _app(
        container,
        NoteCardPreviewPage(card: _serverNoteCard(escapedNewlines: true)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('第一行'), findsOneWidget);
    expect(find.textContaining('第二行'), findsOneWidget);
    expect(find.textContaining('第三行'), findsOneWidget);
  });

  testWidgets('复制内容按钮使用封装的 Toast 提示', (tester) async {
    // 模拟剪贴板平台通道，让 onPressed 的异步处理正常完成
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuthController(_user)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _app(container, NoteCardPreviewPage(card: _serverNoteCard())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('note_card_copy'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('note_card_copy_done'), findsOneWidget);
  });

  testWidgets('桌面端「打开笔记」切换侧边栏到记事本并关闭预览页', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuthController(_user)),
      ],
    );
    addTearDown(container.dispose);
    // layoutControllerProvider 为 autoDispose：保持监听，防止被回收后重建为初始状态
    final layoutSub = container.listen(
      layoutControllerProvider,
      (_, _) {},
    );
    addTearDown(layoutSub.close);

    await tester.pumpWidget(
      _app(
        container,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        NoteCardPreviewPage(card: _serverNoteCard()),
                  ),
                ),
                child: const Text('open-preview'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open-preview'));
    await tester.pumpAndSettle();
    expect(find.text('note_card_open'), findsOneWidget);

    await tester.tap(find.text('note_card_open'));
    await tester.pumpAndSettle();

    // 侧边栏切到记事本（index 3），打开请求已写入，预览页已关闭
    expect(container.read(layoutControllerProvider).currentIndex, 3);
    expect(container.read(noteOpenRequestProvider), 7);
    expect(find.text('note_card_open'), findsNothing);
  });

  testWidgets('移动端「打开笔记」压栈编辑器页（可返回）', (tester) async {
    // 599 仍属于移动端宽度断点（<=600），且给测试字体留足空间避免溢出
    tester.view.physicalSize = const Size(599, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuthController(_user)),
        noteTreeServiceProvider.overrideWith(() => _FakeTreeService()),
        noteTagServiceProvider.overrideWith(() => _FakeTagService()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _app(
        container,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        NoteCardPreviewPage(card: _serverNoteCard()),
                  ),
                ),
                child: const Text('open-preview'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open-preview'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('note_card_open'));
    // 移动端压栈的记事本页含加载动画，避免 pumpAndSettle 超时，用有界 pump
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // 移动端：侧边栏不切换、无打开请求，预览页仍在栈中（被压栈页面盖住，需跳过 offstage）
    expect(container.read(layoutControllerProvider).currentIndex, 0);
    expect(container.read(noteOpenRequestProvider), isNull);
    expect(find.byType(NoteCardPreviewPage, skipOffstage: false), findsOneWidget);
  });
}
