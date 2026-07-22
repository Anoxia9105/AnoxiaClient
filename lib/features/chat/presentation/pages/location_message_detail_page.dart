import 'package:anoxia/features/chat/presentation/widgets/location/map_tile_source.dart';
import 'package:anoxia/framework/protocol/message/MessagePayload.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationMessageDetailPage extends StatefulWidget {
  const LocationMessageDetailPage({super.key, required this.location});

  final LocationPayload location;

  @override
  State<LocationMessageDetailPage> createState() =>
      _LocationMessageDetailPageState();
}

class _LocationMessageDetailPageState extends State<LocationMessageDetailPage> {
  final MapController _mapController = MapController();
  MapTileSource? _source;
  String? _languageCode;

  LatLng get _point =>
      LatLng(widget.location.latitude ?? 0, widget.location.longitude ?? 0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageCode = context.locale.languageCode;
    if (_languageCode != languageCode) {
      _languageCode = languageCode;
      _source = MapTileSource.preferredFor(context);
    }
  }

  void _cycleSource() {
    final current = _source ?? MapTileSource.preferredFor(context);
    final index = MapTileSource.all.indexWhere((item) => item.id == current.id);
    setState(() {
      _source = MapTileSource.all[(index + 1) % MapTileSource.all.length];
    });
  }

  @override
  Widget build(BuildContext context) {
    final source = _source ?? MapTileSource.preferredFor(context);
    final theme = Theme.of(context);
    final title = widget.location.displayTitle.trim().isEmpty
        ? 'location_selected_point'.tr()
        : widget.location.displayTitle;

    return Scaffold(
      appBar: AppBar(title: Text('location_detail_title'.tr())),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _point,
              initialZoom: 16,
              minZoom: 2,
              maxZoom: 19,
            ),
            children: [
              TileLayer(
                key: ValueKey(source.id),
                urlTemplate: source.urlTemplate,
                subdomains: source.subdomains,
                userAgentPackageName: 'cn.anoxia',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _point,
                    width: 52,
                    height: 52,
                    alignment: Alignment.topCenter,
                    child: const Icon(
                      Icons.location_pin,
                      size: 48,
                      color: Colors.redAccent,
                      shadows: [Shadow(blurRadius: 6, color: Colors.black38)],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: null,
                  tooltip: 'location_selected_point'.tr(),
                  onPressed: () => _mapController.move(_point, 16),
                  child: const Icon(Icons.location_searching),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: null,
                  tooltip: 'map_source'.tr(args: [source.localizedName]),
                  onPressed: _cycleSource,
                  child: const Icon(Icons.layers_outlined),
                ),
              ],
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SafeArea(
              top: false,
              child: Card(
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (widget.location.displayAddress.isNotEmpty &&
                          widget.location.displayAddress != title) ...[
                        const SizedBox(height: 4),
                        Text(widget.location.displayAddress),
                      ],
                      const SizedBox(height: 5),
                      Text(
                        'location_coordinates'.tr(
                          args: [
                            _point.latitude.toStringAsFixed(6),
                            _point.longitude.toStringAsFixed(6),
                          ],
                        ),
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        'map_source'.tr(args: [source.localizedName]),
                        style: theme.textTheme.labelSmall,
                      ),
                      Text(
                        source.attribution,
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
