// 会话输入草稿存取。
//
// 目标：切走再回来，正在打的字还在（P0-1）。
// - `load`/`clear` 由 ChatInputController 在 build/发送成功路径调用；
// - `save` 内部 500ms debounce 合并写：连续打字只落一次盘；
//   内容与最近一次已落盘结果相同时直接跳过（选区移动等高频通知被吸收）；
// - `flush` 供切房间（controller onDispose）时立即落盘，不等待 debounce；
// - 空 delta 视为「已清空输入」，删除草稿行而不是保存空串；
// - 每个房间串行写链（前一次写完成后再写下一个），避免乱序覆盖新内容；
// - 查询路径不抛错（数据库失败降级 null），写失败只记日志不冒泡。
//
// 草稿行随 `clearSessionCache` 一起清除（登出/切账号不留个人内容）。
import 'dart:async';

import 'package:anoxia/framework/local_cache/cache_providers.dart';
import 'package:anoxia/framework/local_cache/database.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'input_draft_store_provider.g.dart';

/// 一份待写盘的草稿载荷（由调用方在控制器内一次性序列化好）。
class InputDraftPayload {
  const InputDraftPayload({required this.deltaJson, required this.plainText});

  /// Quill Delta JSON（完整文档）
  final String deltaJson;

  /// 纯文本快照
  final String plainText;

  /// Quill 空文档（只有初始换行）的 delta JSON：
  /// 空输入不该留草稿行，落盘时转为删除。
  bool get isEmptyDelta {
    if (deltaJson.isEmpty) return true;
    if (plainText.isNotEmpty) return false;
    return deltaJson == '[]' ||
        deltaJson == InputDraftPayload._emptyDocumentDeltaJson;
  }

  /// Quill 新建文档的 `document.toDelta().toJson()` 序列化结果
  /// （jsonEncode 产生的字符串中换行是 `\n` 两字符转义）。
  static const String _emptyDocumentDeltaJson = '[{"insert":"\\n"}]';
}

/// 会话输入草稿存取服务（每会话最多一行草稿）。
@Riverpod(keepAlive: true)
class InputDraftStore extends _$InputDraftStore {
  /// debounce 合并窗口：连续快速输入只落一次盘。
  static const Duration saveDebounce = Duration(milliseconds: 500);

  final Map<String, Timer> _timers = {};
  final Map<String, InputDraftPayload> _pending = {};

  /// 每个房间最近一次已写入的 deltaJson，用于吸收重复保存请求。
  final Map<String, String> _lastWrittenDelta = {};

  /// 每个房间的写链，保证同一会话草稿按提交顺序落盘。
  final Map<String, Future<void>> _writeChains = {};

  @override
  void build() {
    ref.onDispose(_disposeAll);
  }

  /// 读取会话草稿；无草稿或读取失败返回 null。
  Future<InputDraft?> load(String roomId) async {
    try {
      return await ref.read(localDataSourceProvider).loadInputDraft(roomId);
    } catch (e, st) {
      debugLog('input draft load failed: $e', e, st);
      return null;
    }
  }

  /// 排队保存一份草稿（debounce 合并；与上次已写内容相同则跳过）。
  void save({
    required String roomId,
    required String deltaJson,
    required String plainText,
  }) {
    final payload = InputDraftPayload(
      deltaJson: deltaJson,
      plainText: plainText,
    );
    if (_lastWrittenDelta[roomId] == payload.deltaJson) return;
    _pending[roomId] = payload;
    _startTimer(roomId);
  }

  /// 立即落盘一批未保存的草稿（切房间、controller 销毁时调用）。
  ///
  /// 返回该会话写链的未来：完成即代表调用前挂起的写已结束（测试用）。
  Future<void> flush(String roomId) {
    _cancelTimer(roomId);
    final payload = _pending.remove(roomId);
    if (payload != null) {
      _enqueueWrite(roomId, payload);
    }
    return _writeChains[roomId] ?? Future<void>.value();
  }

  /// 清除草稿（取消排队写入后删除行）。
  ///
  /// 返回写链的未来；调用方（controller）无需等待，测试可用它同步收口。
  Future<void> clear(String roomId) {
    _cancelTimer(roomId);
    _pending.remove(roomId);
    _lastWrittenDelta.remove(roomId);
    _enqueueWrite(
      roomId,
      const InputDraftPayload(deltaJson: '', plainText: ''),
    );
    return _writeChains[roomId] ?? Future<void>.value();
  }

  void _startTimer(String roomId) {
    _cancelTimer(roomId);
    _timers[roomId] = Timer(saveDebounce, () {
      unawaited(flush(roomId));
    });
  }

  void _cancelTimer(String roomId) {
    _timers.remove(roomId)?.cancel();
  }

  void _enqueueWrite(String roomId, InputDraftPayload payload) {
    final previous = _writeChains[roomId] ?? Future<void>.value();
    _writeChains[roomId] = previous.then((_) => _doWrite(roomId, payload));
  }

  Future<void> _doWrite(String roomId, InputDraftPayload payload) async {
    try {
      final dataSource = ref.read(localDataSourceProvider);
      if (payload.isEmptyDelta) {
        await dataSource.clearInputDraft(roomId);
        _lastWrittenDelta.remove(roomId);
      } else if (_lastWrittenDelta[roomId] != payload.deltaJson) {
        await dataSource.saveInputDraft(
          roomId: roomId,
          deltaJson: payload.deltaJson,
          plainText: payload.plainText,
        );
        _lastWrittenDelta[roomId] = payload.deltaJson;
      }
    } catch (e, st) {
      // 写链可能在 store/容器销毁后才执行（切房间 flush），吞掉这类失败即可。
      debugLog('input draft save failed: $e', e, st);
    }
  }

  void _disposeAll() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _pending.clear();
    _writeChains.clear();
  }
}
