// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_bubble_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 本设备偏好，默认关闭；不控制对方或同步到其他设备。

@ProviderFor(ChatBubbleTailEnabled)
final chatBubbleTailEnabledProvider = ChatBubbleTailEnabledProvider._();

/// 本设备偏好，默认关闭；不控制对方或同步到其他设备。
final class ChatBubbleTailEnabledProvider
    extends $NotifierProvider<ChatBubbleTailEnabled, bool> {
  /// 本设备偏好，默认关闭；不控制对方或同步到其他设备。
  ChatBubbleTailEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatBubbleTailEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatBubbleTailEnabledHash();

  @$internal
  @override
  ChatBubbleTailEnabled create() => ChatBubbleTailEnabled();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$chatBubbleTailEnabledHash() =>
    r'4e589787ca3021059ea369d2f5994944c54496a3';

/// 本设备偏好，默认关闭；不控制对方或同步到其他设备。

abstract class _$ChatBubbleTailEnabled extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
