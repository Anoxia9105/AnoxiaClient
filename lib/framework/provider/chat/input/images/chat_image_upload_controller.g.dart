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
    extends $NotifierProvider<ChatImageUploadController, Map<String, String>> {
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
  Override overrideWithValue(Map<String, String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, String>>(value),
    );
  }
}

String _$chatImageUploadControllerHash() =>
    r'f1d6fbcacba45e3ddcd28ae49c9b20034172e66d';

abstract class _$ChatImageUploadController
    extends $Notifier<Map<String, String>> {
  Map<String, String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<Map<String, String>, Map<String, String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, String>, Map<String, String>>,
              Map<String, String>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
