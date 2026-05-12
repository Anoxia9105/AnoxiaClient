// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_selection_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ContactSelection)
const contactSelectionProvider = ContactSelectionProvider._();

final class ContactSelectionProvider
    extends $NotifierProvider<ContactSelection, ContactSelectionState> {
  const ContactSelectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contactSelectionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contactSelectionHash();

  @$internal
  @override
  ContactSelection create() => ContactSelection();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContactSelectionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContactSelectionState>(value),
    );
  }
}

String _$contactSelectionHash() => r'6ca18b16512505066f78a7c7d232551bab3d3f1c';

abstract class _$ContactSelection extends $Notifier<ContactSelectionState> {
  ContactSelectionState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<ContactSelectionState, ContactSelectionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ContactSelectionState, ContactSelectionState>,
              ContactSelectionState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
