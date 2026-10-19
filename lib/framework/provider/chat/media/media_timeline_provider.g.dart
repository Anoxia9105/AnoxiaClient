// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_timeline_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 媒体时间线控制器（按房间 family；autoDispose）

@ProviderFor(MediaTimelineController)
final mediaTimelineControllerProvider = MediaTimelineControllerFamily._();

/// 媒体时间线控制器（按房间 family；autoDispose）
final class MediaTimelineControllerProvider
    extends
        $AsyncNotifierProvider<MediaTimelineController, MediaTimelineState> {
  /// 媒体时间线控制器（按房间 family；autoDispose）
  MediaTimelineControllerProvider._({
    required MediaTimelineControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'mediaTimelineControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$mediaTimelineControllerHash();

  @override
  String toString() {
    return r'mediaTimelineControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MediaTimelineController create() => MediaTimelineController();

  @override
  bool operator ==(Object other) {
    return other is MediaTimelineControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$mediaTimelineControllerHash() =>
    r'b36ab2e0c8db4e6e90392cdbc509aab58dc8f93e';

/// 媒体时间线控制器（按房间 family；autoDispose）

final class MediaTimelineControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          MediaTimelineController,
          AsyncValue<MediaTimelineState>,
          MediaTimelineState,
          FutureOr<MediaTimelineState>,
          String
        > {
  MediaTimelineControllerFamily._()
    : super(
        retry: null,
        name: r'mediaTimelineControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 媒体时间线控制器（按房间 family；autoDispose）

  MediaTimelineControllerProvider call(String roomId) =>
      MediaTimelineControllerProvider._(argument: roomId, from: this);

  @override
  String toString() => r'mediaTimelineControllerProvider';
}

/// 媒体时间线控制器（按房间 family；autoDispose）

abstract class _$MediaTimelineController
    extends $AsyncNotifier<MediaTimelineState> {
  late final _$args = ref.$arg as String;
  String get roomId => _$args;

  FutureOr<MediaTimelineState> build(String roomId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<MediaTimelineState>, MediaTimelineState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<MediaTimelineState>, MediaTimelineState>,
              AsyncValue<MediaTimelineState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
