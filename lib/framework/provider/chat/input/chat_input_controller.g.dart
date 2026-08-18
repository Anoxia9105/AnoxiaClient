// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_input_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 聊天输入控制器
///
/// 负责管理聊天输入框的 QuillController，处理文本输入、@提及、图片/文件上传、
/// 消息发送（文本、富文本、表情、图片、文件、语音、卡片、位置）、输入状态通知、
/// 回复目标、输入超时等核心交互逻辑。

@ProviderFor(ChatInputController)
final chatInputControllerProvider = ChatInputControllerFamily._();

/// 聊天输入控制器
///
/// 负责管理聊天输入框的 QuillController，处理文本输入、@提及、图片/文件上传、
/// 消息发送（文本、富文本、表情、图片、文件、语音、卡片、位置）、输入状态通知、
/// 回复目标、输入超时等核心交互逻辑。
final class ChatInputControllerProvider
    extends $NotifierProvider<ChatInputController, QuillController> {
  /// 聊天输入控制器
  ///
  /// 负责管理聊天输入框的 QuillController，处理文本输入、@提及、图片/文件上传、
  /// 消息发送（文本、富文本、表情、图片、文件、语音、卡片、位置）、输入状态通知、
  /// 回复目标、输入超时等核心交互逻辑。
  ChatInputControllerProvider._({
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
    r'c5fa0d94f278943e98fcb56cb6384694607e5517';

/// 聊天输入控制器
///
/// 负责管理聊天输入框的 QuillController，处理文本输入、@提及、图片/文件上传、
/// 消息发送（文本、富文本、表情、图片、文件、语音、卡片、位置）、输入状态通知、
/// 回复目标、输入超时等核心交互逻辑。

final class ChatInputControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ChatInputController,
          QuillController,
          QuillController,
          QuillController,
          String
        > {
  ChatInputControllerFamily._()
    : super(
        retry: null,
        name: r'chatInputControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// 聊天输入控制器
  ///
  /// 负责管理聊天输入框的 QuillController，处理文本输入、@提及、图片/文件上传、
  /// 消息发送（文本、富文本、表情、图片、文件、语音、卡片、位置）、输入状态通知、
  /// 回复目标、输入超时等核心交互逻辑。

  ChatInputControllerProvider call(String roomId) =>
      ChatInputControllerProvider._(argument: roomId, from: this);

  @override
  String toString() => r'chatInputControllerProvider';
}

/// 聊天输入控制器
///
/// 负责管理聊天输入框的 QuillController，处理文本输入、@提及、图片/文件上传、
/// 消息发送（文本、富文本、表情、图片、文件、语音、卡片、位置）、输入状态通知、
/// 回复目标、输入超时等核心交互逻辑。

abstract class _$ChatInputController extends $Notifier<QuillController> {
  late final _$args = ref.$arg as String;
  String get roomId => _$args;

  QuillController build(String roomId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<QuillController, QuillController>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<QuillController, QuillController>,
              QuillController,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// 聊天输入框的焦点节点 Provider
///
/// 用于在发送消息后（桌面端）自动获取焦点。

@ProviderFor(chatFocusNode)
final chatFocusNodeProvider = ChatFocusNodeFamily._();

/// 聊天输入框的焦点节点 Provider
///
/// 用于在发送消息后（桌面端）自动获取焦点。

final class ChatFocusNodeProvider
    extends $FunctionalProvider<FocusNode, FocusNode, FocusNode>
    with $Provider<FocusNode> {
  /// 聊天输入框的焦点节点 Provider
  ///
  /// 用于在发送消息后（桌面端）自动获取焦点。
  ChatFocusNodeProvider._({
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

/// 聊天输入框的焦点节点 Provider
///
/// 用于在发送消息后（桌面端）自动获取焦点。

final class ChatFocusNodeFamily extends $Family
    with $FunctionalFamilyOverride<FocusNode, String> {
  ChatFocusNodeFamily._()
    : super(
        retry: null,
        name: r'chatFocusNodeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 聊天输入框的焦点节点 Provider
  ///
  /// 用于在发送消息后（桌面端）自动获取焦点。

  ChatFocusNodeProvider call(String roomId) =>
      ChatFocusNodeProvider._(argument: roomId, from: this);

  @override
  String toString() => r'chatFocusNodeProvider';
}

/// @提及状态管理
///
/// 用于管理 @ 提及选择器的显示/隐藏、搜索文本、光标位置等信息。

@ProviderFor(MentionState)
final mentionStateProvider = MentionStateProvider._();

/// @提及状态管理
///
/// 用于管理 @ 提及选择器的显示/隐藏、搜索文本、光标位置等信息。
final class MentionStateProvider
    extends $NotifierProvider<MentionState, MentionStateData> {
  /// @提及状态管理
  ///
  /// 用于管理 @ 提及选择器的显示/隐藏、搜索文本、光标位置等信息。
  MentionStateProvider._()
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

String _$mentionStateHash() => r'a9e513f26aa32f07f6a66b44ca742626262cc3ae';

/// @提及状态管理
///
/// 用于管理 @ 提及选择器的显示/隐藏、搜索文本、光标位置等信息。

abstract class _$MentionState extends $Notifier<MentionStateData> {
  MentionStateData build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MentionStateData, MentionStateData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MentionStateData, MentionStateData>,
              MentionStateData,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
