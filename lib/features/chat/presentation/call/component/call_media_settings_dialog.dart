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
    barrierDismissible: false,
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      title: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.tune_rounded,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'call_media_settings'.tr(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'call_media_settings_subtitle'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _section(
                Icons.videocam_outlined,
                'call_camera',
                'call_camera_quality_hint',
                DropdownButtonFormField<CameraQuality>(
                  initialValue: _camera,
                  isExpanded: true,
                  decoration: _decoration('call_camera_quality'),
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
              ),
              const SizedBox(height: 12),
              _section(
                Icons.screen_share_outlined,
                'call_share',
                'call_share_quality_hint',
                Column(
                  children: [
                    DropdownButtonFormField<ScreenShareQuality>(
                      initialValue: _screen,
                      isExpanded: true,
                      decoration: _decoration('call_share_quality'),
                      items: ScreenShareQuality.values
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(
                                'call_share_quality_${value.name}'.tr(),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _screen = value!),
                    ),
                    if (DeviceUtil.isWeb)
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text('call_share_audio'.tr()),
                        subtitle: Text('call_share_audio_hint'.tr()),
                        value: _shareAudio,
                        onChanged: _saving
                            ? null
                            : (value) => setState(() => _shareAudio = value),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                collapsedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                leading: const Icon(Icons.settings_ethernet_rounded),
                title: Text('call_media_advanced'.tr()),
                subtitle: Text(
                  'call_media_advanced_hint'.tr(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
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
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'call_media_apply_hint'.tr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
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

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label.tr(),
    filled: true,
    fillColor: Theme.of(context).colorScheme.surface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
  );

  Widget _section(IconData icon, String title, String hint, Widget child) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title.tr(), style: theme.textTheme.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            hint.tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _codecSelector(
    String label,
    VideoCodecPreference selected,
    void Function(VideoCodecPreference) update,
  ) => DropdownButtonFormField<VideoCodecPreference>(
    initialValue: selected,
    isExpanded: true,
    decoration: _decoration(label),
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
