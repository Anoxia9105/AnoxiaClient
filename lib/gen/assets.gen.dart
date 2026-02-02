// dart format width=80

/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: deprecated_member_use,directives_ordering,implicit_dynamic_list_literal,unnecessary_import

import 'package:flutter/widgets.dart';

class $AssetsI18nGen {
  const $AssetsI18nGen();

  /// File path: assets/i18n/en.json
  String get en => 'assets/i18n/en.json';

  /// File path: assets/i18n/ja.json
  String get ja => 'assets/i18n/ja.json';

  /// File path: assets/i18n/zh.json
  String get zh => 'assets/i18n/zh.json';

  /// List of all assets
  List<String> get values => [en, ja, zh];
}

class $AssetsImagesGen {
  const $AssetsImagesGen();

  /// File path: assets/images/app_icon.ico
  String get appIconIco => 'assets/images/app_icon.ico';

  /// File path: assets/images/app_icon.png
  AssetGenImage get appIconPng =>
      const AssetGenImage('assets/images/app_icon.png');

  /// Directory path: assets/images/badge
  $AssetsImagesBadgeGen get badge => const $AssetsImagesBadgeGen();

  /// List of all assets
  List<dynamic> get values => [appIconIco, appIconPng];
}

class $AssetsImagesBadgeGen {
  const $AssetsImagesBadgeGen();

  /// File path: assets/images/badge/badge_1.ico
  String get badge1 => 'assets/images/badge/badge_1.ico';

  /// File path: assets/images/badge/badge_1_16.ico
  String get badge116 => 'assets/images/badge/badge_1_16.ico';

  /// File path: assets/images/badge/badge_1back.ico
  String get badge1back => 'assets/images/badge/badge_1back.ico';

  /// File path: assets/images/badge/badge_2.ico
  String get badge2 => 'assets/images/badge/badge_2.ico';

  /// File path: assets/images/badge/badge_3.ico
  String get badge3 => 'assets/images/badge/badge_3.ico';

  /// File path: assets/images/badge/badge_4.ico
  String get badge4 => 'assets/images/badge/badge_4.ico';

  /// File path: assets/images/badge/badge_5.ico
  String get badge5 => 'assets/images/badge/badge_5.ico';

  /// File path: assets/images/badge/badge_6.ico
  String get badge6 => 'assets/images/badge/badge_6.ico';

  /// File path: assets/images/badge/badge_7.ico
  String get badge7 => 'assets/images/badge/badge_7.ico';

  /// File path: assets/images/badge/badge_8.ico
  String get badge8 => 'assets/images/badge/badge_8.ico';

  /// File path: assets/images/badge/badge_9.ico
  String get badge9 => 'assets/images/badge/badge_9.ico';

  /// File path: assets/images/badge/badge_more.ico
  String get badgeMore => 'assets/images/badge/badge_more.ico';

  /// List of all assets
  List<String> get values => [
    badge1,
    badge116,
    badge1back,
    badge2,
    badge3,
    badge4,
    badge5,
    badge6,
    badge7,
    badge8,
    badge9,
    badgeMore,
  ];
}

class Assets {
  const Assets._();

  static const $AssetsI18nGen i18n = $AssetsI18nGen();
  static const $AssetsImagesGen images = $AssetsImagesGen();
}

class AssetGenImage {
  const AssetGenImage(
    this._assetName, {
    this.size,
    this.flavors = const {},
    this.animation,
  });

  final String _assetName;

  final Size? size;
  final Set<String> flavors;
  final AssetGenImageAnimation? animation;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = true,
    bool isAntiAlias = false,
    String? package,
    FilterQuality filterQuality = FilterQuality.medium,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({AssetBundle? bundle, String? package}) {
    return AssetImage(_assetName, bundle: bundle, package: package);
  }

  String get path => _assetName;

  String get keyName => _assetName;
}

class AssetGenImageAnimation {
  const AssetGenImageAnimation({
    required this.isAnimation,
    required this.duration,
    required this.frames,
  });

  final bool isAnimation;
  final Duration duration;
  final int frames;
}
