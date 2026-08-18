// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_content_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 当前编辑中的笔记会话
///
/// 持有标题 / Quill Delta / 纯文本与脏标记、保存状态。
/// 编辑器 Widget 负责防抖计时，到点调用 [save] 落库。

@ProviderFor(NoteSessionService)
final noteSessionServiceProvider = NoteSessionServiceProvider._();

/// 当前编辑中的笔记会话
///
/// 持有标题 / Quill Delta / 纯文本与脏标记、保存状态。
/// 编辑器 Widget 负责防抖计时，到点调用 [save] 落库。
final class NoteSessionServiceProvider
    extends $NotifierProvider<NoteSessionService, NoteEditSession?> {
  /// 当前编辑中的笔记会话
  ///
  /// 持有标题 / Quill Delta / 纯文本与脏标记、保存状态。
  /// 编辑器 Widget 负责防抖计时，到点调用 [save] 落库。
  NoteSessionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noteSessionServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noteSessionServiceHash();

  @$internal
  @override
  NoteSessionService create() => NoteSessionService();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NoteEditSession? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NoteEditSession?>(value),
    );
  }
}

String _$noteSessionServiceHash() =>
    r'ff54644b13bc16bebd715186b22aebd6e42400a2';

/// 当前编辑中的笔记会话
///
/// 持有标题 / Quill Delta / 纯文本与脏标记、保存状态。
/// 编辑器 Widget 负责防抖计时，到点调用 [save] 落库。

abstract class _$NoteSessionService extends $Notifier<NoteEditSession?> {
  NoteEditSession? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<NoteEditSession?, NoteEditSession?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NoteEditSession?, NoteEditSession?>,
              NoteEditSession?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
