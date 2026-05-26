// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_image_upload_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 聊天图片上传控制器
///
/// 处理图片选择、粘贴和上传功能

@ProviderFor(ChatImageUploadController)
final chatImageUploadControllerProvider = ChatImageUploadControllerProvider._();

/// 聊天图片上传控制器
///
/// 处理图片选择、粘贴和上传功能
final class ChatImageUploadControllerProvider
    extends
        $NotifierProvider<ChatImageUploadController, Map<String, UploadEntry>> {
  /// 聊天图片上传控制器
  ///
  /// 处理图片选择、粘贴和上传功能
  ChatImageUploadControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatImageUploadControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatImageUploadControllerHash();

  @$internal
  @override
  ChatImageUploadController create() => ChatImageUploadController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, UploadEntry> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, UploadEntry>>(value),
    );
  }
}

String _$chatImageUploadControllerHash() =>
    r'f54cedd000d156b2126c6a4b637e028b8ac9d25c';

/// 聊天图片上传控制器
///
/// 处理图片选择、粘贴和上传功能

abstract class _$ChatImageUploadController
    extends $Notifier<Map<String, UploadEntry>> {
  Map<String, UploadEntry> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<Map<String, UploadEntry>, Map<String, UploadEntry>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, UploadEntry>, Map<String, UploadEntry>>,
              Map<String, UploadEntry>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
