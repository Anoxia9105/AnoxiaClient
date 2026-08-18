// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_tag_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 记事本标签服务
///
/// 提供标签列表（含关联笔记数），供树面板的标签过滤栏使用。
/// 标签编辑（增删）成功后调用 [refresh] 拉取最新列表。

@ProviderFor(NoteTagService)
final noteTagServiceProvider = NoteTagServiceProvider._();

/// 记事本标签服务
///
/// 提供标签列表（含关联笔记数），供树面板的标签过滤栏使用。
/// 标签编辑（增删）成功后调用 [refresh] 拉取最新列表。
final class NoteTagServiceProvider
    extends $AsyncNotifierProvider<NoteTagService, List<NoteTag>> {
  /// 记事本标签服务
  ///
  /// 提供标签列表（含关联笔记数），供树面板的标签过滤栏使用。
  /// 标签编辑（增删）成功后调用 [refresh] 拉取最新列表。
  NoteTagServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noteTagServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noteTagServiceHash();

  @$internal
  @override
  NoteTagService create() => NoteTagService();
}

String _$noteTagServiceHash() => r'ddb634986605c5a413d3a097e6f9718dcb58b96a';

/// 记事本标签服务
///
/// 提供标签列表（含关联笔记数），供树面板的标签过滤栏使用。
/// 标签编辑（增删）成功后调用 [refresh] 拉取最新列表。

abstract class _$NoteTagService extends $AsyncNotifier<List<NoteTag>> {
  FutureOr<List<NoteTag>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<NoteTag>>, List<NoteTag>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<NoteTag>>, List<NoteTag>>,
              AsyncValue<List<NoteTag>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
