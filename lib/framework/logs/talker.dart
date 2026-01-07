import 'package:talker_flutter/talker_flutter.dart';

final log = Talker(
  settings: TalkerSettings(
    /// You can enable/disable all talker processes with this field
    enabled: true,
    /// You can enable/disable saving logs data in history
    useHistory: true,
    /// Length of history that saving logs data
    maxHistoryItems: 100,
    /// You can enable/disable console logs
    useConsoleLogs: true,
  ),
  /// Setup your implementation of logger
  logger: TalkerLogger(),
  ///etc...
);