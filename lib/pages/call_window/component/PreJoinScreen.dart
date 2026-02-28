import 'package:anoxia/framework/logs/talker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:livekit_client/livekit_client.dart';

class PrejoinScreen extends StatefulWidget {
  final String roomId;
  final VoidCallback onJoin;

  const PrejoinScreen({
    super.key,
    required this.roomId,
    required this.onJoin,
  });

  @override
  State<PrejoinScreen> createState() => _PrejoinScreenState();
}

class _PrejoinScreenState extends State<PrejoinScreen> {
  List<MediaDevice> audioInputs = [];
  List<MediaDevice> audioOutputs = [];
  List<MediaDevice> videoInputs = [];
  MediaDevice? selectedAudioInput;
  MediaDevice? selectedAudioOutput;
  MediaDevice? selectedVideoInput;
  bool isCameraEnabled = false;
  bool isMicEnabled = false;
  double micVolume = 0.0;
  NetworkStatus networkStatus = NetworkStatus.checking;

  @override
  void initState() {
    super.initState();
    _loadDevices();
    _checkNetworkStatus();
  }

  Future<void> _loadDevices() async {
    try {
      final devices = await Hardware.instance.enumerateDevices();
      setState(() {
        audioInputs = devices.where((d) => d.kind == 'audioinput').toList();
        audioOutputs = devices.where((d) => d.kind == 'audiooutput').toList();
        videoInputs = devices.where((d) => d.kind == 'videoinput').toList();
        selectedAudioInput = Hardware.instance.selectedAudioInput;
        selectedAudioOutput = Hardware.instance.selectedAudioOutput;
        selectedVideoInput = Hardware.instance.selectedVideoInput;
      });
    } catch (e) {
      log.error('加载设备失败: $e');
    }
  }

  Future<void> _selectAudioInput(MediaDevice device) async {
    await Hardware.instance.selectAudioInput(device);
    setState(() {
      selectedAudioInput = device;
    });
  }

  Future<void> _selectAudioOutput(MediaDevice device) async {
    await Hardware.instance.selectAudioOutput(device);
    setState(() {
      selectedAudioOutput = device;
    });
  }

  Future<void> _selectVideoInput(MediaDevice device) async {
    setState(() {
      selectedVideoInput = device;
    });
  }

  void _toggleCamera() {
    setState(() {
      isCameraEnabled = !isCameraEnabled;
    });
  }

  void _toggleMic() {
    setState(() {
      isMicEnabled = !isMicEnabled;
    });
  }

