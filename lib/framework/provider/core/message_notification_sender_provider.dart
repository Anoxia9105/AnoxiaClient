import 'package:anoxia/framework/core/notification_helper.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'message_notification_sender_provider.g.dart';

typedef MessageNotificationSender =
    Future<void> Function({
      required int id,
      required String title,
      required String body,
      String? payload,
      String? avatarUrl,
    });

@Riverpod(keepAlive: true)
MessageNotificationSender messageNotificationSender(Ref ref) =>
    NotificationHelper().show;
