/// Decides whether an incoming chat message should create a local notification.
///
/// On the web, selecting a room does not mean the user can still see it: the
/// browser tab may be hidden. Desktop windows may be minimized or unfocused.
/// Native mobile notifications retain the existing push policy.
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
      isCurrentRoom && (isAppForeground || (isMobile && !isWeb));

  return !isSelfMessage &&
      !isCallSystemMessage &&
      !isActivelyViewingCurrentRoom &&
      !isDoNotDisturb &&
      !(isMobile && isAppForeground);
}
