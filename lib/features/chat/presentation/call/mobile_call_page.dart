import 'package:anoxia/common/constants/StorageKeys.dart';
import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/utils/SPUtil.dart';
import 'package:anoxia/features/chat/presentation/call/call_room_page.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class MobileCallPage extends ConsumerStatefulWidget {
  final String roomId;
  final String title;

  const MobileCallPage({
    super.key,
    required this.roomId,
    required this.title,
  });

  @override
  ConsumerState<MobileCallPage> createState() =>
      _MobileCallPageState();
}

class _MobileCallPageState
    extends ConsumerState<MobileCallPage> {

  @override
  void initState() {
    super.initState();

    _checkBluetoothPermissions();
  }

  Future<void> _checkBluetoothPermissions() async {
    if (!DeviceUtil.isAndroid()) return;

    final requested =
        SPUtil.instance.getBool(
          StorageKeys
              .kBluetoothPermissionRequestedKey,
        ) ??
            false;

    if (requested) return;

    bool hasPermanentlyDenied = false;

    var status =
    await Permission.bluetooth.request();

    if (status.isPermanentlyDenied) {
      log.warning(
        'Bluetooth Permission disabled',
      );

      hasPermanentlyDenied = true;
    }

    status =
    await Permission.bluetoothConnect
        .request();

    if (status.isPermanentlyDenied) {
      log.warning(
        'Bluetooth Connect Permission disabled',
      );

      hasPermanentlyDenied = true;
    }

    await SPUtil.instance.setBool(
      StorageKeys
          .kBluetoothPermissionRequestedKey,
      true,
    );

    if (hasPermanentlyDenied) {
      await openAppSettings();
    }
  }

  @override
  Widget build(
      BuildContext context,
      ) {

    final session = ref.watch(
      mobileCallSessionControllerProvider,
    );

    final token = session?.token;

    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,

        elevation: 0,

        centerTitle: true,

        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        leading: IconButton(
          icon: const Icon(
            Icons.fullscreen_exit,
          ),

          /// 最小化
          onPressed: () {
            ref
                .read(
              mobileCallSessionControllerProvider
                  .notifier,
            )
                .minimize();
          },
        ),

        actions: [

          /// 挂断
          IconButton(
            icon: const Icon(
              Icons.call_end,
              color: Colors.red,
            ),

            onPressed: () {

              /// 结束会话
              ref
                  .read(
                mobileCallSessionControllerProvider
                    .notifier,
              )
                  .end();
            },
          ),
        ],
      ),

      body: _buildBody(token),
    );
  }

  Widget _buildBody(String? token) {

    /// 已存在Token
    if (token != null &&
        token.isNotEmpty) {

      return CallRoomPage(
        token: token,
      );
    }

    /// 首次拉取Token
    final tokenAsync = ref.watch(
      roomTokenProvider(widget.roomId),
    );

    return tokenAsync.when(
      data: (newToken) {

        WidgetsBinding.instance
            .addPostFrameCallback((_) {

          if (!mounted) return;

          ref
              .read(
            mobileCallSessionControllerProvider
                .notifier,
          )
              .updateToken(newToken);
        });

        return CallRoomPage(
          token: newToken,
        );
      },

      error: (err, stack) {

        return Center(
          child: Column(
            mainAxisSize:
            MainAxisSize.min,

            children: [

              Text(
                'call_window_room_creation_failed'
                    .tr(),
              ),

              const SizedBox(
                height: 12,
              ),

              FilledButton(
                onPressed: () {

                  ref.invalidate(
                    roomTokenProvider(
                      widget.roomId,
                    ),
                  );
                },

                child: Text(
                  'call_window_retry'
                      .tr(),
                ),
              ),
            ],
          ),
        );
      },

      loading: () {

        return const Center(
          child:
          CircularProgressIndicator(
            color: Colors.white,
          ),
        );
      },
    );
  }
}