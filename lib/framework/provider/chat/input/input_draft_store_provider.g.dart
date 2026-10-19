// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'input_draft_store_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 会话输入草稿存取服务（每会话最多一行草稿）。

@ProviderFor(InputDraftStore)
final inputDraftStoreProvider = InputDraftStoreProvider._();

/// 会话输入草稿存取服务（每会话最多一行草稿）。
final class InputDraftStoreProvider
    extends $NotifierProvider<InputDraftStore, void> {
  /// 会话输入草稿存取服务（每会话最多一行草稿）。
  InputDraftStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inputDraftStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inputDraftStoreHash();

  @$internal
  @override
  InputDraftStore create() => InputDraftStore();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$inputDraftStoreHash() => r'008cc15a1a9dbbe8ce2632fecec55da516ccf63e';

/// 会话输入草稿存取服务（每会话最多一行草稿）。

abstract class _$InputDraftStore extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
