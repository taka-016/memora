import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/queries/group/group_query_service.dart';
import 'package:memora/application/queries/trip/trip_entry_query_service.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/presentation/features/trip/trip_management.dart';
import '../../../../helpers/test_exception.dart';

import 'trip_management_test.mocks.dart';

@GenerateMocks([TripEntryRepository, TripEntryQueryService, GroupQueryService])
void main() {
  late MockTripEntryRepository mockTripEntryRepository;
  late MockTripEntryQueryService mockTripEntryQueryService;
  late MockGroupQueryService mockGroupQueryService;
  late List<TripEntryDto> testTripEntries;
  late PinDto testPin;
  late TripEntryDto detailedTripEntry;
  late List<GroupMemberDto> testGroupMembers;
  late GroupDto testGroup;
  const testGroupId = 'test-group-id';
  const testYear = 2025;

  setUp(() {
    mockTripEntryRepository = MockTripEntryRepository();
    mockTripEntryQueryService = MockTripEntryQueryService();
    mockGroupQueryService = MockGroupQueryService();

    testGroupMembers = [
      GroupMemberDto(
        memberId: 'member-1',
        groupId: testGroupId,
        displayName: '太郎',
        email: 'taro@example.com',
      ),
      GroupMemberDto(
        memberId: 'member-2',
        groupId: testGroupId,
        displayName: '花子',
        email: 'hanako@example.com',
      ),
    ];

    testGroup = GroupDto(
      id: testGroupId,
      ownerId: 'owner-1',
      name: 'テストグループ',
      members: testGroupMembers,
    );

    // デフォルトのグループメンバー取得モック設定
    when(
      mockGroupQueryService.getGroupWithMembersById(
        testGroupId,
        membersOrderBy: anyNamed('membersOrderBy'),
      ),
    ).thenAnswer((_) async => testGroup);

    testPin = PinDto(
      pinId: 'pin-1',
      tripId: 'trip-1',
      groupId: 'test-group-id',
      latitude: 43.06417,
      longitude: 141.34694,
      locationName: '札幌駅',
      visitStartDate: DateTime(2025, 7, 1, 9),
      visitEndDate: DateTime(2025, 7, 1, 12),
      visitMemo: '待ち合わせ',
    );

    testTripEntries = [
      TripEntryDto(
        id: 'trip-1',
        groupId: 'test-group-id',
        tripYear: testYear,
        tripName: '北海道旅行',
        tripStartDate: DateTime(2025, 7, 1),
        tripEndDate: DateTime(2025, 7, 5),
        tripMemo: '夏の北海道を楽しむ',
        pins: [testPin],
      ),
      TripEntryDto(
        id: 'trip-2',
        groupId: 'test-group-id',
        tripYear: testYear,
        tripName: '沖縄旅行',
        tripStartDate: DateTime(2025, 9, 15),
        tripEndDate: DateTime(2025, 9, 18),
        tripMemo: null,
        pins: [],
      ),
    ];

    detailedTripEntry = testTripEntries.first;
  });

  Widget createApp({
    required Widget home,
    TripEntryRepository? tripEntryRepository,
    TripEntryQueryService? tripEntryQueryService,
    GroupQueryService? groupQueryService,
  }) {
    return ProviderScope(
      overrides: [
        tripEntryRepositoryProvider.overrideWithValue(
          tripEntryRepository ?? mockTripEntryRepository,
        ),
        tripEntryQueryServiceProvider.overrideWithValue(
          tripEntryQueryService ?? mockTripEntryQueryService,
        ),
        groupQueryServiceProvider.overrideWithValue(
          groupQueryService ?? mockGroupQueryService,
        ),
      ],
      child: MaterialApp(home: home),
    );
  }

  group('TripManagement', () {
    testWidgets('初期化時に旅行リストが読み込まれること', (WidgetTester tester) async {
      // Arrange
      when(
        mockTripEntryQueryService.getTripEntriesByGroupIdAndYear(
          testGroupId,
          testYear,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => testTripEntries);
      // Act
      await tester.pumpWidget(
        createApp(
          home: Scaffold(
            body: TripManagement(
              groupId: testGroupId,
              year: testYear,
              onBackPressed: null,
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      // 初期ローディング状態を確認
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // ローディング完了まで待機
      await tester.pumpAndSettle();

      // Assert - データ取得の確認
      verify(
        mockTripEntryQueryService.getTripEntriesByGroupIdAndYear(
          testGroupId,
          testYear,
          orderBy: anyNamed('orderBy'),
        ),
      ).called(1);

      expect(find.text('$testYear年の旅行管理'), findsOneWidget);
      expect(find.text('旅行追加'), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(2)); // 2つの旅行が表示

      // 1つ目の旅行の確認
      expect(find.text('北海道旅行'), findsOneWidget);

      // 2つ目の旅行の確認
      expect(find.text('沖縄旅行'), findsOneWidget);
      expect(find.text('2025/07/01 - 2025/07/05'), findsOneWidget);
      expect(find.text('2025/09/15 - 2025/09/18'), findsOneWidget);
    });

    testWidgets('旅行がない場合でも画面が表示されること', (WidgetTester tester) async {
      // Arrange
      when(
        mockTripEntryQueryService.getTripEntriesByGroupIdAndYear(
          testGroupId,
          testYear,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => []);
      // Act
      await tester.pumpWidget(
        createApp(
          home: Scaffold(
            body: TripManagement(
              groupId: testGroupId,
              year: testYear,
              onBackPressed: null,
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('$testYear年の旅行管理'), findsOneWidget);
      expect(find.text('旅行追加'), findsOneWidget);
      expect(find.text('この年の旅行はまだありません'), findsOneWidget);
      expect(
        find.byIcon(Icons.arrow_back),
        findsNothing,
      ); // onBackPressedがnullのため
    });

    testWidgets('旅行追加ボタンが表示されること', (WidgetTester tester) async {
      // Arrange
      when(
        mockTripEntryQueryService.getTripEntriesByGroupIdAndYear(
          testGroupId,
          testYear,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => []);
      // Act
      await tester.pumpWidget(
        createApp(
          home: Scaffold(
            body: TripManagement(
              groupId: testGroupId,
              year: testYear,
              onBackPressed: null,
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('旅行追加'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('データ読み込みエラー時にスナックバーが表示されること', (WidgetTester tester) async {
      // Arrange
      when(
        mockTripEntryQueryService.getTripEntriesByGroupIdAndYear(
          testGroupId,
          testYear,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenThrow(TestException('Network error'));

      // Act
      await tester.pumpWidget(
        createApp(
          home: Scaffold(
            body: TripManagement(
              groupId: testGroupId,
              year: testYear,
              onBackPressed: null,
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text('旅行一覧の読み込みに失敗しました: TestException: Network error'),
        findsOneWidget,
      );
    });

    testWidgets('リフレッシュ機能が動作すること', (WidgetTester tester) async {
      // Arrange
      when(
        mockTripEntryQueryService.getTripEntriesByGroupIdAndYear(
          testGroupId,
          testYear,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => testTripEntries);
      // Act
      await tester.pumpWidget(
        createApp(
          home: Scaffold(
            body: TripManagement(
              groupId: testGroupId,
              year: testYear,
              onBackPressed: null,
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // リフレッシュ実行
      await tester.fling(
        find.byType(RefreshIndicator),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      // Assert
      verify(
        mockTripEntryQueryService.getTripEntriesByGroupIdAndYear(
          testGroupId,
          testYear,
          orderBy: anyNamed('orderBy'),
        ),
      ).called(2); // 初期ロード + リフレッシュ
    });

    testWidgets('行タップで編集画面に遷移すること', (WidgetTester tester) async {
      // Arrange
      when(
        mockTripEntryQueryService.getTripEntriesByGroupIdAndYear(
          testGroupId,
          testYear,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => testTripEntries);
      when(
        mockTripEntryQueryService.getTripEntryById(
          'trip-1',
          pinsOrderBy: anyNamed('pinsOrderBy'),
          pinDetailsOrderBy: anyNamed('pinDetailsOrderBy'),
          tasksOrderBy: anyNamed('tasksOrderBy'),
        ),
      ).thenAnswer((_) async => detailedTripEntry);
      // Act
      await tester.pumpWidget(
        createApp(
          home: TripManagement(
            groupId: testGroupId,
            year: testYear,
            onBackPressed: null,
            isTestEnvironment: true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // タップ前は編集モーダルが表示されていないことを確認
      expect(find.text('旅行編集'), findsNothing);

      // 最初の旅行項目をタップ
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      // 編集モーダルが開いていることを確認
      expect(find.text('旅行編集'), findsOneWidget);
      expect(find.text('北海道旅行'), findsAtLeastNWidgets(1)); // モーダル内にも表示される
      expect(find.text('札幌駅'), findsOneWidget);

      verify(
        mockTripEntryQueryService.getTripEntryById(
          'trip-1',
          pinsOrderBy: anyNamed('pinsOrderBy'),
          pinDetailsOrderBy: anyNamed('pinDetailsOrderBy'),
          tasksOrderBy: anyNamed('tasksOrderBy'),
        ),
      ).called(1);
    });

    testWidgets('旅行詳細取得に失敗した場合にスナックバーが表示されること', (WidgetTester tester) async {
      // Arrange
      when(
        mockTripEntryQueryService.getTripEntriesByGroupIdAndYear(
          testGroupId,
          testYear,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => testTripEntries);
      when(
        mockTripEntryQueryService.getTripEntryById(
          'trip-1',
          pinsOrderBy: anyNamed('pinsOrderBy'),
          pinDetailsOrderBy: anyNamed('pinDetailsOrderBy'),
          tasksOrderBy: anyNamed('tasksOrderBy'),
        ),
      ).thenAnswer((_) async => null);

      // Act
      await tester.pumpWidget(
        createApp(
          home: Scaffold(
            body: TripManagement(
              groupId: testGroupId,
              year: testYear,
              onBackPressed: null,
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('旅行編集'), findsNothing);
      expect(find.text('旅行の詳細取得に失敗しました: データが見つかりませんでした'), findsOneWidget);
      verify(
        mockTripEntryQueryService.getTripEntryById(
          'trip-1',
          pinsOrderBy: anyNamed('pinsOrderBy'),
          pinDetailsOrderBy: anyNamed('pinDetailsOrderBy'),
          tasksOrderBy: anyNamed('tasksOrderBy'),
        ),
      ).called(1);
    });

    testWidgets('旅行情報の更新ができること', (WidgetTester tester) async {
      // Arrange
      when(
        mockTripEntryQueryService.getTripEntriesByGroupIdAndYear(
          testGroupId,
          testYear,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => testTripEntries);
      when(
        mockTripEntryQueryService.getTripEntryById(
          'trip-1',
          pinsOrderBy: anyNamed('pinsOrderBy'),
          pinDetailsOrderBy: anyNamed('pinDetailsOrderBy'),
          tasksOrderBy: anyNamed('tasksOrderBy'),
        ),
      ).thenAnswer((_) async => detailedTripEntry);
      when(
        mockTripEntryRepository.updateTripEntry(any),
      ).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(
        createApp(
          home: Scaffold(
            body: TripManagement(
              groupId: testGroupId,
              year: testYear,
              onBackPressed: null,
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 旅行項目をタップして編集モーダルを開く
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      // 旅行名を変更
      await tester.enterText(
        find.widgetWithText(TextFormField, '北海道旅行'),
        '更新された北海道旅行',
      );

      // 更新ボタンをタップ
      await tester.tap(find.text('更新'));
      await tester.pumpAndSettle();

      // Assert - 更新処理が呼ばれることを確認
      verify(mockTripEntryRepository.updateTripEntry(any)).called(1);
      verify(
        mockTripEntryQueryService.getTripEntryById(
          'trip-1',
          pinsOrderBy: anyNamed('pinsOrderBy'),
          pinDetailsOrderBy: anyNamed('pinDetailsOrderBy'),
          tasksOrderBy: anyNamed('tasksOrderBy'),
        ),
      ).called(1);
    });

    testWidgets('削除ボタンが表示されること', (WidgetTester tester) async {
      // Arrange
      when(
        mockTripEntryQueryService.getTripEntriesByGroupIdAndYear(
          testGroupId,
          testYear,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => testTripEntries);
      // Act
      await tester.pumpWidget(
        createApp(
          home: TripManagement(
            groupId: testGroupId,
            year: testYear,
            onBackPressed: null,
            isTestEnvironment: true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      final cards = find.byType(Card);
      expect(cards, findsNWidgets(2)); // 2つの旅行カード

      // 各カード内に削除ボタンが存在することを確認
      for (int i = 0; i < testTripEntries.length; i++) {
        final card = cards.at(i);
        expect(
          find.descendant(of: card, matching: find.byIcon(Icons.delete)),
          findsOneWidget,
        );
      }
    });

    testWidgets('削除確認ダイアログが表示されること', (WidgetTester tester) async {
      // Arrange
      when(
        mockTripEntryQueryService.getTripEntriesByGroupIdAndYear(
          testGroupId,
          testYear,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => testTripEntries);
      // Act
      await tester.pumpWidget(
        createApp(
          home: Scaffold(
            body: TripManagement(
              groupId: testGroupId,
              year: testYear,
              onBackPressed: null,
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 削除ボタンをタップ
      await tester.tap(find.byIcon(Icons.delete).first);
      await tester.pumpAndSettle();

      // Assert - 削除確認ダイアログが表示されることを確認
      expect(find.text('旅行削除'), findsOneWidget);
      expect(find.text('「北海道旅行」を削除しますか？'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.text('削除'), findsOneWidget);
    });

    testWidgets('削除実行時にdeleteTripEntryが呼ばれること', (WidgetTester tester) async {
      // Arrange
      when(
        mockTripEntryQueryService.getTripEntriesByGroupIdAndYear(
          testGroupId,
          testYear,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => testTripEntries);
      when(
        mockTripEntryRepository.deleteTripEntry(any),
      ).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(
        createApp(
          home: Scaffold(
            body: TripManagement(
              groupId: testGroupId,
              year: testYear,
              onBackPressed: null,
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 削除ボタンをタップ
      await tester.tap(find.byIcon(Icons.delete).first);
      await tester.pumpAndSettle();

      // 削除確認ダイアログで削除ボタンをタップ
      await tester.tap(find.text('削除'));
      await tester.pumpAndSettle();

      // Assert - 削除処理が呼ばれることを確認
      verify(
        mockTripEntryRepository.deleteTripEntry(testTripEntries.first.id),
      ).called(1);
    });

    testWidgets('戻るボタンをタップするとonBackPressedが呼ばれること', (
      WidgetTester tester,
    ) async {
      // Arrange
      bool backPressed = false;
      when(
        mockTripEntryQueryService.getTripEntriesByGroupIdAndYear(
          testGroupId,
          testYear,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => []);
      // Act
      await tester.pumpWidget(
        createApp(
          home: Scaffold(
            body: TripManagement(
              groupId: testGroupId,
              year: testYear,
              onBackPressed: () {
                backPressed = true;
              },
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 戻るボタンをタップ
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      // Assert
      expect(backPressed, isTrue);
    });

    testWidgets('旅行新規作成時にsaveTripEntryが呼ばれること', (WidgetTester tester) async {
      // Arrange
      when(
        mockTripEntryQueryService.getTripEntriesByGroupIdAndYear(
          testGroupId,
          testYear,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => []);
      when(
        mockTripEntryRepository.saveTripEntry(any),
      ).thenAnswer((_) async => 'generated-id');

      // Act
      await tester.pumpWidget(
        createApp(
          home: Scaffold(
            body: TripManagement(
              groupId: testGroupId,
              year: testYear,
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 旅行追加ボタンをタップ
      await tester.tap(find.text('旅行追加'));
      await tester.pumpAndSettle();

      // モーダル内で旅行名を入力
      await tester.enterText(find.byType(TextFormField).first, 'テスト旅行');

      // 開始日を設定
      await tester.tap(find.text('旅行期間 From'));
      await tester.pumpAndSettle();
      // カレンダーで日付を選択（15日をタップ）
      await tester.tap(find.text('15').last);
      await tester.pumpAndSettle();

      // 終了日を設定
      await tester.tap(find.text('旅行期間 To'));
      await tester.pumpAndSettle();
      // カレンダーで日付を選択（20日をタップ）
      await tester.tap(find.text('20').last);
      await tester.pumpAndSettle();

      // 作成ボタンをタップ
      await tester.tap(find.text('作成'));
      await tester.pumpAndSettle();

      // Assert
      verify(mockTripEntryRepository.saveTripEntry(any)).called(1);
    });

    testWidgets('初期化時にグループメンバーが読み込まれること', (WidgetTester tester) async {
      // Arrange
      when(
        mockTripEntryQueryService.getTripEntriesByGroupIdAndYear(
          testGroupId,
          testYear,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => []);
      // Act
      await tester.pumpWidget(
        createApp(
          home: Scaffold(
            body: TripManagement(
              groupId: testGroupId,
              year: testYear,
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - グループメンバー取得の確認
      verify(
        mockGroupQueryService.getGroupWithMembersById(
          testGroupId,
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).called(1);
    });

    testWidgets('グループメンバー読み込みエラー時にスナックバーが表示されること', (WidgetTester tester) async {
      // Arrange
      when(
        mockTripEntryQueryService.getTripEntriesByGroupIdAndYear(
          testGroupId,
          testYear,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => []);

      when(
        mockGroupQueryService.getGroupWithMembersById(
          testGroupId,
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenThrow(TestException('グループメンバー取得エラー'));

      // Act
      await tester.pumpWidget(
        createApp(
          home: Scaffold(
            body: TripManagement(
              groupId: testGroupId,
              year: testYear,
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - エラーメッセージのスナックバーが表示されること
      expect(find.textContaining('グループメンバーの読み込みに失敗しました'), findsOneWidget);
    });

    testWidgets('グループメンバーが存在しない場合でも正常に動作すること', (WidgetTester tester) async {
      // Arrange
      when(
        mockTripEntryQueryService.getTripEntriesByGroupIdAndYear(
          testGroupId,
          testYear,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => []);

      when(
        mockGroupQueryService.getGroupWithMembersById(
          testGroupId,
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => null);

      // Act
      await tester.pumpWidget(
        createApp(
          home: Scaffold(
            body: TripManagement(
              groupId: testGroupId,
              year: testYear,
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - 画面が正常に表示されること
      expect(find.text('$testYear年の旅行管理'), findsOneWidget);
      expect(find.text('旅行追加'), findsOneWidget);
    });
  });
}
