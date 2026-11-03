// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_holidays.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(holidayRepository)
final holidayRepositoryProvider = HolidayRepositoryProvider._();

final class HolidayRepositoryProvider
    extends
        $FunctionalProvider<
          HolidayRepository,
          HolidayRepository,
          HolidayRepository
        >
    with $Provider<HolidayRepository> {
  HolidayRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'holidayRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$holidayRepositoryHash();

  @$internal
  @override
  $ProviderElement<HolidayRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HolidayRepository create(Ref ref) {
    return holidayRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HolidayRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HolidayRepository>(value),
    );
  }
}

String _$holidayRepositoryHash() => r'34e38f6453eb64997e3deaaaf92339eaf3eb143e';

@ProviderFor(scheduleHolidays)
final scheduleHolidaysProvider = ScheduleHolidaysFamily._();

final class ScheduleHolidaysProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, ScheduleHoliday>>,
          Map<String, ScheduleHoliday>,
          Stream<Map<String, ScheduleHoliday>>
        >
    with
        $FutureModifier<Map<String, ScheduleHoliday>>,
        $StreamProvider<Map<String, ScheduleHoliday>> {
  ScheduleHolidaysProvider._({
    required ScheduleHolidaysFamily super.from,
    required (ScheduleHolidayRegion, int) super.argument,
  }) : super(
         retry: null,
         name: r'scheduleHolidaysProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$scheduleHolidaysHash();

  @override
  String toString() {
    return r'scheduleHolidaysProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<Map<String, ScheduleHoliday>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, ScheduleHoliday>> create(Ref ref) {
    final argument = this.argument as (ScheduleHolidayRegion, int);
    return scheduleHolidays(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is ScheduleHolidaysProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$scheduleHolidaysHash() => r'9993da63178f0045ec5eed8700f3685993b8fcf3';

final class ScheduleHolidaysFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<Map<String, ScheduleHoliday>>,
          (ScheduleHolidayRegion, int)
        > {
  ScheduleHolidaysFamily._()
    : super(
        retry: null,
        name: r'scheduleHolidaysProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ScheduleHolidaysProvider call(ScheduleHolidayRegion region, int year) =>
      ScheduleHolidaysProvider._(argument: (region, year), from: this);

  @override
  String toString() => r'scheduleHolidaysProvider';
}
