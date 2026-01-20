import 'package:desktop_multi_window/desktop_multi_window.dart';

class Channel {
  static WindowMethodChannel callChannel = WindowMethodChannel(
    'call_windows_handler',
  );
  static String callChannelMethod="updateSettings";
}
