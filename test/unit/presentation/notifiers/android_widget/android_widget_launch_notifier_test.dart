import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/services/android_widget_launch_uri_source.dart';
import 'package:memora/application/usecases/android_widget/watch_android_widget_launch_uri_usecase.dart';
import 'package:memora/application/usecases/group/get_groups_with_members_usecase.dart';
import 'package:memora/application/usecases/trip/get_trip_entry_by_id_usecase.dart';
import 'package:memora/presentation/notifiers/android_widget/android_widget_launch_notifier.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'android_widget_launch_notifier_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<GetTripEntryByIdUsecase>(),
  MockSpec<GetGroupsWithMembersUsecase>(),
])
class _FakeAndroidWidgetLaunchUriSource
    implements AndroidWidgetLaunchUriSource {
  _FakeAndroidWidgetLaunchUriSource({this.initialUri, this.initialUriFuture});

  final Uri? initialUri;
  final Future<Uri?>? initialUriFuture;
  final controller = StreamController<Uri>.broadcast();

  @override
  Stream<Uri> get clickedUris => controller.stream;

  @override
  Future<Uri?> getInitialUri() {
    return initialUriFuture ?? Future.value(initialUri);
  }
}

void main() {
  const member = MemberDto(id: 'member-1', displayName: 'テストユーザー');
  const trip = TripEntryDto(id: 'trip-1', groupId: 'group-1', year: 2025);
  const testGroup = GroupDto(
    id: 'group-1',
    ownerId: 'member-1',
    name: 'グループ1',
    members: [],
  );

  late MockGetTripEntryByIdUsecase getTripUsecase;
  late MockGetGroupsWithMembersUsecase getGroupsUsecase;

  ProviderContainer createContainer(_FakeAndroidWidgetLaunchUriSource source) {
    return ProviderContainer(
      overrides: [
        watchAndroidWidgetLaunchUriUsecaseProvider.overrideWithValue(
          WatchAndroidWidgetLaunchUriUsecase(source),
        ),
        getTripEntryByIdUsecaseProvider.overrideWithValue(getTripUsecase),
        getGroupsWithMembersUsecaseProvider.overrideWithValue(getGroupsUsecase),
      ],
    );
  }

  group('AndroidWidgetLaunchNotifier', () {
    setUp(() {
      getTripUsecase = MockGetTripEntryByIdUsecase();
      getGroupsUsecase = MockGetGroupsWithMembersUsecase();
    });

    test('ウィジェットからの初回起動URIを解決対象として保留する', () async {
      final source = _FakeAndroidWidgetLaunchUriSource(
        initialUri: Uri.parse('memoraWidget://openTrip?tripId=trip-1'),
      );
      final container = ProviderContainer(
        overrides: [
          watchAndroidWidgetLaunchUriUsecaseProvider.overrideWithValue(
            WatchAndroidWidgetLaunchUriUsecase(source),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await source.controller.close();
      });

      container.read(androidWidgetLaunchNotifierProvider);
      await pumpEventQueue();

      expect(
        container.read(androidWidgetLaunchNotifierProvider).pendingTripId,
        'trip-1',
      );
      expect(
        container.read(androidWidgetLaunchNotifierProvider).isInitialUriLoading,
        isFalse,
      );
    });

    test('設定画面を開く初回起動URIを解決して遷移要求を通知する', () async {
      final source = _FakeAndroidWidgetLaunchUriSource(
        initialUri: Uri.parse('memoraWidget://openSettings'),
      );
      final container = createContainer(source);
      addTearDown(() async {
        container.dispose();
        await source.controller.close();
      });

      container.read(androidWidgetLaunchNotifierProvider);
      await pumpEventQueue();
      final notifier = container.read(
        androidWidgetLaunchNotifierProvider.notifier,
      );

      expect(
        container
            .read(androidWidgetLaunchNotifierProvider)
            .isSettingsLaunchPending,
        isTrue,
      );

      await notifier.resolvePendingLaunch(member);

      expect(
        notifier.takeResolution(member.id),
        const AndroidWidgetSettingsLaunchDestination(memberId: 'member-1'),
      );
      verifyNever(getTripUsecase.execute(any));
      verifyNever(getGroupsUsecase.execute(any));
    });

    test('初回起動URIの確認中だけ読み込み中になる', () async {
      final initialUriCompleter = Completer<Uri?>();
      final source = _FakeAndroidWidgetLaunchUriSource(
        initialUriFuture: initialUriCompleter.future,
      );
      final container = ProviderContainer(
        overrides: [
          watchAndroidWidgetLaunchUriUsecaseProvider.overrideWithValue(
            WatchAndroidWidgetLaunchUriUsecase(source),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await source.controller.close();
      });

      expect(
        container.read(androidWidgetLaunchNotifierProvider).isInitialUriLoading,
        isTrue,
      );

      initialUriCompleter.complete(null);
      await pumpEventQueue();

      expect(
        container.read(androidWidgetLaunchNotifierProvider).isInitialUriLoading,
        isFalse,
      );
    });

    test('起動済みアプリへのクリックURIを保留し不正なURIは無視する', () async {
      final source = _FakeAndroidWidgetLaunchUriSource();
      final container = ProviderContainer(
        overrides: [
          watchAndroidWidgetLaunchUriUsecaseProvider.overrideWithValue(
            WatchAndroidWidgetLaunchUriUsecase(source),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await source.controller.close();
      });

      container.read(androidWidgetLaunchNotifierProvider);
      source.controller.add(Uri.parse('memoraWidget://refresh'));
      await pumpEventQueue();
      expect(
        container.read(androidWidgetLaunchNotifierProvider).pendingTripId,
        isNull,
      );

      source.controller.add(Uri.parse('memoraWidget://openTrip?tripId=trip-2'));
      await pumpEventQueue();

      expect(
        container.read(androidWidgetLaunchNotifierProvider).pendingTripId,
        'trip-2',
      );
    });

    test('旅行と所属グループを順に取得して遷移要求を一度だけ通知する', () async {
      final tripCompleter = Completer<TripEntryDto?>();
      final source = _FakeAndroidWidgetLaunchUriSource(
        initialUri: Uri.parse('memoraWidget://openTrip?tripId=trip-1'),
      );
      when(getTripUsecase.execute(trip.id))
          .thenAnswer((_) => tripCompleter.future);
      when(getGroupsUsecase.execute(member))
          .thenAnswer((_) async => [testGroup]);
      final container = createContainer(source);
      addTearDown(() async {
        container.dispose();
        await source.controller.close();
      });

      container.read(androidWidgetLaunchNotifierProvider);
      await pumpEventQueue();
      final notifier = container.read(
        androidWidgetLaunchNotifierProvider.notifier,
      );

      final resolving = notifier.resolvePendingLaunch(member);

      expect(
        container.read(androidWidgetLaunchNotifierProvider),
        const AndroidWidgetLaunchState(isResolving: true),
      );

      tripCompleter.complete(trip);
      await resolving;

      verifyInOrder([
        getTripUsecase.execute(trip.id),
        getGroupsUsecase.execute(member),
      ]);
      final resolution = notifier.takeResolution(member.id);
      expect(
        resolution,
        const AndroidWidgetLaunchDestination(
          memberId: 'member-1',
          groupId: 'group-1',
          year: 2025,
          tripId: 'trip-1',
          groups: [testGroup],
        ),
      );
      expect(notifier.takeResolution(member.id), isNull);
      expect(
        container.read(androidWidgetLaunchNotifierProvider),
        const AndroidWidgetLaunchState(),
      );
    });

    test('指定された旅行が存在しない場合は失敗を通知して所属グループを取得しない', () async {
      final source = _FakeAndroidWidgetLaunchUriSource(
        initialUri: Uri.parse('memoraWidget://openTrip?tripId=missing-trip'),
      );
      when(getTripUsecase.execute('missing-trip'))
          .thenAnswer((_) async => null);
      final container = createContainer(source);
      addTearDown(() async {
        container.dispose();
        await source.controller.close();
      });

      container.read(androidWidgetLaunchNotifierProvider);
      await pumpEventQueue();
      final notifier = container.read(
        androidWidgetLaunchNotifierProvider.notifier,
      );

      await notifier.resolvePendingLaunch(member);

      expect(
        notifier.takeResolution(member.id),
        const AndroidWidgetLaunchFailure(memberId: 'member-1'),
      );
      verifyNever(getGroupsUsecase.execute(any));
    });

    test('旅行取得に失敗した場合は失敗を通知して再び起動要求を処理できる', () async {
      final source = _FakeAndroidWidgetLaunchUriSource(
        initialUri: Uri.parse('memoraWidget://openTrip?tripId=trip-1'),
      );
      when(getTripUsecase.execute(trip.id)).thenThrow(TestException('旅行取得エラー'));
      final container = createContainer(source);
      addTearDown(() async {
        container.dispose();
        await source.controller.close();
      });

      container.read(androidWidgetLaunchNotifierProvider);
      await pumpEventQueue();
      final notifier = container.read(
        androidWidgetLaunchNotifierProvider.notifier,
      );

      await notifier.resolvePendingLaunch(member);

      expect(
        notifier.takeResolution(member.id),
        const AndroidWidgetLaunchFailure(memberId: 'member-1'),
      );
      expect(
        container.read(androidWidgetLaunchNotifierProvider).isResolving,
        isFalse,
      );
    });

    test('同じ保留要求を連続して処理しても取得は一度だけ実行する', () async {
      final tripCompleter = Completer<TripEntryDto?>();
      final source = _FakeAndroidWidgetLaunchUriSource(
        initialUri: Uri.parse('memoraWidget://openTrip?tripId=trip-1'),
      );
      when(getTripUsecase.execute(trip.id))
          .thenAnswer((_) => tripCompleter.future);
      when(getGroupsUsecase.execute(member))
          .thenAnswer((_) async => [testGroup]);
      final container = createContainer(source);
      addTearDown(() async {
        container.dispose();
        await source.controller.close();
      });

      container.read(androidWidgetLaunchNotifierProvider);
      await pumpEventQueue();
      final notifier = container.read(
        androidWidgetLaunchNotifierProvider.notifier,
      );

      final first = notifier.resolvePendingLaunch(member);
      final duplicate = notifier.resolvePendingLaunch(member);
      tripCompleter.complete(trip);
      await Future.wait([first, duplicate]);

      verify(getTripUsecase.execute(trip.id)).called(1);
      verify(getGroupsUsecase.execute(member)).called(1);
    });

    test('解決中に別の起動要求を受けた場合は古い結果を破棄する', () async {
      const latestTrip = TripEntryDto(
        id: 'trip-2',
        groupId: 'group-1',
        year: 2026,
      );
      final oldTripCompleter = Completer<TripEntryDto?>();
      final latestTripCompleter = Completer<TripEntryDto?>();
      final source = _FakeAndroidWidgetLaunchUriSource(
        initialUri: Uri.parse('memoraWidget://openTrip?tripId=trip-1'),
      );
      when(getTripUsecase.execute(trip.id))
          .thenAnswer((_) => oldTripCompleter.future);
      when(getTripUsecase.execute(latestTrip.id))
          .thenAnswer((_) => latestTripCompleter.future);
      when(getGroupsUsecase.execute(member))
          .thenAnswer((_) async => [testGroup]);
      final container = createContainer(source);
      addTearDown(() async {
        container.dispose();
        await source.controller.close();
      });

      container.read(androidWidgetLaunchNotifierProvider);
      await pumpEventQueue();
      final notifier = container.read(
        androidWidgetLaunchNotifierProvider.notifier,
      );
      final oldResolution = notifier.resolvePendingLaunch(member);

      source.controller.add(Uri.parse('memoraWidget://openTrip?tripId=trip-2'));
      await pumpEventQueue();
      final latestResolution = notifier.resolvePendingLaunch(member);
      latestTripCompleter.complete(latestTrip);
      await latestResolution;

      expect(
        notifier.takeResolution(member.id),
        const AndroidWidgetLaunchDestination(
          memberId: 'member-1',
          groupId: 'group-1',
          year: 2026,
          tripId: 'trip-2',
          groups: [testGroup],
        ),
      );

      oldTripCompleter.complete(trip);
      await oldResolution;
      expect(notifier.takeResolution(member.id), isNull);
    });

    test('別の要求を受信後に古い処理と同じ旅行を受信した場合は最新要求として保留する', () async {
      final oldTripCompleter = Completer<TripEntryDto?>();
      final source = _FakeAndroidWidgetLaunchUriSource(
        initialUri: Uri.parse('memoraWidget://openTrip?tripId=trip-1'),
      );
      when(getTripUsecase.execute(trip.id))
          .thenAnswer((_) => oldTripCompleter.future);
      final container = createContainer(source);
      addTearDown(() async {
        container.dispose();
        await source.controller.close();
      });

      container.read(androidWidgetLaunchNotifierProvider);
      await pumpEventQueue();
      final notifier = container.read(
        androidWidgetLaunchNotifierProvider.notifier,
      );
      final oldResolution = notifier.resolvePendingLaunch(member);

      source.controller.add(Uri.parse('memoraWidget://openTrip?tripId=trip-2'));
      await pumpEventQueue();
      source.controller.add(Uri.parse('memoraWidget://openTrip?tripId=trip-1'));
      await pumpEventQueue();

      expect(
        container.read(androidWidgetLaunchNotifierProvider).pendingTripId,
        'trip-1',
      );

      oldTripCompleter.complete(trip);
      await oldResolution;
    });

    test('解決をキャンセルした場合は遅れて完了した結果を通知しない', () async {
      final tripCompleter = Completer<TripEntryDto?>();
      final source = _FakeAndroidWidgetLaunchUriSource(
        initialUri: Uri.parse('memoraWidget://openTrip?tripId=trip-1'),
      );
      when(getTripUsecase.execute(trip.id))
          .thenAnswer((_) => tripCompleter.future);
      final container = createContainer(source);
      addTearDown(() async {
        container.dispose();
        await source.controller.close();
      });

      container.read(androidWidgetLaunchNotifierProvider);
      await pumpEventQueue();
      final notifier = container.read(
        androidWidgetLaunchNotifierProvider.notifier,
      );
      final resolving = notifier.resolvePendingLaunch(member);

      notifier.cancelPendingLaunch();
      tripCompleter.complete(trip);
      await resolving;

      expect(
        container.read(androidWidgetLaunchNotifierProvider),
        const AndroidWidgetLaunchState(),
      );
    });

    test('別のメンバーが取得した解決結果は消費せず破棄する', () async {
      const otherMember = MemberDto(id: 'member-2', displayName: '別ユーザー');
      final source = _FakeAndroidWidgetLaunchUriSource(
        initialUri: Uri.parse('memoraWidget://openTrip?tripId=trip-1'),
      );
      when(getTripUsecase.execute(trip.id)).thenAnswer((_) async => trip);
      when(getGroupsUsecase.execute(member))
          .thenAnswer((_) async => [testGroup]);
      final container = createContainer(source);
      addTearDown(() async {
        container.dispose();
        await source.controller.close();
      });

      container.read(androidWidgetLaunchNotifierProvider);
      await pumpEventQueue();
      final notifier = container.read(
        androidWidgetLaunchNotifierProvider.notifier,
      );
      await notifier.resolvePendingLaunch(member);

      expect(notifier.takeResolution(otherMember.id), isNull);
      expect(
        container.read(androidWidgetLaunchNotifierProvider).resolution,
        isNull,
      );
    });

    test('同じ旅行の再解決中に古い要求が完了しても重複要求として無視する', () async {
      final firstTripCompleter = Completer<TripEntryDto?>();
      final secondTripCompleter = Completer<TripEntryDto?>();
      var executionCount = 0;
      final source = _FakeAndroidWidgetLaunchUriSource(
        initialUri: Uri.parse('memoraWidget://openTrip?tripId=trip-1'),
      );
      when(getTripUsecase.execute(trip.id)).thenAnswer((_) {
        executionCount++;
        return executionCount == 1
            ? firstTripCompleter.future
            : secondTripCompleter.future;
      });
      when(getGroupsUsecase.execute(member))
          .thenAnswer((_) async => [testGroup]);
      final container = createContainer(source);
      addTearDown(() async {
        container.dispose();
        await source.controller.close();
      });

      container.read(androidWidgetLaunchNotifierProvider);
      await pumpEventQueue();
      final notifier = container.read(
        androidWidgetLaunchNotifierProvider.notifier,
      );
      final firstResolution = notifier.resolvePendingLaunch(member);

      notifier.cancelPendingLaunch();
      source.controller.add(Uri.parse('memoraWidget://openTrip?tripId=trip-1'));
      await pumpEventQueue();
      final secondResolution = notifier.resolvePendingLaunch(member);

      firstTripCompleter.complete(trip);
      await firstResolution;
      source.controller.add(Uri.parse('memoraWidget://openTrip?tripId=trip-1'));
      await pumpEventQueue();

      expect(
        container.read(androidWidgetLaunchNotifierProvider).pendingTripId,
        isNull,
      );

      secondTripCompleter.complete(trip);
      await secondResolution;

      expect(
        notifier.takeResolution(member.id),
        const AndroidWidgetLaunchDestination(
          memberId: 'member-1',
          groupId: 'group-1',
          year: 2025,
          tripId: 'trip-1',
          groups: [testGroup],
        ),
      );
      verify(getTripUsecase.execute(trip.id)).called(2);
    });
  });
}
