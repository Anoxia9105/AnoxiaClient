// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ScheduleService)
final scheduleServiceProvider = ScheduleServiceProvider._();

final class ScheduleServiceProvider
    extends $AsyncNotifierProvider<ScheduleService, List<ScheduleEvent>> {
  ScheduleServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scheduleServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scheduleServiceHash();

  @$internal
  @override
  ScheduleService create() => ScheduleService();
}

String _$scheduleServiceHash() => r'149f288cc97e3eac5b2a2b18130053de7c239b0c';

abstract class _$ScheduleService extends $AsyncNotifier<List<ScheduleEvent>> {
  FutureOr<List<ScheduleEvent>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<ScheduleEvent>>, List<ScheduleEvent>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ScheduleEvent>>, List<ScheduleEvent>>,
              AsyncValue<List<ScheduleEvent>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
