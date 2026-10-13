import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../common/constants/storage_keys.dart';
import '../../../common/utils/sp_util.dart';

part 'chat_effect_settings_provider.g.dart';

/// 本设备偏好，默认开启；不控制对方或同步到其他设备。
@Riverpod(keepAlive: true)
class ChatEffectsEnabled extends _$ChatEffectsEnabled {
  @override
  bool build() =>
      SPUtil.instance.getBool(StorageKeys.chatEffectsEnabled) ?? true;

  void setEnabled(bool enabled) {
    if (state == enabled) return;
    state = enabled;
    unawaited(SPUtil.instance.setBool(StorageKeys.chatEffectsEnabled, enabled));
  }
}
