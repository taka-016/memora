import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/calendar/calendar_launch_request_dto.dart';
import 'package:memora/application/services/calendar/calendar_launch_source.dart';
import 'package:memora/application/usecases/calendar/watch_calendar_launch_usecase.dart';
import 'package:memora/composition_root/providers/calendar_launch_providers.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_launch_notifier.dart';

class _LaunchSource implements CalendarLaunchSource {
  final events = StreamController<void>.broadcast(sync: true);
  Future<CalendarLaunchRequestDto?> Function() read = () async => null;
  @override
  Stream<void> get changes => events.stream;
  @override
  Future<CalendarLaunchRequestDto?> takePending() => read();
}

void main() {
  test('起動時の取得中に変更通知が重なっても消費済みの要求を失わない', () async {
    final source = _LaunchSource();
    addTearDown(source.events.close);
    final pending = Completer<CalendarLaunchRequestDto?>();
    source.read = () => pending.future;
    final container = ProviderContainer(overrides: [
      watchCalendarLaunchUsecaseProvider.overrideWithValue(WatchCalendarLaunchUsecase(source)),
    ]);
    addTearDown(container.dispose);
    container.read(calendarLaunchNotifierProvider);
    source.read = () async => null;
    source.events.add(null);
    await container.pump();
    final request = CalendarLaunchRequestDto(date: DateTime(2026, 11, 28));
    pending.complete(request);
    await container.pump();
    expect(container.read(calendarLaunchNotifierProvider).request, same(request));
  });

  test('ログイン待ちの要求を保持し一度消費した後も同じ日付で再起動できる', () async {
    final source = _LaunchSource();
    addTearDown(source.events.close);
    final request = CalendarLaunchRequestDto(date: DateTime(2026, 11, 28));
    source.read = () async => request;
    final container = ProviderContainer(overrides: [
      watchCalendarLaunchUsecaseProvider.overrideWithValue(WatchCalendarLaunchUsecase(source)),
    ]);
    addTearDown(container.dispose);
    container.read(calendarLaunchNotifierProvider);
    await container.pump();
    expect(container.read(calendarLaunchNotifierProvider).request, same(request));
    final notifier = container.read(calendarLaunchNotifierProvider.notifier);
    expect(notifier.takeRequest(), same(request));
    expect(notifier.takeRequest(), isNull);
    final previousSequence = container.read(calendarLaunchNotifierProvider).sequence;
    source.events.add(null);
    await container.pump();
    expect(notifier.takeRequest(), same(request));
    expect(container.read(calendarLaunchNotifierProvider).sequence, greaterThan(previousSequence));
  });

  test('ログアウト後は取得中だった要求を復活させない', () async {
    final source = _LaunchSource();
    addTearDown(source.events.close);
    final pending = Completer<CalendarLaunchRequestDto?>();
    source.read = () => pending.future;
    final container = ProviderContainer(overrides: [
      watchCalendarLaunchUsecaseProvider.overrideWithValue(WatchCalendarLaunchUsecase(source)),
    ]);
    addTearDown(container.dispose);
    container.read(calendarLaunchNotifierProvider);
    await container.pump();
    container.read(calendarLaunchNotifierProvider.notifier).cancelPendingLaunch();
    pending.complete(CalendarLaunchRequestDto(date: DateTime(2026, 11, 28)));
    await container.pump();
    expect(container.read(calendarLaunchNotifierProvider).request, isNull);
    expect(container.read(calendarLaunchNotifierProvider).isLoading, isFalse);
  });
}
