// 地图瓦片图源配置
//
// 定义地图组件使用的瓦片图源信息，包括 URL 模板、归属信息和子域名等。
// 支持 OpenStreetMap、CARTO Voyager 和 CARTO Light 三种图源，
// 并根据用户语言偏好自动选择默认图源。
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// 地图瓦片图源
///
/// 封装地图瓦片图源的配置信息，包括瓦片 URL 模板、子域名列表和版权归属。
/// 提供了三种内置图源选项，并支持根据上下文语言环境自动选择默认图源。
class MapTileSource {
  const MapTileSource({
    required this.id,
    required this.nameKey,
    required this.urlTemplate,
    required this.attribution,
    this.subdomains = const [],
  });

  /// 图源唯一标识符
  final String id;
  /// 图源名称的国际化 key
  final String nameKey;
  /// 瓦片 URL 模板，支持 {z}/{x}/{y} 占位符
  final String urlTemplate;
  /// 图源版权归属信息
  final String attribution;
  /// 子域名列表，用于 CDN 负载均衡
  final List<String> subdomains;

  /// 获取本地化后的图源名称
  String get localizedName => nameKey.tr();

  /// OpenStreetMap 标准瓦片图源
  static const osm = MapTileSource(
    id: 'osm',
    nameKey: 'map_source_osm',
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: '© OpenStreetMap contributors',
  );

  /// CARTO Voyager 风格瓦片图源
  static const cartoVoyager = MapTileSource(
    id: 'carto_voyager',
    nameKey: 'map_source_carto',
    urlTemplate:
        'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
    attribution: '© OpenStreetMap contributors © CARTO',
    subdomains: ['a', 'b', 'c', 'd'],
  );

  /// CARTO Light 浅色风格瓦片图源
  static const cartoLight = MapTileSource(
    id: 'carto_light',
    nameKey: 'map_source_carto_light',
    urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
    attribution: '© OpenStreetMap contributors © CARTO',
    subdomains: ['a', 'b', 'c', 'd'],
  );

  /// 所有可用图源列表
  static const all = [osm, cartoVoyager, cartoLight];

  /// 根据上下文语言环境选择首选图源
  ///
  /// 中文环境使用 OSM，日语环境使用 CARTO Light，其他环境使用 CARTO Voyager。
  static MapTileSource preferredFor(BuildContext context) {
    return switch (context.locale.languageCode) {
      'zh' => osm,
      'ja' => cartoLight,
      _ => cartoVoyager,
    };
  }
}
