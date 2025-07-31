import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/domain/repositories/trip_entry_repository.dart';
import 'package:memora/presentation/widgets/trip_management.dart';

import 'trip_management_test.mocks.dart';

@GenerateMocks([TripEntryRepository])
void main() {
  group('TripManagement', () {
    const testGroupId = 'test-group-id';
    const testYear = 2025;

    testWidgets('ウィジェットが正しく表示される', (WidgetTester tester) async {
      final mockRepository = MockTripEntryRepository();
      when(
        mockRepository.getTripEntriesByGroupIdAndYear(testGroupId, testYear),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripManagement(
              groupId: testGroupId,
              year: testYear,
              onBackPressed: null,
              tripEntryRepository: mockRepository,
            ),
          ),
        ),
      );

      // ローディング完了まで待機
      await tester.pumpAndSettle();

      // タイトルが正しく表示されることを確認
      expect(find.text('$testYear年の旅行管理'), findsOneWidget);

      // 戻るボタンは表示されない（onBackPressedがnullのため）
      expect(find.byIcon(Icons.arrow_back), findsNothing);

      // 旅行追加ボタンが表示されることを確認
      expect(find.text('旅行追加'), findsOneWidget);

      // 空状態メッセージが表示されることを確認
      expect(find.text('この年の旅行はまだありません'), findsOneWidget);
    });

    testWidgets('旅行追加ボタンをタップするとTripEditModalが表示される', (
      WidgetTester tester,
    ) async {
      final mockRepository = MockTripEntryRepository();
      when(
        mockRepository.getTripEntriesByGroupIdAndYear(testGroupId, testYear),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripManagement(
              groupId: testGroupId,
              year: testYear,
              onBackPressed: null,
              tripEntryRepository: mockRepository,
            ),
          ),
        ),
      );

      // ローディング完了まで待機
      await tester.pumpAndSettle();

      // 旅行追加ボタンをタップ
      await tester.tap(find.text('旅行追加'));
      await tester.pumpAndSettle();

      // TripEditModalが表示されることを確認
      expect(find.text('旅行新規作成'), findsOneWidget);
    });

    testWidgets('戻るボタンをタップするとonBackPressedが呼ばれる', (WidgetTester tester) async {
      bool backPressed = false;
      final mockRepository = MockTripEntryRepository();
      when(
        mockRepository.getTripEntriesByGroupIdAndYear(testGroupId, testYear),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripManagement(
              groupId: testGroupId,
              year: testYear,
              onBackPressed: () {
                backPressed = true;
              },
              tripEntryRepository: mockRepository,
            ),
          ),
        ),
      );

      // ローディング完了まで待機
      await tester.pumpAndSettle();

      // 戻るボタンをタップ
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      // onBackPressedが呼ばれたことを確認
      expect(backPressed, isTrue);
    });

    testWidgets('旅行新規作成時にCreateTripEntryUsecaseが呼ばれること', (
      WidgetTester tester,
    ) async {
      final mockRepository = MockTripEntryRepository();

      // モックの設定：getTripEntriesByGroupIdAndYearは空リストを返す
      when(
        mockRepository.getTripEntriesByGroupIdAndYear(testGroupId, testYear),
      ).thenAnswer((_) async => []);
      // saveTripEntryは成功する
      when(mockRepository.saveTripEntry(any)).thenAnswer((_) async => {});

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripManagement(
              groupId: testGroupId,
              year: testYear,
              tripEntryRepository: mockRepository,
            ),
          ),
        ),
      );

      // ローディング完了まで待機
      await tester.pumpAndSettle();

      // 旅行追加ボタンをタップ
      await tester.tap(find.text('旅行追加'));
      await tester.pumpAndSettle();

      // モーダル内で旅行名を入力
      await tester.enterText(find.byType(TextFormField).first, 'テスト旅行');

      // 作成ボタンをタップ
      await tester.tap(find.text('作成'));
      await tester.pumpAndSettle();

      // CreateTripEntryUsecaseが呼ばれたことを確認
      verify(mockRepository.saveTripEntry(any)).called(1);
    });
  });
}
