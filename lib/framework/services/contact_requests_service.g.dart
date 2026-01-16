// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_requests_service.dart';

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
    r'2822d5e56d684912386484586bd64f8e05944f49';

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
