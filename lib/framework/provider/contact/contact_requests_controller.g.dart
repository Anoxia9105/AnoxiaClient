// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_requests_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 好友申请列表服务
///
/// 管理所有收到的好友请求，支持请求处理和列表刷新。
///
/// 采用 keepAlive 模式，确保请求列表在全局共享。

@ProviderFor(ContactRequestsService)
const contactRequestsServiceProvider = ContactRequestsServiceProvider._();

/// 好友申请列表服务
///
/// 管理所有收到的好友请求，支持请求处理和列表刷新。
///
/// 采用 keepAlive 模式，确保请求列表在全局共享。
final class ContactRequestsServiceProvider
    extends
        $AsyncNotifierProvider<
          ContactRequestsService,
          List<ChatContactRequestVO>
        > {
  /// 好友申请列表服务
  ///
  /// 管理所有收到的好友请求，支持请求处理和列表刷新。
  ///
  /// 采用 keepAlive 模式，确保请求列表在全局共享。
  const ContactRequestsServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contactRequestsServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contactRequestsServiceHash();

  @$internal
  @override
  ContactRequestsService create() => ContactRequestsService();
}

String _$contactRequestsServiceHash() =>
    r'6bee6e02a44768e7b79f535bf5cd25e5aedaa93a';

/// 好友申请列表服务
///
/// 管理所有收到的好友请求，支持请求处理和列表刷新。
///
/// 采用 keepAlive 模式，确保请求列表在全局共享。

abstract class _$ContactRequestsService
    extends $AsyncNotifier<List<ChatContactRequestVO>> {
  FutureOr<List<ChatContactRequestVO>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<ChatContactRequestVO>>,
              List<ChatContactRequestVO>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<ChatContactRequestVO>>,
                List<ChatContactRequestVO>
              >,
              AsyncValue<List<ChatContactRequestVO>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// 待处理好友申请数量
///
/// 仅统计状态为 0（待处理）的请求数

@ProviderFor(pendingRequestCount)
const pendingRequestCountProvider = PendingRequestCountProvider._();

/// 待处理好友申请数量
///
/// 仅统计状态为 0（待处理）的请求数

final class PendingRequestCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// 待处理好友申请数量
  ///
  /// 仅统计状态为 0（待处理）的请求数
  const PendingRequestCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingRequestCountProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingRequestCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return pendingRequestCount(ref);
  }
}

String _$pendingRequestCountHash() =>
    r'e0e837c7b80e5aaeb1c6d32d578b183dc7a4e409';
