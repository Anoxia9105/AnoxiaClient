import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

class MapTileSource {
  const MapTileSource({
    required this.id,
    required this.nameKey,
    required this.urlTemplate,
    required this.attribution,
    this.subdomains = const [],
  });

  final String id;
  final String nameKey;
  final String urlTemplate;
  final String attribution;
  final List<String> subdomains;

  String get localizedName => nameKey.tr();

  static const osm = MapTileSource(
    id: 'osm',
    nameKey: 'map_source_osm',
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: '© OpenStreetMap contributors',
  );

  static const cartoVoyager = MapTileSource(
    id: 'carto_voyager',
    nameKey: 'map_source_carto',
    urlTemplate:
        'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
    attribution: '© OpenStreetMap contributors © CARTO',
    subdomains: ['a', 'b', 'c', 'd'],
  );

  static const cartoLight = MapTileSource(
    id: 'carto_light',
    nameKey: 'map_source_carto_light',
    urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
    attribution: '© OpenStreetMap contributors © CARTO',
    subdomains: ['a', 'b', 'c', 'd'],
  );

  static const all = [osm, cartoVoyager, cartoLight];

  static MapTileSource preferredFor(BuildContext context) {
    return switch (context.locale.languageCode) {
      'zh' => osm,
      'ja' => cartoLight,
      _ => cartoVoyager,
    };
  }
}
