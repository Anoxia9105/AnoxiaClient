// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_notification_sender_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(messageNotificationSender)
final messageNotificationSenderProvider = MessageNotificationSenderProvider._();

final class MessageNotificationSenderProvider
    extends
        $FunctionalProvider<
          MessageNotificationSender,
          MessageNotificationSender,
          MessageNotificationSender
        >
    with $Provider<MessageNotificationSender> {
  MessageNotificationSenderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageNotificationSenderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messageNotificationSenderHash();

  @$internal
  @override
  $ProviderElement<MessageNotificationSender> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MessageNotificationSender create(Ref ref) {
    return messageNotificationSender(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessageNotificationSender value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessageNotificationSender>(value),
    );
  }
}

String _$messageNotificationSenderHash() =>
    r'f4efe808774c0683d7c1064833ee89857ed5e9b4';
