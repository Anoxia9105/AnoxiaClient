// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_list_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ContactListService)
const contactListServiceProvider = ContactListServiceProvider._();

final class ContactListServiceProvider
    extends $AsyncNotifierProvider<ContactListService, List<ChatContactVO>> {
  const ContactListServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contactListServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contactListServiceHash();

  @$internal
  @override
  ContactListService create() => ContactListService();
}

String _$contactListServiceHash() =>
    r'0de15bd85e721fe35de0354cdedb145080996550';

abstract class _$ContactListService
    extends $AsyncNotifier<List<ChatContactVO>> {
  FutureOr<List<ChatContactVO>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<List<ChatContactVO>>, List<ChatContactVO>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ChatContactVO>>, List<ChatContactVO>>,
              AsyncValue<List<ChatContactVO>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(sortedContactGroups)
const sortedContactGroupsProvider = SortedContactGroupsProvider._();

final class SortedContactGroupsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, List<ChatContactVO>>>,
          Map<String, List<ChatContactVO>>,
          FutureOr<Map<String, List<ChatContactVO>>>
        >
    with
        $FutureModifier<Map<String, List<ChatContactVO>>>,
        $FutureProvider<Map<String, List<ChatContactVO>>> {
  const SortedContactGroupsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sortedContactGroupsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sortedContactGroupsHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, List<ChatContactVO>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, List<ChatContactVO>>> create(Ref ref) {
    return sortedContactGroups(ref);
  }
}

String _$sortedContactGroupsHash() =>
    r'6c596adb226661aa64008e2a7453492085ed33e7';
