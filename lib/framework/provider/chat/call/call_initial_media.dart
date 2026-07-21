import 'package:flutter_riverpod/legacy.dart' show StateProvider;

enum CallInitialMedia {
  audio('audio'),
  video('video');

  final String value;

  const CallInitialMedia(this.value);

  static CallInitialMedia fromValue(Object? value) {
    return switch (value?.toString()) {
      'video' => CallInitialMedia.video,
      _ => CallInitialMedia.audio,
    };
  }
}

final callInitialMediaProvider = StateProvider.family<CallInitialMedia, String>(
  (ref, roomId) => CallInitialMedia.audio,
);

final callIsGroupProvider = StateProvider.family<bool, String>(
  (ref, roomId) => false,
);
