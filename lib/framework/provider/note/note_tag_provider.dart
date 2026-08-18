import 'package:anoxia/framework/domain/note_doc.dart';
import 'package:anoxia/framework/provider/core/note_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'note_tag_provider.g.dart';

/// 记事本标签服务
///
/// 提供标签列表（含关联笔记数），供树面板的标签过滤栏使用。
/// 标签编辑（增删）成功后调用 [refresh] 拉取最新列表。
@Riverpod(keepAlive: true)
class NoteTagService extends _$NoteTagService {
  /// 进行中的请求，防止并发重复拉取
  Future<List<NoteTag>>? _inflight;

  @override
  Future<List<NoteTag>> build() {
    return _fetch();
  }

  Future<List<NoteTag>> _fetch() {
    return _inflight ??=
        ref.read(noteRepositoryProvider).getTags().whenComplete(() => _inflight = null);
  }

  /// 手动刷新标签列表
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(_fetch);
    if (!ref.mounted) return;
    state = result;
  }
}