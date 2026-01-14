// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_chat_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AiChatController)
const aiChatControllerProvider = AiChatControllerProvider._();

final class AiChatControllerProvider
    extends $NotifierProvider<AiChatController, List<AiChatMessage>> {
  const AiChatControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiChatControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiChatControllerHash();

  @$internal
  @override
  AiChatController create() => AiChatController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<AiChatMessage> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<AiChatMessage>>(value),
    );
  }
}

String _$aiChatControllerHash() => r'69fccf28bde2c89764fb2ba00a45f8baa52499fa';

abstract class _$AiChatController extends $Notifier<List<AiChatMessage>> {
  List<AiChatMessage> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<List<AiChatMessage>, List<AiChatMessage>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<AiChatMessage>, List<AiChatMessage>>,
              List<AiChatMessage>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
