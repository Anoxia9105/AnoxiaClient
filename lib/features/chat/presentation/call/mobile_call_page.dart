import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'call_room_page.dart';

class MobileCallPage extends ConsumerStatefulWidget {
  final String roomId;
  final String title;

  const MobileCallPage({super.key, required this.roomId, required this.title});

  @override
  ConsumerState<MobileCallPage> createState() => _MobileCallPageState();
}

class _MobileCallPageState extends ConsumerState<MobileCallPage> {
  @override
  void initState() {
    super.initState();
    ref.read(roomTokenProvider(widget.roomId));
  }

  @override
  Widget build(BuildContext context) {
    final tokenAsync = ref.watch(roomTokenProvider(widget.roomId));

    return Scaffold(
      backgroundColor: DeviceUtil.isRealDesktop()
          ? Colors.transparent
          : Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.title.isEmpty ? 'appbar_start_meeting'.tr() : widget.title,
        ),
      ),
      body: tokenAsync.when(
        data: (token) => CallRoomPage(token: token),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('call_window_room_creation_failed'.tr()),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(roomTokenProvider(widget.roomId)),
                child: Text('call_window_retry'.tr()),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
