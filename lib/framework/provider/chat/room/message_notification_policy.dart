/// Decides whether an incoming chat message should create a local notification.
///
/// On the web, selecting a room does not mean the user can still see it: the
/// browser tab may be hidden. Other platforms intentionally keep their existing
/// active-room behavior.
bool shouldShowLocalMessageNotification({
  required bool isSelfMessage,
  required bool isCallSystemMessage,
  required bool isCurrentRoom,
  required bool isDoNotDisturb,
  required bool isMobile,
  required bool isAppForeground,
  required bool isWeb,
}) {
  final isActivelyViewingCurrentRoom =
      isCurrentRoom && (!isWeb || isAppForeground);

  return !isSelfMessage &&
      !isCallSystemMessage &&
      !isActivelyViewingCurrentRoom &&
      !isDoNotDisturb &&
      !(isMobile && isAppForeground);
}
