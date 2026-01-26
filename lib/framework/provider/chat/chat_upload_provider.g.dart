// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_upload_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 上传状态（UI 用）

@ProviderFor(IsUploading)
const isUploadingProvider = IsUploadingProvider._();

/// 上传状态（UI 用）
final class IsUploadingProvider extends $NotifierProvider<IsUploading, bool> {
  /// 上传状态（UI 用）
  const IsUploadingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isUploadingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isUploadingHash();

  @$internal
  @override
  IsUploading create() => IsUploading();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isUploadingHash() => r'eacb54593afcca0de5478723f81d15dc061b15d3';

/// 上传状态（UI 用）

abstract class _$IsUploading extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(ChatUploadController)
const chatUploadControllerProvider = ChatUploadControllerProvider._();

final class ChatUploadControllerProvider
    extends $NotifierProvider<ChatUploadController, void> {
  const ChatUploadControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatUploadControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatUploadControllerHash();

  @$internal
  @override
  ChatUploadController create() => ChatUploadController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$chatUploadControllerHash() =>
    r'78aa9b486cfa8c980d6513a9f07af17ed3a58abe';

abstract class _$ChatUploadController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
