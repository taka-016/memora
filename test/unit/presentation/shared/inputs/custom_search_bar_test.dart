import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/application/usecases/location/search_locations_usecase.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/presentation/shared/inputs/custom_search_bar.dart';

class FakeSearchLocationsUsecase implements SearchLocationsUsecase {
  FakeSearchLocationsUsecase(this.candidates);

  final List<LocationCandidateDto> candidates;

  @override
  Future<List<LocationCandidateDto>> execute(String keyword) async {
    return candidates;
  }
}

// 共通で使う候補リスト
final mockCandidatesDefault = [
  LocationCandidateDto(
    name: '東京タワー',
    address: '東京都港区芝公園4-2-8',
    coordinate: Coordinate(latitude: 35.6586, longitude: 139.7454),
  ),
  LocationCandidateDto(
    name: 'スカイツリー',
    address: '東京都墨田区押上1-1-2',
    coordinate: Coordinate(latitude: 35.7101, longitude: 139.8107),
  ),
];

Widget buildTestApp({
  required Widget child,
  SearchLocationsUsecase? searchLocationsUsecase,
}) {
  return ProviderScope(
    overrides: [
      searchLocationsUsecaseProvider.overrideWithValue(
        searchLocationsUsecase ?? FakeSearchLocationsUsecase(const []),
      ),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('CustomSearchBar', () {
    testWidgets('検索バーが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(child: const CustomSearchBar(hintText: '場所を検索')),
      );
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('場所を検索'), findsOneWidget);
    });

    testWidgets('エンターキー送信で候補リストが表示され、タップでコールバックが呼ばれる', (
      WidgetTester tester,
    ) async {
      final mockCandidates = mockCandidatesDefault;
      LocationCandidateDto? tappedCandidate;
      await tester.pumpWidget(
        buildTestApp(
          searchLocationsUsecase: FakeSearchLocationsUsecase(mockCandidates),
          child: CustomSearchBar(
            hintText: '場所を検索',
            onCandidateSelected: (candidate) {
              tappedCandidate = candidate;
            },
          ),
        ),
      );
      // テキスト入力
      await tester.enterText(find.byType(TextField), '東京');
      // エンターキー送信
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      // 候補リストが表示される
      expect(find.text('東京タワー'), findsOneWidget);
      expect(find.text('スカイツリー'), findsOneWidget);
      // リストの1つをタップ
      await tester.tap(find.text('東京タワー'));
      await tester.pumpAndSettle();
      // コールバックが呼ばれたか
      expect(tappedCandidate?.name, '東京タワー');
    });

    testWidgets('検索バー右端の×ボタンで入力値がクリアされる', (WidgetTester tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        buildTestApp(
          child: CustomSearchBar(hintText: '場所を検索', controller: controller),
        ),
      );
      await tester.enterText(find.byType(TextField), 'テスト');
      await tester.pump();
      expect(controller.text, 'テスト');
      // ×ボタンをタップ
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();
      expect(controller.text, '');
    });

    testWidgets('候補リストの項目をタップしたらリストが閉じる', (WidgetTester tester) async {
      final mockCandidates = mockCandidatesDefault;
      await tester.pumpWidget(
        buildTestApp(
          searchLocationsUsecase: FakeSearchLocationsUsecase(mockCandidates),
          child: const CustomSearchBar(hintText: '場所を検索'),
        ),
      );
      await tester.enterText(find.byType(TextField), '東京');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      // 候補リストが表示されていることを確認
      expect(find.text('東京タワー'), findsOneWidget);
      // 候補をタップ
      await tester.tap(find.text('東京タワー'));
      await tester.pumpAndSettle();
      // タップ後、候補リストが非表示になっていることを確認
      expect(find.text('東京タワー'), findsNothing);
      expect(find.text('スカイツリー'), findsNothing);
    });
  });
}
