// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_version_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 记事本版本历史服务
///
/// 版本列表每次从服务端拉取；还原成功后刷新树，若还原的是当前
/// 编辑中的笔记则重载会话内容。

@ProviderFor(NoteVersionService)
final noteVersionServiceProvider = NoteVersionServiceProvider._();

/// 记事本版本历史服务
///
/// 版本列表每次从服务端拉取；还原成功后刷新树，若还原的是当前
/// 编辑中的笔记则重载会话内容。
final class NoteVersionServiceProvider
    extends $AsyncNotifierProvider<NoteVersionService, List<NoteDocVersion>> {
  /// 记事本版本历史服务
  ///
  /// 版本列表每次从服务端拉取；还原成功后刷新树，若还原的是当前
  /// 编辑中的笔记则重载会话内容。
  NoteVersionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noteVersionServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noteVersionServiceHash();

  @$internal
  @override
  NoteVersionService create() => NoteVersionService();
}

String _$noteVersionServiceHash() =>
    r'1da5e16ac72406e79a29b68eb4190f1bb9bb617b';

/// 记事本版本历史服务
///
/// 版本列表每次从服务端拉取；还原成功后刷新树，若还原的是当前
/// 编辑中的笔记则重载会话内容。

abstract class _$NoteVersionService
    extends $AsyncNotifier<List<NoteDocVersion>> {
  FutureOr<List<NoteDocVersion>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<NoteDocVersion>>, List<NoteDocVersion>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<NoteDocVersion>>,
                List<NoteDocVersion>
              >,
              AsyncValue<List<NoteDocVersion>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
