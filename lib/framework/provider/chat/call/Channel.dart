import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/services.dart';

import '../../../../common/utils/DeviceUtil.dart';

class Channel {
  static const String callChannelMethod = 'updateSettings';

  static WindowMethodChannel? _desktopCallChannel;
  static const MethodChannel _mobileCallChannel = MethodChannel(
    'call_windows_handler',
  );

  static dynamic get callChannel {
    if (DeviceUtil.isRealDesktop()) {
      _desktopCallChannel ??= WindowMethodChannel('call_windows_handler');
      return _desktopCallChannel!;
    }
    return _mobileCallChannel;
  }
}
