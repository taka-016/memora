import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/shared/inputs/custom_search_bar.dart';
import 'package:memora/domain/interfaces/location_search_service.dart';
import 'package:memora/domain/value_objects/location_candidate.dart';
import 'package:memora/domain/value_objects/location.dart';

class MockLocationSearchService implements LocationSearchService {
  List<LocationCandidate> candidates;
  MockLocationSearchService(this.candidates);
  @override
  Future<List<LocationCandidate>> searchByKeyword(String keyword) async {
    return candidates;
  }
}

// 共通で使う候補リスト
const mockCandidatesDefault = [
  LocationCandidate(
    name: '東京タワー',
    address: '東京都港区芝公園4-2-8',
    location: Location(latitude: 35.6586, longitude: 139.7454),
  ),
  LocationCandidate(
    name: 'スカイツリー',
    address: '東京都墨田区押上1-1-2',
    location: Location(latitude: 35.7101, longitude: 139.8107),
  ),
];

void main() {
  group('CustomSearchBar', () {
    testWidgets('検索バーが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CustomSearchBar(hintText: '場所を検索')),
        ),
      );
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('場所を検索'), findsOneWidget);
    });

    testWidgets('エンターキー送信で候補リストが表示され、タップでコールバックが呼ばれる', (
      WidgetTester tester,
    ) async {
      final mockCandidates = mockCandidatesDefault;
      LocationCandidate? tappedCandidate;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomSearchBar(
              hintText: '場所を検索',
              locationSearchService: MockLocationSearchService(mockCandidates),
              onCandidateSelected: (candidate) {
                tappedCandidate = candidate;
              },
            ),
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
        MaterialApp(
          home: Scaffold(
            body: CustomSearchBar(hintText: '場所を検索', controller: controller),
          ),
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
        MaterialApp(
          home: Scaffold(
            body: CustomSearchBar(
              hintText: '場所を検索',
              locationSearchService: MockLocationSearchService(mockCandidates),
            ),
          ),
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
