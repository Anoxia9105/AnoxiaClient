// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_detail_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(contactDetailData)
const contactDetailDataProvider = ContactDetailDataFamily._();

final class ContactDetailDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<ChatContactDetailVO>,
          ChatContactDetailVO,
          FutureOr<ChatContactDetailVO>
        >
    with
        $FutureModifier<ChatContactDetailVO>,
        $FutureProvider<ChatContactDetailVO> {
  const ContactDetailDataProvider._({
    required ContactDetailDataFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'contactDetailDataProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$contactDetailDataHash();

  @override
  String toString() {
    return r'contactDetailDataProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ChatContactDetailVO> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ChatContactDetailVO> create(Ref ref) {
    final argument = this.argument as int;
    return contactDetailData(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ContactDetailDataProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$contactDetailDataHash() => r'c4950440e53db566327e6d04237cbd3e3170f3d9';

final class ContactDetailDataFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ChatContactDetailVO>, int> {
  const ContactDetailDataFamily._()
    : super(
        retry: null,
        name: r'contactDetailDataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  ContactDetailDataProvider call(int userId) =>
      ContactDetailDataProvider._(argument: userId, from: this);

  @override
  String toString() => r'contactDetailDataProvider';
}
