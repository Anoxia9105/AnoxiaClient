// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'high_message_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HighMessageService)
const highMessageServiceProvider = HighMessageServiceProvider._();

final class HighMessageServiceProvider
    extends
        $NotifierProvider<
          HighMessageService,
          Map<String, Map<HighMessageType, HighMessage>>
        > {
  const HighMessageServiceProvider._()
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
    r'5775672969a07cbe49de2e2d40202757a18cd5a2';

abstract class _$HighMessageService
    extends $Notifier<Map<String, Map<HighMessageType, HighMessage>>> {
  Map<String, Map<HighMessageType, HighMessage>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
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
    element.handleValue(ref, created);
  }
}
