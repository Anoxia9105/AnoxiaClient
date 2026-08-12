import 'package:anoxia/common/widgets/app/app_background_layer.dart';
import 'package:anoxia/common/widgets/app/background_video_view.dart';
import 'package:anoxia/framework/domain/app_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('视频背景使用专用视频视图并填满可用区域', (tester) async {
    const asset = AppBackgroundAsset(
      id: 1,
      type: AppBackgroundMediaType.video,
      url: 'https://cdn.example.com/background.mp4',
      name: 'background.mp4',
    );

    await tester.pumpWidget(
      const MaterialApp(home: AppBackgroundLayer(asset: asset)),
    );

    final video = tester.widget<BackgroundVideoView>(
      find.byType(BackgroundVideoView),
    );
    expect(video.url, asset.url);
    expect(video.autoplay, isTrue);
  });

  testWidgets('图片背景使用高质量抗锯齿 cover 渲染', (tester) async {
    const asset = AppBackgroundAsset(
      id: 2,
      type: AppBackgroundMediaType.image,
      url: 'https://cdn.example.com/background.jpg',
      name: 'background.jpg',
    );

    await tester.pumpWidget(
      const MaterialApp(home: AppBackgroundLayer(asset: asset)),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.fit, BoxFit.cover);
    expect(image.filterQuality, FilterQuality.high);
    expect(image.isAntiAlias, isTrue);
  });
}
