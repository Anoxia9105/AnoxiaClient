// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'high_message_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 高优先级消息服务
///
/// 处理高频、实时性要求高的消息类型，包括：
/// - 正在输入状态（TYPING_STATUS）
/// - 通话邀请/接受/取消/拒绝（CALL_INVITE, CALL_ACCEPT, CALL_CANCEL, CALL_REJECT）
/// - 通话信令（CALL_CANDIDATE, CALL_MEDIA_CHANGE）
/// - 消息撤回（MSG_REVOKE）
/// - 系统踢人（SYSTEM_KICK）
///
/// 采用 keepAlive 模式确保全局共享，自动管理定时器和状态清理。

@ProviderFor(HighMessageService)
final highMessageServiceProvider = HighMessageServiceProvider._();

/// 高优先级消息服务
///
/// 处理高频、实时性要求高的消息类型，包括：
/// - 正在输入状态（TYPING_STATUS）
/// - 通话邀请/接受/取消/拒绝（CALL_INVITE, CALL_ACCEPT, CALL_CANCEL, CALL_REJECT）
/// - 通话信令（CALL_CANDIDATE, CALL_MEDIA_CHANGE）
/// - 消息撤回（MSG_REVOKE）
/// - 系统踢人（SYSTEM_KICK）
///
/// 采用 keepAlive 模式确保全局共享，自动管理定时器和状态清理。
final class HighMessageServiceProvider
    extends
        $NotifierProvider<
          HighMessageService,
          Map<String, Map<HighMessageType, HighMessage>>
        > {
  /// 高优先级消息服务
  ///
  /// 处理高频、实时性要求高的消息类型，包括：
  /// - 正在输入状态（TYPING_STATUS）
  /// - 通话邀请/接受/取消/拒绝（CALL_INVITE, CALL_ACCEPT, CALL_CANCEL, CALL_REJECT）
  /// - 通话信令（CALL_CANDIDATE, CALL_MEDIA_CHANGE）
  /// - 消息撤回（MSG_REVOKE）
  /// - 系统踢人（SYSTEM_KICK）
  ///
  /// 采用 keepAlive 模式确保全局共享，自动管理定时器和状态清理。
  HighMessageServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'highMessageServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$highMessageServiceHash();

  @$internal
  @override
  HighMessageService create() => HighMessageService();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    Map<String, Map<HighMessageType, HighMessage>> value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<Map<String, Map<HighMessageType, HighMessage>>>(
            value,
          ),
    );
  }
}

String _$highMessageServiceHash() =>
    r'd7b6fed32ef07c0fe4e7176a5a1e761a73688e67';

/// 高优先级消息服务
///
/// 处理高频、实时性要求高的消息类型，包括：
/// - 正在输入状态（TYPING_STATUS）
/// - 通话邀请/接受/取消/拒绝（CALL_INVITE, CALL_ACCEPT, CALL_CANCEL, CALL_REJECT）
/// - 通话信令（CALL_CANDIDATE, CALL_MEDIA_CHANGE）
/// - 消息撤回（MSG_REVOKE）
/// - 系统踢人（SYSTEM_KICK）
///
/// 采用 keepAlive 模式确保全局共享，自动管理定时器和状态清理。

abstract class _$HighMessageService
    extends $Notifier<Map<String, Map<HighMessageType, HighMessage>>> {
  Map<String, Map<HighMessageType, HighMessage>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              Map<String, Map<HighMessageType, HighMessage>>,
              Map<String, Map<HighMessageType, HighMessage>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, Map<HighMessageType, HighMessage>>,
                Map<String, Map<HighMessageType, HighMessage>>
              >,
              Map<String, Map<HighMessageType, HighMessage>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
