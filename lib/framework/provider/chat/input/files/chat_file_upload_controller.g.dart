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
    extends
        $NotifierProvider<ChatFileUploadController, Map<String, UploadEntry>> {
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
  Override overrideWithValue(Map<String, UploadEntry> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, UploadEntry>>(value),
    );
  }
}

String _$chatFileUploadControllerHash() =>
    r'fa7130c672966943c27f21a7b8b82228df1319b5';

abstract class _$ChatFileUploadController
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