  void _checkNetworkStatus() {
    setState(() {
      networkStatus = NetworkStatus.checking;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          networkStatus = NetworkStatus.good;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.shade900,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 24.h),
                        Text(
                          'prejoin_title'.tr(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'prejoin_subtitle'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: 32.h),

                        _buildSectionTitle('prejoin_camera'.tr()),
                        SizedBox(height: 12.h),
                        _buildCameraSection(),
                        SizedBox(height: 24.h),

                        _buildSectionTitle('prejoin_microphone'.tr()),
                        SizedBox(height: 12.h),
                        _buildMicrophoneSection(),
                        SizedBox(height: 24.h),

                        _buildSectionTitle('prejoin_speaker'.tr()),
                        SizedBox(height: 12.h),
                        _buildSpeakerSection(),
                        SizedBox(height: 24.h),

                        _buildSectionTitle('prejoin_network'.tr()),
                        SizedBox(height: 12.h),
                        _buildNetworkSection(),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24.h),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Widget _buildCameraSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<MediaDevice>(
                  value: selectedVideoInput,
                  decoration: InputDecoration(
                    labelText: 'prejoin_select_camera'.tr(),
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                  dropdownColor: Colors.grey.shade800,
                  style: TextStyle(color: Colors.white),
                  items: videoInputs.map((device) {
                    return DropdownMenuItem<MediaDevice>(
                      value: device,
                      child: Text(
                        device.label.isEmpty ? 'Camera ${device.deviceId}' : device.label,
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (device) {
                    if (device != null) {
                      _selectVideoInput(device);
                    }
                  },
                ),
              ),
              SizedBox(width: 12.w),
              IconButton(
                icon: Icon(
                  isCameraEnabled ? Icons.videocam : Icons.videocam_off,
                  color: isCameraEnabled ? Colors.green : Colors.white54,
                ),
                onPressed: _toggleCamera,
              ),
            ],
          ),
          if (isCameraEnabled) ...[
            SizedBox(height: 16.h),
            Container(
              height: 200.h,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'prejoin_camera_preview'.tr(),
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMicrophoneSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<MediaDevice>(
                  value: selectedAudioInput,
                  decoration: InputDecoration(
                    labelText: 'prejoin_select_microphone'.tr(),
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                  dropdownColor: Colors.grey.shade800,
                  style: TextStyle(color: Colors.white),
                  items: audioInputs.map((device) {
                    return DropdownMenuItem<MediaDevice>(
                      value: device,
                      child: Text(
                        device.label.isEmpty ? 'Microphone ${device.deviceId}' : device.label,
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (device) {
                    if (device != null) {
                      _selectAudioInput(device);
                    }
                  },
                ),
              ),
              SizedBox(width: 12.w),
              IconButton(
                icon: Icon(
                  isMicEnabled ? Icons.mic : Icons.mic_off,
                  color: isMicEnabled ? Colors.green : Colors.white54,
                ),
                onPressed: _toggleMic,
              ),
            ],
          ),
          if (isMicEnabled) ...[
            SizedBox(height: 16.h),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'prejoin_mic_volume'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(Icons.volume_up, color: Colors.white54, size: 16),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: micVolume,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation(
                          Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpeakerSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<MediaDevice>(
        value: selectedAudioOutput,
        decoration: InputDecoration(
          labelText: 'prejoin_select_speaker'.tr(),
          labelStyle: TextStyle(color: Colors.white70),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
          ),
        ),
        dropdownColor: Colors.grey.shade800,
        style: TextStyle(color: Colors.white),
        items: audioOutputs.map((device) {
          return DropdownMenuItem<MediaDevice>(
            value: device,
            child: Text(
              device.label.isEmpty ? 'Speaker ${device.deviceId}' : device.label,
              style: TextStyle(color: Colors.white),
            ),
          );
        }).toList(),
        onChanged: (device) {
          if (device != null) {
            _selectAudioOutput(device);
          }
        },
      ),
    );
  }

  Widget _buildNetworkSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _getNetworkIcon(networkStatus),
            color: _getNetworkColor(networkStatus),
            size: 24,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getNetworkText(networkStatus),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _getNetworkColor(networkStatus),
                  ),
                ),
                if (networkStatus == NetworkStatus.checking)
                  Text(
                    'prejoin_checking_network'.tr(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: _checkNetworkStatus,
            child: Text('prejoin_recheck'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white24),
              padding: EdgeInsets.symmetric(vertical: 16.h),
            ),
            child: Text(
              'prejoin_cancel'.tr(),
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: FilledButton(
            onPressed: widget.onJoin,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(vertical: 16.h),
            ),
            child: Text(
              'prejoin_join'.tr(),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getNetworkIcon(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.good:
        return Icons.wifi;
      case NetworkStatus.poor:
        return Icons.signal_wifi_bad;
      case NetworkStatus.checking:
        return Icons.refresh;
    }
  }

  Color _getNetworkColor(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.good:
        return Colors.green;
      case NetworkStatus.poor:
        return Colors.orange;
      case NetworkStatus.checking:
        return Colors.blue;
    }
  }

  String _getNetworkText(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.good:
        return 'prejoin_network_good'.tr();
      case NetworkStatus.poor:
        return 'prejoin_network_poor'.tr();
      case NetworkStatus.checking:
        return 'prejoin_checking'.tr();
    }
  }
}

enum NetworkStatus {
  good,
  poor,
  checking,
}
