// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_input_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ChatInputController)
const chatInputControllerProvider = ChatInputControllerFamily._();

final class ChatInputControllerProvider
    extends $NotifierProvider<ChatInputController, QuillController> {
  const ChatInputControllerProvider._({
    required ChatInputControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'chatInputControllerProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatInputControllerHash();

  @override
  String toString() {
    return r'chatInputControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ChatInputController create() => ChatInputController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QuillController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QuillController>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChatInputControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatInputControllerHash() =>
    r'225247206843bd6c0326b52ddb812dd76859c2af';

final class ChatInputControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ChatInputController,
          QuillController,
          QuillController,
          QuillController,
          String
        > {
  const ChatInputControllerFamily._()
    : super(
        retry: null,
        name: r'chatInputControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  ChatInputControllerProvider call(String roomId) =>
      ChatInputControllerProvider._(argument: roomId, from: this);

  @override
  String toString() => r'chatInputControllerProvider';
}

abstract class _$ChatInputController extends $Notifier<QuillController> {
  late final _$args = ref.$arg as String;
  String get roomId => _$args;

  QuillController build(String roomId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<QuillController, QuillController>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<QuillController, QuillController>,
              QuillController,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// 聊天输入框焦点

@ProviderFor(chatFocusNode)
const chatFocusNodeProvider = ChatFocusNodeFamily._();

/// 聊天输入框焦点

final class ChatFocusNodeProvider
    extends $FunctionalProvider<FocusNode, FocusNode, FocusNode>
    with $Provider<FocusNode> {
  /// 聊天输入框焦点
  const ChatFocusNodeProvider._({
    required ChatFocusNodeFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'chatFocusNodeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatFocusNodeHash();

  @override
  String toString() {
    return r'chatFocusNodeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<FocusNode> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FocusNode create(Ref ref) {
    final argument = this.argument as String;
    return chatFocusNode(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FocusNode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FocusNode>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChatFocusNodeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatFocusNodeHash() => r'4660d1fd2f3c46541ef6c2a8488481cd922b89dc';

/// 聊天输入框焦点

final class ChatFocusNodeFamily extends $Family
    with $FunctionalFamilyOverride<FocusNode, String> {
  const ChatFocusNodeFamily._()
    : super(
        retry: null,
        name: r'chatFocusNodeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 聊天输入框焦点

  ChatFocusNodeProvider call(String roomId) =>
      ChatFocusNodeProvider._(argument: roomId, from: this);

  @override
  String toString() => r'chatFocusNodeProvider';
}

@ProviderFor(MentionState)
const mentionStateProvider = MentionStateProvider._();

final class MentionStateProvider
    extends $NotifierProvider<MentionState, MentionStateData> {
  const MentionStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mentionStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mentionStateHash();

  @$internal
  @override
  MentionState create() => MentionState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MentionStateData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MentionStateData>(value),
    );
  }
}

String _$mentionStateHash() => r'4979a8c55c48aba2ee915f321b876beb71cd8461';

abstract class _$MentionState extends $Notifier<MentionStateData> {
  MentionStateData build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<MentionStateData, MentionStateData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MentionStateData, MentionStateData>,
              MentionStateData,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
