// 位置消息详情页面，在地图上展示收到的位置消息。
//
// 使用 flutter_map 渲染地图，支持切换地图源，显示位置标题、地址和坐标信息。
import 'package:anoxia/features/chat/presentation/widgets/location/map_tile_source.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// 位置消息详情页面。
///
/// 接收 [location] 参数，在地图上标注位置点并展示位置详细信息。
class LocationMessageDetailPage extends StatefulWidget {
  const LocationMessageDetailPage({super.key, required this.location});

  /// 位置信息载荷。
  final LocationPayload location;

  @override
  State<LocationMessageDetailPage> createState() =>
      _LocationMessageDetailPageState();
}

class _LocationMessageDetailPageState extends State<LocationMessageDetailPage> {
  final MapController _mapController = MapController();

  /// 当前使用的地图源。
  MapTileSource? _source;

  /// 上次使用的语言代码，用于检测语言切换。
  String? _languageCode;

  /// 获取位置的经纬度坐标点。
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

  /// 循环切换地图源。
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
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedLocation01,
                      size: 48,
                      color: Colors.redAccent,
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
                  child: const HugeIcon(icon: HugeIcons.strokeRoundedMapPinpoint01),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: null,
                  tooltip: 'map_source'.tr(args: [source.localizedName]),
                  onPressed: _cycleSource,
                  child: const HugeIcon(icon: HugeIcons.strokeRoundedLayers01),
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