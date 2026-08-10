// 位置选取器组件
//
// 桌面端聊天输入框中的位置分享组件，提供地图选点发送位置消息的功能。
// 支持定位当前位置、拖拽选点、切换瓦片图源等操作。
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:anoxia/features/chat/presentation/widgets/location/map_tile_source.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// 位置选取组件
///
/// 基于 [FlutterMap] 实现的位置选取器，用户可以通过拖拽地图或点击
/// 定位按钮来选择一个位置，确认后通过 [onSubmit] 回调发送位置消息。
class LocationBox extends StatefulWidget {
  const LocationBox({super.key, required this.onSubmit, this.onCancel});

  /// 位置提交回调，用户确认选点后触发
  final ValueChanged<LocationPayload> onSubmit;
  /// 取消回调，用户点击关闭时触发
  final VoidCallback? onCancel;

  @override
  State<LocationBox> createState() => _LocationBoxState();
}

class _LocationBoxState extends State<LocationBox> {
  final MapController _mapController = MapController();
  LatLng _selectedPoint = const LatLng(0, 0);
  MapTileSource? _tileSource;
  String? _languageCode;
  String? _statusKey;
  bool _locating = false;
  bool _hasSelection = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageCode = context.locale.languageCode;
    if (_languageCode != languageCode) {
      _languageCode = languageCode;
      _tileSource = MapTileSource.preferredFor(context);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _locateUser());
  }

  Future<void> _locateUser() async {
    if (_locating || !mounted) return;
    setState(() {
      _locating = true;
      _statusKey = null;
    });

    try {
      final granted = await _ensureLocationPermission();
      if (!mounted) return;
      if (!granted) {
        setState(() => _statusKey = 'location_permission_denied');
        return;
      }

      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) setState(() => _statusKey = 'location_service_disabled');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      if (!mounted) return;
      final point = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedPoint = point;
        _hasSelection = true;
        _statusKey = null;
      });
      _mapController.move(point, 16);
    } catch (_) {
      if (mounted) setState(() => _statusKey = 'location_failed');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<bool> _ensureLocationPermission() async {
    // Browsers request permission as part of getCurrentPosition. Some browsers
    // do not implement the Permissions API, so pre-checking would reject a
    // request that can still succeed.
    if (kIsWeb) return true;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      return true;
    }
    if (permission != LocationPermission.deniedForever || !mounted) {
      return false;
    }

    final openSettings = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'permission_required_title'.tr(
            args: ['location_permission_name'.tr()],
          ),
        ),
        content: Text(
          'permission_settings_required'.tr(
            args: ['location_permission_name'.tr()],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('dialog_cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('permission_go_to_settings'.tr()),
          ),
        ],
      ),
    );
    if (openSettings == true) await Geolocator.openAppSettings();
    return false;
  }

  void _cycleTileSource() {
    final current = _tileSource ?? MapTileSource.preferredFor(context);
    final index = MapTileSource.all.indexWhere((item) => item.id == current.id);
    setState(() {
      _tileSource = MapTileSource.all[(index + 1) % MapTileSource.all.length];
    });
  }

  void _submit() {
    if (!_hasSelection) return;
    final latitude = _selectedPoint.latitude;
    final longitude = _selectedPoint.longitude;
    widget.onSubmit(
      LocationPayload(
        latitude: latitude,
        longitude: longitude,
        title: 'location_selected_point'.tr(),
        address:
            '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final source = _tileSource ?? MapTileSource.preferredFor(context);

    return Material(
      color: colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            _Header(onClose: widget.onCancel),
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _selectedPoint,
                      initialZoom: 2,
                      minZoom: 2,
                      maxZoom: 19,
                      onPositionChanged: (camera, hasGesture) {
                        if (hasGesture && mounted) {
                          setState(() {
                            _selectedPoint = camera.center;
                            _hasSelection = true;
                          });
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        key: ValueKey(source.id),
                        urlTemplate: source.urlTemplate,
                        subdomains: source.subdomains,
                        userAgentPackageName: 'cn.anoxia',
                      ),
                    ],
                  ),
                  const IgnorePointer(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 42),
                        child: Icon(
                          Icons.location_pin,
                          size: 48,
                          color: Colors.redAccent,
                          shadows: [
                            Shadow(blurRadius: 6, color: Colors.black38),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: _HintCard(
                        statusKey: _locating ? 'location_locating' : _statusKey,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Column(
                      children: [
                        FloatingActionButton.small(
                          heroTag: null,
                          tooltip: 'location_current_position'.tr(),
                          onPressed: _locating ? null : _locateUser,
                          child: _locating
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: null,
                          tooltip: 'map_source'.tr(
                            args: [source.localizedName],
                          ),
                          onPressed: _cycleTileSource,
                          child: const Icon(Icons.layers_outlined),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: _SelectionCard(
                      point: _selectedPoint,
                      source: source,
                      onSend: _hasSelection ? _submit : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.onClose});
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
          Expanded(
            child: Text(
              'location_picker_title'.tr(),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({this.statusKey});
  final String? statusKey;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text((statusKey ?? 'location_drag_hint').tr()),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.point,
    required this.source,
    this.onSend,
  });

  final LatLng point;
  final MapTileSource source;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'location_selected_point'.tr(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'location_coordinates'.tr(
                      args: [
                        point.latitude.toStringAsFixed(6),
                        point.longitude.toStringAsFixed(6),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    'map_source'.tr(args: [source.localizedName]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall,
                  ),
                  Text(
                    source.attribution,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: onSend,
              icon: const Icon(Icons.send_outlined),
              label: Text('toolbar_send'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
