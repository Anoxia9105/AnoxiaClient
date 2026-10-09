import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/framework/domain/room_state.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';

import 'call_media_settings_dialog.dart';
import 'call_diagnostics_dialog.dart';
import 'window_screen_select_dialog.dart';

enum _Action { settings, share, replace, diagnostics }

/// 桌面与移动布局共用通话设置/共享入口。
class CallMediaMenu extends ConsumerWidget {
  const CallMediaMenu({super.key, required this.state});
  final RoomState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharing = state.screenSharing;
    return PopupMenuButton<_Action>(
      tooltip: 'call_media_settings'.tr(),
      icon: const Icon(Icons.tune_rounded),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _Action.settings,
          child: Text('call_media_settings'.tr()),
        ),
        if (!lkPlatformIsWebMobile())
          PopupMenuItem(
            value: _Action.share,
            child: Text((sharing ? 'call_share_stop' : 'call_share').tr()),
          ),
        if (sharing)
          PopupMenuItem(
            value: _Action.replace,
            child: Text('call_share_replace'.tr()),
          ),
        PopupMenuItem(
          value: _Action.diagnostics,
          child: Text('call_diagnostics'.tr()),
        ),
      ],
      onSelected: (action) async {
        final notifier = ref.read(roomControllerProvider(state.token).notifier);
        if (action == _Action.settings) {
          await showCallMediaSettings(
            context,
            state,
            notifier.applyMediaPreferences,
          );
        } else if (action == _Action.diagnostics) {
          await showCallDiagnostics(
            context,
            state.room,
            notifier.connectionDuration,
          );
        } else if (action == _Action.share && sharing) {
          await notifier.stopScreenShare();
        } else {
          String? sourceId;
          if (DeviceUtil.isRealDesktop()) {
            sourceId = await showDesktopScreenSourcePicker(context);
            if (sourceId == null) return;
          }
          if (!context.mounted) return;
          if (action == _Action.replace) {
            await notifier.replaceScreenShare(sourceId: sourceId);
          } else {
            await notifier.startScreenShare(sourceId: sourceId);
          }
        }
      },
    );
  }
}
