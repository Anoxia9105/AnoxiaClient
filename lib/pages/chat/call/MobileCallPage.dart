import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'CallRoomPage.dart';

class MobileCallPage extends ConsumerStatefulWidget {
  final String roomId;
  final String title;

  const MobileCallPage({super.key, required this.roomId, required this.title});

  @override
  ConsumerState<MobileCallPage> createState() => _MobileCallPageState();
}

class _MobileCallPageState extends ConsumerState<MobileCallPage> {
  bool _ending = false;

  @override
  void initState() {
    super.initState();
    ref
        .read(mobileCallSessionControllerProvider.notifier)
        .start(roomId: widget.roomId, title: widget.title);
    ref.read(roomTokenProvider(widget.roomId));
  }

  void _minimizeAndBack() {
    if (!DeviceUtil.isRealMobile()) return;
    ref.read(mobileCallSessionControllerProvider.notifier).minimize();
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _endAndBack() async {
    setState(() => _ending = true);
    final tokenAsync = ref.read(roomTokenProvider(widget.roomId));
    final token = tokenAsync.value;

    if (token != null && token.isNotEmpty) {
      await ref.read(roomControllerProvider(token).notifier).leave();
    }

    ref.read(mobileCallSessionControllerProvider.notifier).end();
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final tokenAsync = ref.watch(roomTokenProvider(widget.roomId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _minimizeAndBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title.isEmpty ? 'appbar_start_meeting'.tr() : widget.title),
          actions: [
            IconButton(
              tooltip: '最小化通话',
              onPressed: _minimizeAndBack,
              icon: const Icon(Icons.picture_in_picture_alt_outlined),
            ),
            IconButton(
              tooltip: '结束通话',
              onPressed: _ending ? null : _endAndBack,
              icon: const Icon(Icons.call_end, color: Colors.redAccent),
            ),
          ],
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
                  onPressed: () => ref.invalidate(roomTokenProvider(widget.roomId)),
                  child: Text('call_window_retry'.tr()),
                ),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
