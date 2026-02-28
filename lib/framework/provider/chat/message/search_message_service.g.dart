// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_message_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 搜索消息服务
/// 功能：提供消息搜索、加载更多搜索结果等功能

@ProviderFor(SearchMessageService)
const searchMessageServiceProvider = SearchMessageServiceProvider._();

/// 搜索消息服务
/// 功能：提供消息搜索、加载更多搜索结果等功能
final class SearchMessageServiceProvider
    extends $NotifierProvider<SearchMessageService, SearchState> {
  /// 搜索消息服务
  /// 功能：提供消息搜索、加载更多搜索结果等功能
  const SearchMessageServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchMessageServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchMessageServiceHash();

  @$internal
  @override
  SearchMessageService create() => SearchMessageService();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchState>(value),
    );
  }
}

String _$searchMessageServiceHash() =>
    r'e8e6d6e78e2e4e28abbe65b3a0720eb72b6aa82e';

/// 搜索消息服务
/// 功能：提供消息搜索、加载更多搜索结果等功能

abstract class _$SearchMessageService extends $Notifier<SearchState> {
  SearchState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<SearchState, SearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SearchState, SearchState>,
              SearchState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
