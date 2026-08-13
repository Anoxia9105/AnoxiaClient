import 'dart:async';
import 'dart:typed_data';

import 'package:anoxia/domain/repositories/app_background_repository.dart';
import 'package:anoxia/framework/domain/app_background.dart';
import 'package:anoxia/framework/provider/core/app_background_repository_provider.dart';
import 'package:anoxia/framework/provider/theme/theme_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'rapid background selections are persisted in order and latest wins',
    () async {
      final repository = _ControlledBackgroundRepository();
      final container = ProviderContainer(
        overrides: [
          appBackgroundRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(appBackgroundProvider.notifier);
      final first = controller.savePreference(activeAssetId: 1);
      final second = controller.savePreference(activeAssetId: 2);

      await Future<void>.delayed(Duration.zero);
      expect(repository.preferenceRequests, hasLength(1));
      repository.preferenceRequests.single.complete(_state(activeAssetId: 1));
      await first;
      await Future<void>.delayed(Duration.zero);
      expect(repository.preferenceRequests, hasLength(2));
      repository.preferenceRequests.last.complete(_state(activeAssetId: 2));
      await second;

      expect(container.read(appBackgroundProvider).activeAssetId, 2);
    },
  );

  test(
    'an older refresh cannot overwrite a selection made while loading',
    () async {
      final repository = _ControlledBackgroundRepository();
      final container = ProviderContainer(
        overrides: [
          appBackgroundRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(appBackgroundProvider.notifier);
      final refresh = controller.refresh();
      final selection = controller.savePreference(activeAssetId: 2);

      repository.fetchRequest.complete(_state(activeAssetId: 1));
      await refresh;
      repository.preferenceRequests.single.complete(_state(activeAssetId: 2));
      await selection;

      expect(container.read(appBackgroundProvider).activeAssetId, 2);
    },
  );
}

AppBackgroundState _state({required int activeAssetId}) => AppBackgroundState(
  assets: const [
    AppBackgroundAsset(
      id: 1,
      type: AppBackgroundMediaType.image,
      url: 'https://cdn.example.com/one.jpg',
      name: 'one',
    ),
    AppBackgroundAsset(
      id: 2,
      type: AppBackgroundMediaType.video,
      url: 'https://cdn.example.com/two.mp4',
      name: 'two',
    ),
  ],
  activeAssetId: activeAssetId,
);

class _ControlledBackgroundRepository implements AppBackgroundRepository {
  final fetchRequest = Completer<AppBackgroundState>();
  final List<Completer<AppBackgroundState>> preferenceRequests = [];

  @override
  Future<AppBackgroundState> fetch() => fetchRequest.future;

  @override
  Future<AppBackgroundState> updatePreference({
    required int? activeAssetId,
    required double surfaceOpacity,
  }) {
    final request = Completer<AppBackgroundState>();
    preferenceRequests.add(request);
    return request.future;
  }

  @override
  Future<AppBackgroundState> delete(int assetId) => throw UnimplementedError();

  @override
  Future<AppBackgroundState> upload({
    required Uint8List bytes,
    required String fileName,
    UploadProgressCallback? onProgress,
  }) => throw UnimplementedError();
}
