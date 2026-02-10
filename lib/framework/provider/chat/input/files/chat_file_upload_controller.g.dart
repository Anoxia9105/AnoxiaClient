// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_file_upload_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ChatFileUploadController)
const chatFileUploadControllerProvider = ChatFileUploadControllerProvider._();

final class ChatFileUploadControllerProvider
    extends $NotifierProvider<ChatFileUploadController, Map<String, String>> {
  const ChatFileUploadControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatFileUploadControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatFileUploadControllerHash();

  @$internal
  @override
  ChatFileUploadController create() => ChatFileUploadController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, String>>(value),
    );
  }
}

String _$chatFileUploadControllerHash() =>
    r'ef56309c127b214900a9b8bdbbd798d3c50d0b35';

abstract class _$ChatFileUploadController
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
