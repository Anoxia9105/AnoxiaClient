// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_list_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ContactListService)
const contactListServiceProvider = ContactListServiceProvider._();

final class ContactListServiceProvider
    extends
        $AsyncNotifierProvider<ContactListService, Map<int, ChatContactVO>> {
  const ContactListServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contactListServiceProvider',
        isAutoDispose: false,
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
    r'acda1d2d0e2e11a84e05633e1bf36324c998552a';

abstract class _$ContactListService
    extends $AsyncNotifier<Map<int, ChatContactVO>> {
  FutureOr<Map<int, ChatContactVO>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<
              AsyncValue<Map<int, ChatContactVO>>,
              Map<int, ChatContactVO>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<int, ChatContactVO>>,
                Map<int, ChatContactVO>
              >,
              AsyncValue<Map<int, ChatContactVO>>,
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
        isAutoDispose: false,
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
    r'e2091c06b5f436da79354bef2b6b5381c034911d';
