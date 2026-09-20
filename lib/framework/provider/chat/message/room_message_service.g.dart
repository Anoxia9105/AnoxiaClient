// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_message_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(roomMessages)
final roomMessagesProvider = RoomMessagesFamily._();

final class RoomMessagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ChatMessage>>,
          List<ChatMessage>,
          Stream<List<ChatMessage>>
        >
    with
        $FutureModifier<List<ChatMessage>>,
        $StreamProvider<List<ChatMessage>> {
  RoomMessagesProvider._({
    required RoomMessagesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'roomMessagesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$roomMessagesHash();

  @override
  String toString() {
    return r'roomMessagesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<ChatMessage>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ChatMessage>> create(Ref ref) {
    final argument = this.argument as String;
    return roomMessages(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RoomMessagesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$roomMessagesHash() => r'00a58eea8e04d21c8dba663826547ffd7e56529c';

final class RoomMessagesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<ChatMessage>>, String> {
  RoomMessagesFamily._()
    : super(
        retry: null,
        name: r'roomMessagesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RoomMessagesProvider call(String roomId) =>
      RoomMessagesProvider._(argument: roomId, from: this);

  @override
  String toString() => r'roomMessagesProvider';
}

@ProviderFor(ChatMessages)
final chatMessagesProvider = ChatMessagesProvider._();

final class ChatMessagesProvider extends $NotifierProvider<ChatMessages, void> {
  ChatMessagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatMessagesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatMessagesHash();

  @$internal
  @override
  ChatMessages create() => ChatMessages();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$chatMessagesHash() => r'b1dbe337ae1030cb48f6be423591f0b43c549933';

abstract class _$ChatMessages extends $Notifier<void> {
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

@ProviderFor(ChatHasMore)
final chatHasMoreProvider = ChatHasMoreProvider._();

final class ChatHasMoreProvider
    extends $NotifierProvider<ChatHasMore, Map<String, bool>> {
  ChatHasMoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatHasMoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatHasMoreHash();

  @$internal
  @override
  ChatHasMore create() => ChatHasMore();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, bool> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, bool>>(value),
    );
  }
}

String _$chatHasMoreHash() => r'255f95b2907b314618d54bb158284bc4661a5650';

abstract class _$ChatHasMore extends $Notifier<Map<String, bool>> {
  Map<String, bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Map<String, bool>, Map<String, bool>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, bool>, Map<String, bool>>,
              Map<String, bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
