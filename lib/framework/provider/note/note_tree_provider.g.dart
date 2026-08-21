// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_tree_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 记事本完整树服务
///
/// 管理文件夹 / 笔记树，提供树查询与各类增删改、移动操作的封装，
/// 操作成功后自动刷新树。

@ProviderFor(NoteTreeService)
final noteTreeServiceProvider = NoteTreeServiceProvider._();

/// 记事本完整树服务
///
/// 管理文件夹 / 笔记树，提供树查询与各类增删改、移动操作的封装，
/// 操作成功后自动刷新树。
final class NoteTreeServiceProvider
    extends $AsyncNotifierProvider<NoteTreeService, NoteTree> {
  /// 记事本完整树服务
  ///
  /// 管理文件夹 / 笔记树，提供树查询与各类增删改、移动操作的封装，
  /// 操作成功后自动刷新树。
  NoteTreeServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noteTreeServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noteTreeServiceHash();

  @$internal
  @override
  NoteTreeService create() => NoteTreeService();
}

String _$noteTreeServiceHash() => r'418d276031e4c2a55b6eff466815ca7dd3745ae9';

/// 记事本完整树服务
///
/// 管理文件夹 / 笔记树，提供树查询与各类增删改、移动操作的封装，
/// 操作成功后自动刷新树。

abstract class _$NoteTreeService extends $AsyncNotifier<NoteTree> {
  FutureOr<NoteTree> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<NoteTree>, NoteTree>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<NoteTree>, NoteTree>,
              AsyncValue<NoteTree>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
