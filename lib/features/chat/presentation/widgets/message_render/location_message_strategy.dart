// 位置消息渲染策略
//
// 实现位置类型消息的渲染逻辑，将位置信息渲染为包含地图预览和坐标信息的卡片。
// 点击可跳转到详细地图页面。
import 'package:anoxia/features/chat/presentation/pages/location_message_detail_page.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/features/chat/presentation/widgets/location/map_tile_source.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'base/message_render_strategy.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 位置消息渲染策略
///
/// 将 [LocationPayload] 数据渲染为内嵌地图缩略图的消息卡片，
/// 显示坐标信息和位置标题，点击可查看详细地图。
class LocationMessageStrategy extends MessageRenderStrategy {
  @override
  Widget buildContent(
    BuildContext context,
    ChatMessage message,
    Color textColor,
  ) {
    final location = message.payload?.location;
    if (location == null || !location.hasCoordinate) {
      final fallback =
          (message.payload?.content ?? message.content).trim();
      if (fallback.isNotEmpty && !_isPlaceholder(fallback)) {
        return Text(fallback, style: TextStyle(color: textColor, fontSize: 15));
      }
      return Text(
        'reply_placeholder_location'.tr(),
        style: TextStyle(color: textColor, fontSize: 15),
      );
    }
    return _LocationMessage(location: location);
  }

  static bool _isPlaceholder(String text) {
    final lower = text.trim().toLowerCase();
    return const {
      '[location]',
      '[位置]',
      '[empty]',
    }.contains(lower);
  }
}

class _LocationMessage extends StatelessWidget {
  const _LocationMessage({required this.location});
  final LocationPayload location;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final point = LatLng(location.latitude!, location.longitude!);
    final source = MapTileSource.preferredFor(context);
    final title = location.displayTitle.trim().isEmpty
        ? 'location_selected_point'.tr()
        : location.displayTitle;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(RadiusToken.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => LocationMessageDetailPage(location: location),
          ),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320, minWidth: 240),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 145,
                child: Stack(
                  children: [
                    IgnorePointer(
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: point,
                          initialZoom: 14,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: source.urlTemplate,
                            subdomains: source.subdomains,
                            userAgentPackageName: 'cn.anoxia',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: point,
                                width: 38,
                                height: 38,
                                alignment: Alignment.topCenter,
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedLocation01,
                                  size: 36,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 3,
                      bottom: 2,
                      child: Text(
                        source.attribution,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 8,
                          color: colorScheme.onSurfaceVariant,
                          backgroundColor: colorScheme.surface.withValues(
                            alpha: 0.75,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'location_coordinates'.tr(
                        args: [
                          point.latitude.toStringAsFixed(5),
                          point.longitude.toStringAsFixed(5),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
