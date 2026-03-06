import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:livekit_client/livekit_client.dart';

/// 预加入屏幕 - 显示设备列表、摄像头预览和网络状态
class PreJoinScreen extends ConsumerStatefulWidget {
  final String token;
  final VoidCallback? onJoined;
  final VoidCallback? onBack;

  const PreJoinScreen({
    super.key,
    required this.token,
    this.onJoined,
    this.onBack,
  });

  @override
  ConsumerState<PreJoinScreen> createState() => _PreJoinScreenState();
}

class _PreJoinScreenState extends ConsumerState<PreJoinScreen> {
  late String _selectedCameraId;
  late String _selectedMicrophoneId;
  late String _selectedSpeakerId;

  bool _isCameraEnabled = true;
  bool _isMicrophoneEnabled = true;
  bool _isSpeakerEnabled = true;

  List<MediaDevice> _availableCameras = [];
  List<MediaDevice> _availableMicrophones = [];
  List<MediaDevice> _availableSpeakers = [];

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    try {
      final devices = await Hardware.instance.enumerateDevices();

      setState(() {
        _availableCameras = devices
            .where((d) => d.kind == 'videoinput')
            .toList();
        _availableMicrophones = devices
            .where((d) => d.kind == 'audioinput')
            .toList();
        _availableSpeakers = devices
            .where((d) => d.kind == 'audiooutput')
            .toList();

        // 设置默认选择
        if (_availableCameras.isNotEmpty) {
          _selectedCameraId = _availableCameras.first.deviceId;
        }
        if (_availableMicrophones.isNotEmpty) {
          _selectedMicrophoneId = _availableMicrophones.first.deviceId;
        }
        if (_availableSpeakers.isNotEmpty) {
          _selectedSpeakerId = _availableSpeakers.first.deviceId;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('call_get_device_failed'.tr(args: [e.toString()]))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return WillPopScope(
      onWillPop: () async {
        widget.onBack?.call();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('call_join_room'.tr()),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.onBack ?? () => Navigator.pop(context),
          ),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 摄像头预览
                _buildCameraPreview(),
                SizedBox(height: 24.h),

                // 设备选择卡片
                _buildDeviceSelectionCard(colorScheme),
                SizedBox(height: 24.h),

                // 网络状态卡片
                _buildNetworkStatusCard(colorScheme),
                SizedBox(height: 32.h),

                // 加入按钮
                _buildJoinButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建摄像头预览
  Widget _buildCameraPreview() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 240.h,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.videocam,
                color: Colors.white54,
                size: 64.w,
              ),
              SizedBox(height: 16.h),
              Text(
                'call_camera_preview'.tr(),
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建设备选择卡片
  Widget _buildDeviceSelectionCard(ColorScheme colorScheme) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'call_device_settings'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 20.h),

            // 摄像头选择
            _buildDeviceSelector(
              label: 'call_camera'.tr(),
              devices: _availableCameras,
              selectedId: _selectedCameraId,
              onChanged: (id) {
                if (id != null) {
                  setState(() => _selectedCameraId = id);
                  // 注意: 实际设备切换需要在房间连接时进行
                }
              },
              isEnabled: _isCameraEnabled,
              onEnabledChanged: (enabled) {
                setState(() => _isCameraEnabled = enabled);
              },
            ),
            SizedBox(height: 16.h),

            // 麦克风选择
            _buildDeviceSelector(
              label: 'call_microphone'.tr(),
              devices: _availableMicrophones,
              selectedId: _selectedMicrophoneId,
              onChanged: (id) {
                if (id != null) {
                  setState(() => _selectedMicrophoneId = id);
                  // 注意: 实际设备切换需要在房间连接时进行
                }
              },
              isEnabled: _isMicrophoneEnabled,
              onEnabledChanged: (enabled) {
                setState(() => _isMicrophoneEnabled = enabled);
              },
            ),
            SizedBox(height: 16.h),

            // 扬声器选择
            _buildDeviceSelector(
              label: 'call_speaker'.tr(),
              devices: _availableSpeakers,
              selectedId: _selectedSpeakerId,
              onChanged: (id) {
                if (id != null) {
                  setState(() => _selectedSpeakerId = id);
                  // 注意: 实际设备切换需要在房间连接时进行
                }
              },
              isEnabled: _isSpeakerEnabled,
              onEnabledChanged: (enabled) {
                setState(() => _isSpeakerEnabled = enabled);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 构建单个设备选择器
  Widget _buildDeviceSelector({
    required String label,
    required List<MediaDevice> devices,
    required String selectedId,
    required Function(String?) onChanged,
    required bool isEnabled,
    required Function(bool) onEnabledChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              SizedBox(height: 8.h),
              DropdownButton<String>(
                isExpanded: true,
                value: devices.any((d) => d.deviceId == selectedId)
                    ? selectedId
                    : (devices.isNotEmpty ? devices.first.deviceId : null),
                items: devices
                    .map((device) => DropdownMenuItem(
                          value: device.deviceId,
                          child: Text(device.label),
                        ))
                    .toList(),
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        SizedBox(width: 16.w),
        Column(
          children: [
            SizedBox(height: 16.h),
            Switch(
              value: isEnabled,
              onChanged: onEnabledChanged,
            ),
          ],
        ),
      ],
    );
  }

  /// 构建网络状态卡片
  Widget _buildNetworkStatusCard(ColorScheme colorScheme) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'call_network_status'.tr(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'call_network_good'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建加入按钮
  Widget _buildJoinButton() {
    return ElevatedButton(
      onPressed: _joinRoom,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text('call_join_room'.tr()),
    );
  }

  /// 加入房间
  Future<void> _joinRoom() async {
    try {
      // 这里可以添加加入房间的逻辑
      // 通常会调用 room_controller 来实际加入房间
      widget.onJoined?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('call_join_failed'.tr(args: [e.toString()]))),
      );
    }
  }
}
