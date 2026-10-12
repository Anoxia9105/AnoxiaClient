/// 将 SDK 的终止原因转换为用户能采取行动的提示，避免所有断线都显示网络故障。
String callDisconnectionMessageKey(String? reason) => switch (reason) {
  'duplicateIdentity' => 'call_connection_other_device',
  'roomDeleted' || 'roomClosed' => 'call_room_ended_hint',
  'serverShutdown' || 'migration' => 'call_server_restarting_hint',
  'reconnectAttemptsExceeded' ||
  'connectionTimeout' => 'call_reconnect_exhausted',
  'mediaFailure' => 'call_media_connection_failed',
  _ => 'call_connection_lost',
};
