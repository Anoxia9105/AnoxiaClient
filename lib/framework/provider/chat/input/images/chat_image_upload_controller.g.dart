// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_image_upload_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ChatImageUploadController)
const chatImageUploadControllerProvider = ChatImageUploadControllerProvider._();

final class ChatImageUploadControllerProvider
    extends
        $NotifierProvider<ChatImageUploadController, Map<String, UploadEntry>> {
  const ChatImageUploadControllerProvider._()
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

abstract class _$ChatImageUploadController
    extends $Notifier<Map<String, UploadEntry>> {
  Map<String, UploadEntry> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
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
    element.handleValue(ref, created);
  }
}
