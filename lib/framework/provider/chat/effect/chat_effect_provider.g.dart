// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_effect_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(chatEffectDispatcher)
final chatEffectDispatcherProvider = ChatEffectDispatcherProvider._();

final class ChatEffectDispatcherProvider
    extends
        $FunctionalProvider<
          ChatEffectDispatcher,
          ChatEffectDispatcher,
          ChatEffectDispatcher
        >
    with $Provider<ChatEffectDispatcher> {
  ChatEffectDispatcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatEffectDispatcherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatEffectDispatcherHash();

  @$internal
  @override
  $ProviderElement<ChatEffectDispatcher> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ChatEffectDispatcher create(Ref ref) {
    return chatEffectDispatcher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatEffectDispatcher value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatEffectDispatcher>(value),
    );
  }
}

String _$chatEffectDispatcherHash() =>
    r'12e403274b15786ec9c3a5295acf1fcb6b2bc806';
