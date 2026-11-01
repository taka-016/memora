import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/application/models/app_capabilities.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:memora/composition_root/providers/location_providers.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/presentation/features/calendar/calendar_location_field.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import '../../shared/inputs/custom_search_bar_test.mocks.dart';

void main() {
  late MockSearchLocationsUsecase search;
  late TextEditingController controller;
  final candidates = [
    LocationCandidateDto(
      name: '東京タワー',
      address: '東京都港区',
      coordinate: Coordinate(latitude: 35, longitude: 139),
    ),
  ];
  setUp(() {
    search = MockSearchLocationsUsecase();
    controller = TextEditingController();
  });
  tearDown(() => controller.dispose());

  Future<void> pumpField(
    WidgetTester tester, {
    bool offline = false,
    bool enabled = true,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appCapabilitiesProvider.overrideWithValue(
            AppCapabilities.forMode(offline ? AppMode.offline : AppMode.online),
          ),
          searchLocationsUsecaseProvider.overrideWithValue(search),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CalendarLocationField(
                controller: controller,
                enabled: enabled,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.pump();
    await tester.tap(find.byTooltip('場所を検索'));
    await tester.pump();
  }

  testWidgets('検索しても入力値を保持し候補を選んだ場合だけ名称へ置換する', (tester) async {
    when(search.execute('東京')).thenAnswer((_) async => candidates);
    await pumpField(tester);
    await tester.enterText(find.byType(TextField), '東京');
    await submit(tester);
    expect(controller.text, '東京');
    await tester.tap(find.text('東京タワー'));
    await tester.pump();
    expect(controller.text, '東京タワー');
    expect(find.text('東京都港区'), findsNothing);
    await tester.enterText(find.byType(TextField), '東京タワー入口');
    expect(controller.text, '東京タワー入口');
    verify(search.execute('東京')).called(1);
  });

  testWidgets('検索中・0件・失敗を区別し再検索できる', (tester) async {
    final pending = Completer<List<LocationCandidateDto>>();
    when(search.execute(any)).thenAnswer((_) => pending.future);
    await pumpField(tester);
    await tester.enterText(find.byType(TextField), '駅');
    await submit(tester);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    pending.complete([]);
    await tester.pump();
    expect(find.text('検索結果がありません'), findsOneWidget);
    when(search.execute(any)).thenThrow(TestException('検索失敗'));
    await submit(tester);
    expect(find.text('場所を検索できませんでした。再検索してください'), findsOneWidget);
    expect(find.text('検索結果がありません'), findsNothing);
    when(search.execute(any)).thenAnswer((_) async => candidates);
    await submit(tester);
    expect(find.text('東京タワー'), findsOneWidget);
    expect(find.text('場所を検索できませんでした。再検索してください'), findsNothing);
    expect(controller.text, '駅');
  });

  testWidgets('検索中に入力を変えた場合は古い候補を表示しない', (tester) async {
    final pending = Completer<List<LocationCandidateDto>>();
    when(search.execute(any)).thenAnswer((_) => pending.future);
    await pumpField(tester);
    await tester.enterText(find.byType(TextField), '東京');
    await submit(tester);
    await tester.enterText(find.byType(TextField), '京都');
    pending.complete(candidates);
    await tester.pump();
    expect(find.text('東京タワー'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(controller.text, '京都');
  });

  testWidgets('検索中に画面を閉じても遅延完了で例外を出さない', (tester) async {
    final pending = Completer<List<LocationCandidateDto>>();
    when(search.execute(any)).thenAnswer((_) => pending.future);
    await pumpField(tester);
    await tester.enterText(find.byType(TextField), '東京');
    await submit(tester);
    await tester.pumpWidget(const SizedBox());
    pending.complete(candidates);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('オフラインでは検索せず場所名を手入力・解除できる', (tester) async {
    await pumpField(tester, offline: true);
    expect(find.byTooltip('場所を検索'), findsNothing);
    await tester.enterText(find.byType(TextField), '集合場所');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(controller.text, '集合場所');
    await tester.enterText(find.byType(TextField), '');
    expect(controller.text, '');
    verifyZeroInteractions(search);
  });
}
