// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_trash_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 回收站服务
///
/// 管理回收站列表，提供还原 / 彻底删除 / 清空操作；
/// 还原或删除后自动刷新树与回收站列表。

@ProviderFor(NoteTrashService)
final noteTrashServiceProvider = NoteTrashServiceProvider._();

/// 回收站服务
///
/// 管理回收站列表，提供还原 / 彻底删除 / 清空操作；
/// 还原或删除后自动刷新树与回收站列表。
final class NoteTrashServiceProvider
    extends $AsyncNotifierProvider<NoteTrashService, List<NoteBrief>> {
  /// 回收站服务
  ///
  /// 管理回收站列表，提供还原 / 彻底删除 / 清空操作；
  /// 还原或删除后自动刷新树与回收站列表。
  NoteTrashServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noteTrashServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noteTrashServiceHash();

  @$internal
  @override
  NoteTrashService create() => NoteTrashService();
}

String _$noteTrashServiceHash() => r'69730711fb0610b4ce23d727d7b866a6e2573e1f';

/// 回收站服务
///
/// 管理回收站列表，提供还原 / 彻底删除 / 清空操作；
/// 还原或删除后自动刷新树与回收站列表。

abstract class _$NoteTrashService extends $AsyncNotifier<List<NoteBrief>> {
  FutureOr<List<NoteBrief>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<NoteBrief>>, List<NoteBrief>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<NoteBrief>>, List<NoteBrief>>,
              AsyncValue<List<NoteBrief>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
