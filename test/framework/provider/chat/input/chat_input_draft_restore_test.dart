// P0-1 控制器层草稿恢复/落盘测试。
//
// 覆盖（对应计划验收）：
// - 有草稿 → ChatInputController.build 异步恢复内容与光标；
// - 用户抢先打字 → 放弃恢复（防竞态）；
// - 发送后（clearInput）草稿行被清除；
// - 切房间（controller onDispose）等待中的草稿立即落盘（flush）。
//
// 说明：不做整页 widget 测试；三类副作用全部落本地库，直接用内存 drift 断言。
// typing 等链路在测试里只会走 currentRoomProvider（覆写为 null 即短路）。
import 'dart:async';
import 'dart:convert';

import 'package:anoxia/framework/local_cache/cache_providers.dart';
import 'package:anoxia/framework/local_cache/database.dart';
import 'package:anoxia/framework/local_cache/local_data_source.dart';
import 'package:anoxia/framework/local_cache/session_epoch.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_controller.dart';
import 'package:anoxia/framework/provider/chat/input/input_draft_store_provider.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:drift/native.dart';
import 'package:flutter/painting.dart' show TextSelection;
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 可控延迟的数据源：恢复链路等待 [gate] 完成后才读库，用于构造竞态。
class GatedDataSource extends LocalDataSource {
  GatedDataSource(super.db, {super.sessionEpoch});

  Completer<void>? gate;

  @override
  Future<InputDraft?> loadInputDraft(String roomId) async {
    if (gate != null) {
      await gate!.future;
    }
    return super.loadInputDraft(roomId);
  }
}

/// 生成一段纯文本 Quill delta JSON（内容后带换行，与 query 导出口径一致）。
final String emptyDeltaJson = jsonEncode((Delta()..insert('\n')).toJson());

String deltaJsonOf(String text) =>
    jsonEncode((Delta()..insert('$text\n')).toJson());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('有草稿时 build 自动恢复内容与光标（无竞态）', () async {
    final dataSource = LocalDataSource(
      AppDatabase(NativeDatabase.memory()),
      sessionEpoch: SessionEpoch.instance,
    );
    addTearDown(dataSource.db.close);
    await dataSource.saveInputDraft(
      roomId: 'r1',
      deltaJson: deltaJsonOf('草稿文本'),
      plainText: '草稿文本',
    );

    final container = ProviderContainer(
      overrides: [localDataSourceProvider.overrideWith((ref) => dataSource)],
    );
    addTearDown(container.dispose);

    // eslint 保留 emptyDeltaJson 以防后续用例：此处顺带断言 jsonEncode 与 store 判空口径一致
    expect(
      InputDraftPayload(deltaJson: emptyDeltaJson, plainText: '').isEmptyDelta,
      isTrue,
      reason: '恢复测试依赖保存口径，等于 Quill 新建文档序列化结果',
    );

    final controller = container.read(chatInputControllerProvider('r1'));
    await pumpEventQueue();

    expect(controller.document.toPlainText(), '草稿文本\n');
    // 光标定位到恢复文本末尾（正文末尾即文档 length - 1）
    expect(controller.selection.baseOffset, controller.document.length - 1);
  });

  test('用户抢先打字时放弃恢复草稿', () async {
    final dataSource = GatedDataSource(
      AppDatabase(NativeDatabase.memory()),
      sessionEpoch: SessionEpoch.instance,
    );
    addTearDown(dataSource.db.close);
    await dataSource.saveInputDraft(
      roomId: 'r1',
      deltaJson: deltaJsonOf('草稿文本'),
      plainText: '草稿文本',
    );
    dataSource.gate = Completer<void>();

    final container = ProviderContainer(
      overrides: [
        localDataSourceProvider.overrideWith((ref) => dataSource),
        // typing 链路只读 currentRoomProvider；给空房间即可短路
        currentRoomProvider('r1').overrideWith((ref) => null),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(chatInputControllerProvider('r1'));
    // 模拟用户在草稿读取完成前已经开始输入（在光标处插入，保留结尾换行）
    controller.replaceText(
      0,
      0,
      '用户字',
      const TextSelection.collapsed(offset: 3),
    );

    dataSource.gate!.complete();
    await pumpEventQueue();

    expect(controller.document.toPlainText(), contains('用户字'));
    expect(controller.document.toPlainText(), isNot(contains('草稿文本')));

    // 抢先输入排入 store；模拟切房间（provider 失效 → onDispose flush 落盘）
    container.invalidate(chatInputControllerProvider('r1'));
    await pumpEventQueue();
    final row = await dataSource.loadInputDraft('r1');
    expect(row!.plainText, '用户字\n');
  });

  test('clearInput（发送成功路径）清除草稿行', () async {
    final dataSource = LocalDataSource(
      AppDatabase(NativeDatabase.memory()),
      sessionEpoch: SessionEpoch.instance,
    );
    addTearDown(dataSource.db.close);
    await dataSource.saveInputDraft(
      roomId: 'r1',
      deltaJson: deltaJsonOf('草稿文本'),
      plainText: '草稿文本',
    );

    final container = ProviderContainer(
      overrides: [localDataSourceProvider.overrideWith((ref) => dataSource)],
    );
    addTearDown(container.dispose);

    final controller = container.read(chatInputControllerProvider('r1'));
    await pumpEventQueue();
    expect(controller.document.toPlainText(), '草稿文本\n');

    container.read(chatInputControllerProvider('r1').notifier).clearInput();
    await pumpEventQueue();

    expect(controller.document.toPlainText().length, 1); // 剩初始换行
    expect(await dataSource.loadInputDraft('r1'), isNull);
  });

  test('切房间（controller 失效）时等待中的草稿立即落盘', () async {
    final dataSource = LocalDataSource(
      AppDatabase(NativeDatabase.memory()),
      sessionEpoch: SessionEpoch.instance,
    );
    addTearDown(dataSource.db.close);

    final container = ProviderContainer(
      overrides: [localDataSourceProvider.overrideWith((ref) => dataSource)],
    );
    addTearDown(container.dispose);

    final controller = container.read(chatInputControllerProvider('r1'));
    controller.replaceText(
      0,
      0,
      '正在打的话',
      const TextSelection.collapsed(offset: 5),
    );

    // 模拟切房间：r1 provider 失效 → onDispose flush 立即写盘（不等 500ms）
    container.invalidate(chatInputControllerProvider('r1'));
    await pumpEventQueue();

    final row = await dataSource.loadInputDraft('r1');
    expect(row!.plainText, '正在打的话\n');
  });
}
