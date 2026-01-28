// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_requests_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ContactRequestsService)
const contactRequestsServiceProvider = ContactRequestsServiceProvider._();

final class ContactRequestsServiceProvider
    extends
        $AsyncNotifierProvider<
          ContactRequestsService,
          List<ChatContactRequestVO>
        > {
  const ContactRequestsServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contactRequestsServiceProvider',
        isAutoDispose: true,
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
    r'999c5c316c7b67269477f09263be4dcff950c4d7';

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

/// 统计待处理的数量

@ProviderFor(pendingRequestCount)
const pendingRequestCountProvider = PendingRequestCountProvider._();

/// 统计待处理的数量

final class PendingRequestCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// 统计待处理的数量
  const PendingRequestCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingRequestCountProvider',
        isAutoDispose: true,
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
    r'03112f3df3768bfaba7a91e80a1d5587e82cf3b1';
