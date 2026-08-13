import 'package:flutter/material.dart';

import '../../../framework/domain/app_background.dart';
import '../cached_network_image_view.dart';
import 'background_video_view.dart';

class AppBackgroundLayer extends StatelessWidget {
  final AppBackgroundAsset asset;

  const AppBackgroundLayer({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    if (asset.type == AppBackgroundMediaType.image) {
      return SizedBox.expand(
        child: Image(
          image: appCachedNetworkImageProvider(asset.url),
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          isAntiAlias: true,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      );
    }

    return BackgroundVideoView(key: ValueKey(asset.url), url: asset.url);
  }
}
