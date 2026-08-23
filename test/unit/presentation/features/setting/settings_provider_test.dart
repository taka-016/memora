import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/services/android_widget_cache_storage.dart';
import 'package:memora/application/services/android_widget_update_interval_storage.dart';
import 'package:memora/application/usecases/android_widget/android_widget_itinerary_cache_usecases.dart';
import 'package:memora/application/usecases/android_widget/update_android_widget_interval_usecase.dart';
import 'package:memora/application/usecases/group/get_groups_with_members_usecase.dart';
import 'package:memora/presentation/features/setting/settings.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'settings_provider_test.mocks.dart';

@GenerateMocks([
  AndroidWidgetCacheStorage,
  AndroidWidgetUpdateIntervalStorage,
  ClearAndroidWidgetTargetGroupUsecase,
  GetGroupsWithMembersUsecase,
  SelectAndroidWidgetTargetGroupUsecase,
  UpdateAndroidWidgetIntervalUsecase,
])
void main() {
  const member = MemberDto(id: 'member-1', displayName: '太郎');
  const secondMember = MemberDto(id: 'member-2', displayName: '花子');
  const groupA = GroupDto(
    id: 'group-a',
    ownerId: 'member-1',
    name: 'グループA',
    members: [],
  );
  const groupB = GroupDto(
    id: 'group-b',
    ownerId: 'member-1',
    name: 'グループB',
    members: [],
  );

  late MockAndroidWidgetCacheStorage cacheStorage;
  late MockAndroidWidgetUpdateIntervalStorage intervalStorage;
  late MockClearAndroidWidgetTargetGroupUsecase clearTargetGroupUsecase;
  late MockGetGroupsWithMembersUsecase getGroupsUsecase;
  late MockSelectAndroidWidgetTargetGroupUsecase selectTargetGroupUsecase;
  late MockUpdateAndroidWidgetIntervalUsecase updateIntervalUsecase;
  late ProviderContainer container;

  setUp(() {
    cacheStorage = MockAndroidWidgetCacheStorage();
    intervalStorage = MockAndroidWidgetUpdateIntervalStorage();
    clearTargetGroupUsecase = MockClearAndroidWidgetTargetGroupUsecase();
    getGroupsUsecase = MockGetGroupsWithMembersUsecase();
    selectTargetGroupUsecase = MockSelectAndroidWidgetTargetGroupUsecase();
    updateIntervalUsecase = MockUpdateAndroidWidgetIntervalUsecase();
    container = ProviderContainer(
      overrides: [
        androidWidgetCacheStorageProvider.overrideWithValue(cacheStorage),
        androidWidgetUpdateIntervalStorageProvider.overrideWithValue(
          intervalStorage,
        ),
        clearAndroidWidgetTargetGroupUsecaseProvider.overrideWithValue(
          clearTargetGroupUsecase,
        ),
        getGroupsWithMembersUsecaseProvider.overrideWithValue(getGroupsUsecase),
        selectAndroidWidgetTargetGroupUsecaseProvider.overrideWithValue(
          selectTargetGroupUsecase,
        ),
        updateAndroidWidgetIntervalUsecaseProvider.overrideWithValue(
          updateIntervalUsecase,
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('androidWidgetUpdateIntervalProvider', () {
    test('初期値を取得する', () async {
      when(
        intervalStorage.load(),
      ).thenAnswer((_) async => AndroidWidgetUpdateInterval.every24Hours);
      final subscription = container.listen(
        androidWidgetUpdateIntervalProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);

      expect(
        (await container.read(
          androidWidgetUpdateIntervalProvider.future,
        )).interval,
        AndroidWidgetUpdateInterval.every24Hours,
      );
    });

    test('初期取得失敗後にProviderを再構築して再試行できる', () async {
      when(intervalStorage.load()).thenThrow(TestException('取得失敗'));
      final subscription = container.listen(
        androidWidgetUpdateIntervalProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);

      await expectLater(
        container.read(androidWidgetUpdateIntervalProvider.future),
        throwsA(isA<TestException>()),
      );

      when(
        intervalStorage.load(),
      ).thenAnswer((_) async => AndroidWidgetUpdateInterval.every6Hours);
      container.invalidate(androidWidgetUpdateIntervalProvider);

      expect(
        (await container.read(
          androidWidgetUpdateIntervalProvider.future,
        )).interval,
        AndroidWidgetUpdateInterval.every6Hours,
      );
      verify(intervalStorage.load()).called(2);
    });

    test('保存中は現在値を維持して連続保存を受け付けない', () async {
      when(
        intervalStorage.load(),
      ).thenAnswer((_) async => AndroidWidgetUpdateInterval.every24Hours);
      final completer = Completer<void>();
      when(
        updateIntervalUsecase.execute(AndroidWidgetUpdateInterval.every6Hours),
      ).thenAnswer((_) => completer.future);
      final subscription = container.listen(
        androidWidgetUpdateIntervalProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      await container.read(androidWidgetUpdateIntervalProvider.future);
      final notifier = container.read(
        androidWidgetUpdateIntervalProvider.notifier,
      );

      final firstSave = notifier.save(AndroidWidgetUpdateInterval.every6Hours);
      await container.pump();
      final secondSave = await notifier.save(
        AndroidWidgetUpdateInterval.every3Hours,
      );

      final savingState = container.read(androidWidgetUpdateIntervalProvider);
      expect(savingState.requireValue.isSaving, isTrue);
      expect(
        savingState.requireValue.interval,
        AndroidWidgetUpdateInterval.every24Hours,
      );
      expect(secondSave, isFalse);
      verifyNever(
        updateIntervalUsecase.execute(AndroidWidgetUpdateInterval.every3Hours),
      );

      completer.complete();
      expect(await firstSave, isTrue);
      expect(
        container
            .read(androidWidgetUpdateIntervalProvider)
            .requireValue
            .interval,
        AndroidWidgetUpdateInterval.every6Hours,
      );
    });

    test('保存失敗時は表示値を維持し、同じ操作を再試行できる', () async {
      when(
        intervalStorage.load(),
      ).thenAnswer((_) async => AndroidWidgetUpdateInterval.every24Hours);
      when(
        updateIntervalUsecase.execute(AndroidWidgetUpdateInterval.every6Hours),
      ).thenThrow(TestException('保存失敗'));
      final subscription = container.listen(
        androidWidgetUpdateIntervalProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      await container.read(androidWidgetUpdateIntervalProvider.future);
      final notifier = container.read(
        androidWidgetUpdateIntervalProvider.notifier,
      );

      await expectLater(
        notifier.save(AndroidWidgetUpdateInterval.every6Hours),
        throwsA(isA<TestException>()),
      );
      expect(
        container
            .read(androidWidgetUpdateIntervalProvider)
            .requireValue
            .interval,
        AndroidWidgetUpdateInterval.every24Hours,
      );

      when(
        updateIntervalUsecase.execute(AndroidWidgetUpdateInterval.every6Hours),
      ).thenAnswer((_) async {});
      expect(
        await notifier.save(AndroidWidgetUpdateInterval.every6Hours),
        isTrue,
      );
      expect(
        container
            .read(androidWidgetUpdateIntervalProvider)
            .requireValue
            .interval,
        AndroidWidgetUpdateInterval.every6Hours,
      );
      verify(
        updateIntervalUsecase.execute(AndroidWidgetUpdateInterval.every6Hours),
      ).called(2);
    });
  });

  group('androidWidgetTargetGroupProvider', () {
    test('メンバーごとに候補と選択中IDの取得状態を分離する', () async {
      when(getGroupsUsecase.execute(member)).thenAnswer((_) async => [groupA]);
      when(
        getGroupsUsecase.execute(secondMember),
      ).thenAnswer((_) async => [groupB]);
      when(cacheStorage.getTargetGroupId()).thenAnswer((_) async => 'group-a');
      final firstProvider = androidWidgetTargetGroupProvider(member);
      final secondProvider = androidWidgetTargetGroupProvider(secondMember);
      final firstSubscription = container.listen(firstProvider, (_, _) {});
      final secondSubscription = container.listen(secondProvider, (_, _) {});
      addTearDown(firstSubscription.close);
      addTearDown(secondSubscription.close);

      final firstState = await container.read(firstProvider.future);
      final secondState = await container.read(secondProvider.future);

      expect(firstState.groups, [groupA]);
      expect(firstState.selectedGroupId, 'group-a');
      expect(secondState.groups, [groupB]);
      expect(secondState.selectedGroupId, isNull);
    });

    test('初期取得失敗後にProviderを再構築して再試行できる', () async {
      when(getGroupsUsecase.execute(member)).thenThrow(TestException('取得失敗'));
      when(cacheStorage.getTargetGroupId()).thenAnswer((_) async => 'group-a');
      final provider = androidWidgetTargetGroupProvider(member);
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);

      await expectLater(
        container.read(provider.future),
        throwsA(isA<TestException>()),
      );

      when(getGroupsUsecase.execute(member)).thenAnswer((_) async => [groupA]);
      container.invalidate(provider);

      final state = await container.read(provider.future);
      expect(state.groups, [groupA]);
      expect(state.selectedGroupId, 'group-a');
      verify(getGroupsUsecase.execute(member)).called(2);
    });

    test('選択と解除の成功後に同じProviderへ結果を反映する', () async {
      when(
        getGroupsUsecase.execute(member),
      ).thenAnswer((_) async => [groupA, groupB]);
      when(cacheStorage.getTargetGroupId()).thenAnswer((_) async => 'group-a');
      when(
        selectTargetGroupUsecase.execute('group-b'),
      ).thenAnswer((_) async {});
      when(clearTargetGroupUsecase.execute()).thenAnswer((_) async {});
      final provider = androidWidgetTargetGroupProvider(member);
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      await container.read(provider.future);
      final notifier = container.read(provider.notifier);

      expect(await notifier.select('group-b'), isTrue);
      expect(container.read(provider).requireValue.selectedGroupId, 'group-b');

      expect(await notifier.select(null), isTrue);
      expect(container.read(provider).requireValue.selectedGroupId, isNull);
      verify(selectTargetGroupUsecase.execute('group-b')).called(1);
      verify(clearTargetGroupUsecase.execute()).called(1);
    });

    test('選択失敗時は表示値を維持し、同じ操作を再試行できる', () async {
      when(
        getGroupsUsecase.execute(member),
      ).thenAnswer((_) async => [groupA, groupB]);
      when(cacheStorage.getTargetGroupId()).thenAnswer((_) async => 'group-a');
      when(
        selectTargetGroupUsecase.execute('group-b'),
      ).thenThrow(TestException('保存失敗'));
      final provider = androidWidgetTargetGroupProvider(member);
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      await container.read(provider.future);
      final notifier = container.read(provider.notifier);

      await expectLater(
        notifier.select('group-b'),
        throwsA(isA<TestException>()),
      );
      expect(container.read(provider).requireValue.selectedGroupId, 'group-a');

      when(
        selectTargetGroupUsecase.execute('group-b'),
      ).thenAnswer((_) async {});
      expect(await notifier.select('group-b'), isTrue);
      expect(container.read(provider).requireValue.selectedGroupId, 'group-b');
      verify(selectTargetGroupUsecase.execute('group-b')).called(2);
    });

    test('選択中は逆順の解除を受け付けず古い結果で表示を上書きしない', () async {
      when(
        getGroupsUsecase.execute(member),
      ).thenAnswer((_) async => [groupA, groupB]);
      when(cacheStorage.getTargetGroupId()).thenAnswer((_) async => 'group-a');
      final completer = Completer<void>();
      when(
        selectTargetGroupUsecase.execute('group-b'),
      ).thenAnswer((_) => completer.future);
      final provider = androidWidgetTargetGroupProvider(member);
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      await container.read(provider.future);
      final notifier = container.read(provider.notifier);

      final selectFuture = notifier.select('group-b');
      await container.pump();
      final clearResult = await notifier.select(null);

      expect(clearResult, isFalse);
      expect(container.read(provider).value?.selectedGroupId, 'group-a');
      verifyNever(clearTargetGroupUsecase.execute());

      completer.complete();
      expect(await selectFuture, isTrue);
      expect(container.read(provider).requireValue.selectedGroupId, 'group-b');
    });
  });
}
