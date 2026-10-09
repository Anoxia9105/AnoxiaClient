import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/framework/domain/room_state.dart';
import 'package:anoxia/framework/domain/call_media_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Future<void> showCallMediaSettings(
  BuildContext context,
  RoomState state,
  Future<void> Function(CallMediaPreferences) onSave,
) async {
  await showDialog<void>(
    context: context,
    builder: (_) => _CallMediaSettingsDialog(state: state, onSave: onSave),
  );
}

class _CallMediaSettingsDialog extends StatefulWidget {
  const _CallMediaSettingsDialog({required this.state, required this.onSave});
  final RoomState state;
  final Future<void> Function(CallMediaPreferences) onSave;
  @override
  State<_CallMediaSettingsDialog> createState() =>
      _CallMediaSettingsDialogState();
}

class _CallMediaSettingsDialogState extends State<_CallMediaSettingsDialog> {
  late ScreenShareQuality _screen;
  late CameraQuality _camera;
  late VideoCodecPreference _cameraCodec;
  late VideoCodecPreference _screenCodec;
  late bool _shareAudio;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final prefs = widget.state.mediaPreferences;
    _screen = prefs.screenQuality;
    _camera = prefs.cameraQuality;
    _cameraCodec = prefs.cameraCodec;
    _screenCodec = prefs.screenCodec;
    _shareAudio = DeviceUtil.isWeb && prefs.shareAudio;
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: Text('call_media_settings'.tr()),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<CameraQuality>(
                initialValue: _camera,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'call_camera_quality'.tr(),
                ),
                items: CameraQuality.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text('call_camera_quality_${value.name}'.tr()),
                      ),
                    )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _camera = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ScreenShareQuality>(
                initialValue: _screen,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'call_share_quality'.tr(),
                ),
                items: ScreenShareQuality.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text('call_share_quality_${value.name}'.tr()),
                      ),
                    )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _screen = value!),
              ),
              const SizedBox(height: 12),
              if (DeviceUtil.isWeb)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('call_share_audio'.tr()),
                  subtitle: Text('call_share_audio_hint'.tr()),
                  value: _shareAudio,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _shareAudio = value!),
                ),
              Text(
                'call_media_apply_hint'.tr(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('call_media_advanced'.tr()),
                children: [
                  _codecSelector(
                    'call_camera_codec',
                    _cameraCodec,
                    (value) => _cameraCodec = value,
                  ),
                  const SizedBox(height: 12),
                  _codecSelector(
                    'call_share_codec',
                    _screenCodec,
                    (value) => _screenCodec = value,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'call_codec_hint'.tr(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text('cancel'.tr()),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('common_save'.tr()),
        ),
      ],
    ),
  );

  Widget _codecSelector(
    String label,
    VideoCodecPreference selected,
    void Function(VideoCodecPreference) update,
  ) => DropdownButtonFormField<VideoCodecPreference>(
    initialValue: selected,
    isExpanded: true,
    decoration: InputDecoration(labelText: label.tr()),
    items: VideoCodecPreference.values
        .map(
          (value) => DropdownMenuItem(
            value: value,
            enabled:
                value == VideoCodecPreference.automatic ||
                widget.state.supportedVideoCodecs.contains(value.name),
            child: Text(
              value == VideoCodecPreference.automatic
                  ? 'call_codec_auto'.tr()
                  : value.name.toUpperCase(),
            ),
          ),
        )
        .toList(),
    onChanged: _saving ? null : (value) => setState(() => update(value!)),
  );

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(
        CallMediaPreferences(
          screenQuality: _screen,
          cameraQuality: _camera,
          cameraCodec: _cameraCodec,
          screenCodec: _screenCodec,
          shareAudio: _shareAudio,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _error = 'call_media_save_failed'.tr());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
