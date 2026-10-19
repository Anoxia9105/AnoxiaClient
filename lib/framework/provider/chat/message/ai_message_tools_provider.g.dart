// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_message_tools_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 翻译控制器：key = `messageId|targetLang`（按消息 family，内存即缓存）

@ProviderFor(AiTranslateController)
final aiTranslateControllerProvider = AiTranslateControllerFamily._();

/// 翻译控制器：key = `messageId|targetLang`（按消息 family，内存即缓存）
final class AiTranslateControllerProvider
    extends $NotifierProvider<AiTranslateController, AiToolState> {
  /// 翻译控制器：key = `messageId|targetLang`（按消息 family，内存即缓存）
  AiTranslateControllerProvider._({
    required AiTranslateControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'aiTranslateControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$aiTranslateControllerHash();

  @override
  String toString() {
    return r'aiTranslateControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AiTranslateController create() => AiTranslateController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AiToolState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AiToolState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AiTranslateControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$aiTranslateControllerHash() =>
    r'84bd8f519476f30d3d80bd10a61793cecb66560b';

/// 翻译控制器：key = `messageId|targetLang`（按消息 family，内存即缓存）

final class AiTranslateControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          AiTranslateController,
          AiToolState,
          AiToolState,
          AiToolState,
          String
        > {
  AiTranslateControllerFamily._()
    : super(
        retry: null,
        name: r'aiTranslateControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 翻译控制器：key = `messageId|targetLang`（按消息 family，内存即缓存）

  AiTranslateControllerProvider call(String key) =>
      AiTranslateControllerProvider._(argument: key, from: this);

  @override
  String toString() => r'aiTranslateControllerProvider';
}

/// 翻译控制器：key = `messageId|targetLang`（按消息 family，内存即缓存）

abstract class _$AiTranslateController extends $Notifier<AiToolState> {
  late final _$args = ref.$arg as String;
  String get key => _$args;

  AiToolState build(String key);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AiToolState, AiToolState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AiToolState, AiToolState>,
              AiToolState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// 未读总结控制器：按房间 family（一次生成缓存，重开弹层不重拉）

@ProviderFor(AiUnreadSummaryController)
final aiUnreadSummaryControllerProvider = AiUnreadSummaryControllerFamily._();

/// 未读总结控制器：按房间 family（一次生成缓存，重开弹层不重拉）
final class AiUnreadSummaryControllerProvider
    extends $NotifierProvider<AiUnreadSummaryController, AiToolState> {
  /// 未读总结控制器：按房间 family（一次生成缓存，重开弹层不重拉）
  AiUnreadSummaryControllerProvider._({
    required AiUnreadSummaryControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'aiUnreadSummaryControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$aiUnreadSummaryControllerHash();

  @override
  String toString() {
    return r'aiUnreadSummaryControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AiUnreadSummaryController create() => AiUnreadSummaryController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AiToolState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AiToolState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AiUnreadSummaryControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$aiUnreadSummaryControllerHash() =>
    r'b6089f265666aca68af5cad593a60ead8cb54ebb';

/// 未读总结控制器：按房间 family（一次生成缓存，重开弹层不重拉）

final class AiUnreadSummaryControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          AiUnreadSummaryController,
          AiToolState,
          AiToolState,
          AiToolState,
          String
        > {
  AiUnreadSummaryControllerFamily._()
    : super(
        retry: null,
        name: r'aiUnreadSummaryControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 未读总结控制器：按房间 family（一次生成缓存，重开弹层不重拉）

  AiUnreadSummaryControllerProvider call(String roomId) =>
      AiUnreadSummaryControllerProvider._(argument: roomId, from: this);

  @override
  String toString() => r'aiUnreadSummaryControllerProvider';
}

/// 未读总结控制器：按房间 family（一次生成缓存，重开弹层不重拉）

abstract class _$AiUnreadSummaryController extends $Notifier<AiToolState> {
  late final _$args = ref.$arg as String;
  String get roomId => _$args;

  AiToolState build(String roomId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AiToolState, AiToolState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AiToolState, AiToolState>,
              AiToolState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
