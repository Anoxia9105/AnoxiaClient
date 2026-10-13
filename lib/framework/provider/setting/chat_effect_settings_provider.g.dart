// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_effect_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 本设备偏好，默认开启；不控制对方或同步到其他设备。

@ProviderFor(ChatEffectsEnabled)
final chatEffectsEnabledProvider = ChatEffectsEnabledProvider._();

/// 本设备偏好，默认开启；不控制对方或同步到其他设备。
final class ChatEffectsEnabledProvider
    extends $NotifierProvider<ChatEffectsEnabled, bool> {
  /// 本设备偏好，默认开启；不控制对方或同步到其他设备。
  ChatEffectsEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatEffectsEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatEffectsEnabledHash();

  @$internal
  @override
  ChatEffectsEnabled create() => ChatEffectsEnabled();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$chatEffectsEnabledHash() =>
    r'c4c1c35541648317dd0188fd8d5e12edfbf2c8ea';

/// 本设备偏好，默认开启；不控制对方或同步到其他设备。

abstract class _$ChatEffectsEnabled extends $Notifier<bool> {
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
