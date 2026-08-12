enum AppBackgroundMediaType { image, video }

class AppBackgroundAsset {
  final int id;
  final AppBackgroundMediaType type;
  final String url;
  final String name;

  const AppBackgroundAsset({
    required this.id,
    required this.type,
    required this.url,
    required this.name,
  });

  factory AppBackgroundAsset.fromJson(Map<String, dynamic> json) {
    final rawType = json['mediaType']?.toString().toUpperCase();
    return AppBackgroundAsset(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      type: rawType == 'VIDEO'
          ? AppBackgroundMediaType.video
          : AppBackgroundMediaType.image,
      url: json['url']?.toString().trim() ?? '',
      name: json['name']?.toString().trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'mediaType': type.name.toUpperCase(),
    'url': url,
    'name': name,
  };

  @override
  bool operator ==(Object other) =>
      other is AppBackgroundAsset &&
      id == other.id &&
      type == other.type &&
      url == other.url &&
      name == other.name;

  @override
  int get hashCode => Object.hash(id, type, url, name);
}

class AppBackgroundState {
  static const double defaultSurfaceOpacity = 0.86;
  static const double minSurfaceOpacity = 0.45;
  static const double maxSurfaceOpacity = 0.96;

  final List<AppBackgroundAsset> assets;
  final int? activeAssetId;
  final double surfaceOpacity;
  final bool loading;
  final bool uploading;
  final double? uploadProgress;
  final String? error;

  const AppBackgroundState({
    this.assets = const [],
    this.activeAssetId,
    this.surfaceOpacity = defaultSurfaceOpacity,
    this.loading = false,
    this.uploading = false,
    this.uploadProgress,
    this.error,
  });

  factory AppBackgroundState.fromJson(Map<String, dynamic> json) {
    final rawAssets = json['assets'];
    final assets = rawAssets is List
        ? rawAssets
              .whereType<Map>()
              .where((item) {
                final type = item['mediaType']?.toString().toUpperCase();
                return type == 'IMAGE' || type == 'VIDEO';
              })
              .map(
                (item) =>
                    AppBackgroundAsset.fromJson(item.cast<String, dynamic>()),
              )
              .where((item) => item.id > 0 && item.url.isNotEmpty)
              .toList(growable: false)
        : const <AppBackgroundAsset>[];
    final rawOpacity = double.tryParse(
      json['surfaceOpacity']?.toString() ?? '',
    );
    return AppBackgroundState(
      assets: assets,
      activeAssetId: int.tryParse(json['activeAssetId']?.toString() ?? ''),
      surfaceOpacity: (rawOpacity ?? defaultSurfaceOpacity).clamp(
        minSurfaceOpacity,
        maxSurfaceOpacity,
      ),
    );
  }

  AppBackgroundAsset? get activeAsset {
    for (final asset in assets) {
      if (asset.id == activeAssetId) return asset;
    }
    return null;
  }

  AppBackgroundState copyWith({
    List<AppBackgroundAsset>? assets,
    int? activeAssetId,
    bool clearActiveAsset = false,
    double? surfaceOpacity,
    bool? loading,
    bool? uploading,
    double? uploadProgress,
    bool clearUploadProgress = false,
    String? error,
    bool clearError = false,
  }) => AppBackgroundState(
    assets: assets ?? this.assets,
    activeAssetId: clearActiveAsset
        ? null
        : (activeAssetId ?? this.activeAssetId),
    surfaceOpacity: (surfaceOpacity ?? this.surfaceOpacity).clamp(
      minSurfaceOpacity,
      maxSurfaceOpacity,
    ),
    loading: loading ?? this.loading,
    uploading: uploading ?? this.uploading,
    uploadProgress: clearUploadProgress
        ? null
        : uploadProgress?.clamp(0, 1) ?? this.uploadProgress,
    error: clearError ? null : (error ?? this.error),
  );

  Map<String, dynamic> toJson() => {
    'assets': assets.map((item) => item.toJson()).toList(growable: false),
    'activeAssetId': activeAssetId,
    'surfaceOpacity': surfaceOpacity,
  };

  @override
  bool operator ==(Object other) =>
      other is AppBackgroundState &&
      _listEquals(assets, other.assets) &&
      activeAssetId == other.activeAssetId &&
      surfaceOpacity == other.surfaceOpacity &&
      loading == other.loading &&
      uploading == other.uploading &&
      uploadProgress == other.uploadProgress &&
      error == other.error;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(assets),
    activeAssetId,
    surfaceOpacity,
    loading,
    uploading,
    uploadProgress,
    error,
  );

  static bool _listEquals<T>(List<T> left, List<T> right) {
    if (identical(left, right)) return true;
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}
