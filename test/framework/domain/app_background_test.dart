import 'package:anoxia/framework/domain/app_background.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppBackgroundState', () {
    test('parses cloud assets and clamps opacity', () {
      final state = AppBackgroundState.fromJson({
        'activeAssetId': 7,
        'surfaceOpacity': 1.4,
        'assets': [
          {
            'id': 7,
            'mediaType': 'VIDEO',
            'url': 'https://cdn.example.com/background.mp4',
            'name': 'Ocean',
          },
        ],
      });

      expect(state.activeAsset?.id, 7);
      expect(state.activeAsset?.type, AppBackgroundMediaType.video);
      expect(state.surfaceOpacity, AppBackgroundState.maxSurfaceOpacity);
    });

    test('falls back safely for malformed cloud values', () {
      final state = AppBackgroundState.fromJson({
        'activeAssetId': 'missing',
        'surfaceOpacity': 'invalid',
        'assets': [
          {
            'id': 3,
            'mediaType': 'unknown',
            'url': 'https://cdn.example.com/not-media',
          },
        ],
      });

      expect(state.assets, isEmpty);
      expect(state.activeAsset, isNull);
      expect(state.surfaceOpacity, AppBackgroundState.defaultSurfaceOpacity);
    });

    test('round-trips the active selection and opacity', () {
      const state = AppBackgroundState(
        assets: [
          AppBackgroundAsset(
            id: 2,
            type: AppBackgroundMediaType.image,
            url: 'https://cdn.example.com/background.webp',
            name: 'Forest',
          ),
        ],
        activeAssetId: 2,
        surfaceOpacity: 0.72,
      );

      expect(AppBackgroundState.fromJson(state.toJson()), state);
    });

    test('clamps upload progress and can clear it after completion', () {
      const state = AppBackgroundState(uploading: true, uploadProgress: 0);

      final uploading = state.copyWith(uploadProgress: 1.4);
      final completed = uploading.copyWith(
        uploading: false,
        clearUploadProgress: true,
      );

      expect(uploading.uploadProgress, 1);
      expect(completed.uploadProgress, isNull);
      expect(completed.uploading, isFalse);
    });

    test('keeps local upload progress when merging unrelated cloud state', () {
      const uploading = AppBackgroundState(
        uploading: true,
        uploadProgress: 0.42,
        surfaceOpacity: 0.7,
      );
      const remote = AppBackgroundState(surfaceOpacity: 0.65);

      final merged = uploading.mergeRemote(
        remote,
        preserveUpload: true,
        surfaceOpacityOverride: uploading.surfaceOpacity,
      );

      expect(merged.uploading, isTrue);
      expect(merged.uploadProgress, 0.42);
      expect(merged.surfaceOpacity, 0.7);
    });

    test('reserves the final upload progress for cloud persistence', () {
      expect(AppBackgroundState.displayUploadProgress(0, 100), 0);
      expect(AppBackgroundState.displayUploadProgress(50, 100), 0.45);
      expect(AppBackgroundState.displayUploadProgress(100, 100), 0.9);
      expect(AppBackgroundState.displayUploadProgress(120, 100), 0.9);
      expect(AppBackgroundState.displayUploadProgress(1, 0), 0);
    });
  });

  group('AppBackgroundAsset', () {
    test('falls back to the decoded URL filename when name is empty', () {
      const asset = AppBackgroundAsset(
        id: 7,
        type: AppBackgroundMediaType.video,
        url: 'https://cdn.example.com/backgrounds/demo%20video.mp4',
        name: '',
      );

      expect(asset.displayName, 'demo video.mp4');
    });
  });
}
