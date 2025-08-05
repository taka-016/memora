import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/repositories/group_repository.dart';
import 'package:memora/domain/repositories/member_repository.dart';
import 'package:memora/domain/repositories/group_member_repository.dart';
import 'package:memora/domain/repositories/group_event_repository.dart';
import 'package:memora/domain/repositories/trip_entry_repository.dart';
import 'package:memora/presentation/widgets/group_management.dart';

import 'group_management_test.mocks.dart';

@GenerateMocks([
  GroupRepository,
  MemberRepository,
  GroupMemberRepository,
  GroupEventRepository,
  TripEntryRepository,
])
void main() {
  late MockGroupRepository mockGroupRepository;
  late MockMemberRepository mockMemberRepository;
  late MockGroupMemberRepository mockGroupMemberRepository;
  late MockGroupEventRepository mockGroupEventRepository;
  late MockTripEntryRepository mockTripEntryRepository;
  late Member testMember;

  setUp(() {
    mockGroupRepository = MockGroupRepository();
    mockMemberRepository = MockMemberRepository();
    mockGroupMemberRepository = MockGroupMemberRepository();
    mockGroupEventRepository = MockGroupEventRepository();
    mockTripEntryRepository = MockTripEntryRepository();
    testMember = Member(
      id: 'test-member-id',
      accountId: 'test-account-id',
      administratorId: null,
      displayName: 'Test User',
      kanjiLastName: '山田',
      kanjiFirstName: '太郎',
      hiraganaLastName: 'やまだ',
      hiraganaFirstName: 'たろう',
      firstName: 'Taro',
      lastName: 'Yamada',
      gender: '男性',
      birthday: DateTime(1990, 1, 1),
      email: 'test@example.com',
      phoneNumber: '090-1234-5678',
      type: 'member',
      passportNumber: null,
      passportExpiration: null,
      anaMileageNumber: null,
      jalMileageNumber: null,
    );
  });

  group('GroupManagement', () {
    testWidgets('初期化時にグループリストが読み込まれること', (WidgetTester tester) async {
      // Arrange
      final managedGroups = [
        Group(
          id: 'group-1',
          administratorId: testMember.id,
          name: 'Test Group 1',
          memo: 'Test memo 1',
        ),
        Group(
          id: 'group-2',
          administratorId: testMember.id,
          name: 'Test Group 2',
          memo: 'Test memo 2',
        ),
      ];

      when(
        mockGroupRepository.getGroupsByAdministratorId(testMember.id),
      ).thenAnswer((_) async => managedGroups);

      // グループメンバー取得のモック
      when(
        mockGroupMemberRepository.getGroupMembersByGroupId('group-1'),
      ).thenAnswer((_) async => []);
      when(
        mockGroupMemberRepository.getGroupMembersByGroupId('group-2'),
      ).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupManagement(
              member: testMember,
              groupRepository: mockGroupRepository,
              memberRepository: mockMemberRepository,
              groupMemberRepository: mockGroupMemberRepository,
              groupEventRepository: mockGroupEventRepository,
              tripEntryRepository: mockTripEntryRepository,
            ),
          ),
        ),
      );

      // 初期ローディング状態を確認
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // ローディング完了まで待機
      await tester.pumpAndSettle();

      // Assert
      verify(
        mockGroupRepository.getGroupsByAdministratorId(testMember.id),
      ).called(1);
      expect(find.text('グループ管理'), findsOneWidget);
      expect(find.text('Test Group 1'), findsOneWidget);
      expect(find.text('Test Group 2'), findsOneWidget);
      expect(find.text('Test memo 1'), findsOneWidget);
      expect(find.text('Test memo 2'), findsOneWidget);
    });

    testWidgets('管理しているグループがない場合、空状態が表示されること', (WidgetTester tester) async {
      // Arrange
      when(
        mockGroupRepository.getGroupsByAdministratorId(testMember.id),
      ).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupManagement(
              member: testMember,
              groupRepository: mockGroupRepository,
              memberRepository: mockMemberRepository,
              groupMemberRepository: mockGroupMemberRepository,
              groupEventRepository: mockGroupEventRepository,
              tripEntryRepository: mockTripEntryRepository,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ListTile), findsNothing);
      expect(find.text('管理しているグループがありません'), findsOneWidget);
      expect(find.text('グループを追加してください'), findsOneWidget);
    });

    testWidgets('グループ追加ボタンが表示されること', (WidgetTester tester) async {
      // Arrange
      when(
        mockGroupRepository.getGroupsByAdministratorId(testMember.id),
      ).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupManagement(
              member: testMember,
              groupRepository: mockGroupRepository,
              memberRepository: mockMemberRepository,
              groupMemberRepository: mockGroupMemberRepository,
              groupEventRepository: mockGroupEventRepository,
              tripEntryRepository: mockTripEntryRepository,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('グループ追加'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('データ読み込みエラー時にスナックバーが表示されること', (WidgetTester tester) async {
      // Arrange
      when(
        mockGroupRepository.getGroupsByAdministratorId(testMember.id),
      ).thenThrow(Exception('Network error'));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupManagement(
              member: testMember,
              groupRepository: mockGroupRepository,
              memberRepository: mockMemberRepository,
              groupMemberRepository: mockGroupMemberRepository,
              groupEventRepository: mockGroupEventRepository,
              tripEntryRepository: mockTripEntryRepository,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text('データの読み込みに失敗しました: Exception: Network error'),
        findsOneWidget,
      );
    });

    testWidgets('リフレッシュ機能が動作すること', (WidgetTester tester) async {
      // Arrange
      final managedGroups = [
        Group(
          id: 'group-1',
          administratorId: testMember.id,
          name: 'Test Group 1',
          memo: 'Test memo 1',
        ),
      ];

      when(
        mockGroupRepository.getGroupsByAdministratorId(testMember.id),
      ).thenAnswer((_) async => managedGroups);

      // グループメンバー取得のモック
      when(
        mockGroupMemberRepository.getGroupMembersByGroupId('group-1'),
      ).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupManagement(
              member: testMember,
              groupRepository: mockGroupRepository,
              memberRepository: mockMemberRepository,
              groupMemberRepository: mockGroupMemberRepository,
              groupEventRepository: mockGroupEventRepository,
              tripEntryRepository: mockTripEntryRepository,
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
        mockGroupRepository.getGroupsByAdministratorId(testMember.id),
      ).called(2);
    });

    testWidgets('削除ボタンが表示されること', (WidgetTester tester) async {
      // Arrange
      final managedGroups = [
        Group(
          id: 'group-1',
          administratorId: testMember.id,
          name: 'Test Group 1',
          memo: 'Test memo 1',
        ),
      ];

      when(
        mockGroupRepository.getGroupsByAdministratorId(testMember.id),
      ).thenAnswer((_) async => managedGroups);

      // グループメンバー取得のモック
      when(
        mockGroupMemberRepository.getGroupMembersByGroupId('group-1'),
      ).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupManagement(
              member: testMember,
              groupRepository: mockGroupRepository,
              memberRepository: mockMemberRepository,
              groupMemberRepository: mockGroupMemberRepository,
              groupEventRepository: mockGroupEventRepository,
              tripEntryRepository: mockTripEntryRepository,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('グループ一覧の行をタップして編集画面が開けること', (WidgetTester tester) async {
      // Arrange
      final managedGroups = [
        Group(
          id: 'group-1',
          administratorId: testMember.id,
          name: 'Test Group 1',
          memo: 'Test memo 1',
        ),
      ];

      final availableMembers = [testMember];

      when(
        mockGroupRepository.getGroupsByAdministratorId(testMember.id),
      ).thenAnswer((_) async => managedGroups);

      when(
        mockMemberRepository.getMembersByAdministratorId(testMember.id),
      ).thenAnswer((_) async => availableMembers);

      when(
        mockGroupMemberRepository.getGroupMembersByGroupId('group-1'),
      ).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupManagement(
              member: testMember,
              groupRepository: mockGroupRepository,
              memberRepository: mockMemberRepository,
              groupMemberRepository: mockGroupMemberRepository,
              groupEventRepository: mockGroupEventRepository,
              tripEntryRepository: mockTripEntryRepository,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ListTileをタップ
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      // Assert - 編集モーダルが開かれることを期待
      expect(find.text('グループ編集'), findsOneWidget);
    });

    testWidgets('グループ情報の更新ができること', (WidgetTester tester) async {
      // Arrange
      final managedGroups = [
        Group(
          id: 'group-1',
          administratorId: testMember.id,
          name: 'Test Group 1',
          memo: 'Test memo 1',
        ),
      ];

      final availableMembers = [testMember];

      when(
        mockGroupRepository.getGroupsByAdministratorId(testMember.id),
      ).thenAnswer((_) async => managedGroups);

      when(
        mockMemberRepository.getMembersByAdministratorId(testMember.id),
      ).thenAnswer((_) async => availableMembers);

      when(
        mockGroupMemberRepository.getGroupMembersByGroupId('group-1'),
      ).thenAnswer((_) async => []);

      when(mockGroupRepository.updateGroup(any)).thenAnswer((_) async {});

      when(
        mockGroupMemberRepository.deleteGroupMember(any),
      ).thenAnswer((_) async {});

      when(
        mockGroupMemberRepository.saveGroupMember(any),
      ).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupManagement(
              member: testMember,
              groupRepository: mockGroupRepository,
              memberRepository: mockMemberRepository,
              groupMemberRepository: mockGroupMemberRepository,
              groupEventRepository: mockGroupEventRepository,
              tripEntryRepository: mockTripEntryRepository,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ListTileをタップして編集モーダルを開く
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      // グループ名を変更
      await tester.enterText(
        find.widgetWithText(TextFormField, 'グループ名').first,
        'Updated Group Name',
      );

      // 更新ボタンをタップ
      await tester.tap(find.text('更新'));
      await tester.pumpAndSettle();

      // Assert - 更新処理が呼ばれることを確認
      verify(mockGroupRepository.updateGroup(any)).called(1);
    });

    testWidgets('グループメンバーの追加削除ができること', (WidgetTester tester) async {
      // Arrange
      final managedGroups = [
        Group(
          id: 'group-1',
          administratorId: testMember.id,
          name: 'Test Group 1',
          memo: 'Test memo 1',
        ),
      ];

      final availableMembers = [
        testMember,
        Member(
          id: 'member-2',
          accountId: 'account-2',
          administratorId: testMember.id,
          displayName: 'Member 2',
          kanjiLastName: '田中',
          kanjiFirstName: '花子',
          hiraganaLastName: 'たなか',
          hiraganaFirstName: 'はなこ',
          firstName: 'Hanako',
          lastName: 'Tanaka',
          gender: '女性',
          birthday: DateTime(1992, 5, 15),
          email: 'hanako@example.com',
          phoneNumber: '090-8765-4321',
          type: 'member',
          passportNumber: null,
          passportExpiration: null,
          anaMileageNumber: null,
          jalMileageNumber: null,
        ),
      ];

      when(
        mockGroupRepository.getGroupsByAdministratorId(testMember.id),
      ).thenAnswer((_) async => managedGroups);

      when(
        mockMemberRepository.getMembersByAdministratorId(testMember.id),
      ).thenAnswer((_) async => availableMembers);

      when(
        mockGroupMemberRepository.getGroupMembersByGroupId('group-1'),
      ).thenAnswer((_) async => []);

      when(mockGroupRepository.updateGroup(any)).thenAnswer((_) async {});

      when(
        mockGroupMemberRepository.deleteGroupMember(any),
      ).thenAnswer((_) async {});

      when(
        mockGroupMemberRepository.saveGroupMember(any),
      ).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupManagement(
              member: testMember,
              groupRepository: mockGroupRepository,
              memberRepository: mockMemberRepository,
              groupMemberRepository: mockGroupMemberRepository,
              groupEventRepository: mockGroupEventRepository,
              tripEntryRepository: mockTripEntryRepository,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ListTileをタップして編集モーダルを開く
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      // メンバー一覧のコンテナ内をスクロールして2番目のメンバーを表示
      await tester.scrollUntilVisible(
        find.byType(CheckboxListTile).at(1),
        100.0,
        scrollable: find.descendant(
          of: find.byKey(const Key('member_list_container')),
          matching: find.byType(Scrollable),
        ),
      );

      // 2番目のメンバーをチェック
      final secondCheckbox = find.byType(CheckboxListTile).at(1);
      expect(secondCheckbox, findsOneWidget);
      await tester.tap(secondCheckbox);
      await tester.pumpAndSettle();

      // 更新ボタンをタップ
      await tester.tap(find.text('更新'));
      await tester.pumpAndSettle();

      // Assert - メンバー作成処理が呼ばれることを確認
      verify(mockGroupMemberRepository.saveGroupMember(any)).called(1);
    });

    testWidgets('グループ削除時にグループメンバーも削除されること', (WidgetTester tester) async {
      // Arrange
      final managedGroups = [
        Group(
          id: 'group-1',
          administratorId: testMember.id,
          name: 'Test Group 1',
          memo: 'Test memo 1',
        ),
      ];

      when(
        mockGroupRepository.getGroupsByAdministratorId(testMember.id),
      ).thenAnswer((_) async => managedGroups);

      when(
        mockGroupMemberRepository.getGroupMembersByGroupId('group-1'),
      ).thenAnswer((_) async => []);

      when(mockGroupRepository.deleteGroup('group-1')).thenAnswer((_) async {});
      when(
        mockGroupMemberRepository.deleteGroupMembersByGroupId('group-1'),
      ).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupManagement(
              member: testMember,
              groupRepository: mockGroupRepository,
              memberRepository: mockMemberRepository,
              groupMemberRepository: mockGroupMemberRepository,
              groupEventRepository: mockGroupEventRepository,
              tripEntryRepository: mockTripEntryRepository,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 削除ボタンをタップ
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // 確認ダイアログで削除ボタンをタップ
      await tester.tap(find.text('削除'));
      await tester.pumpAndSettle();

      // Assert - グループメンバー削除処理が呼ばれることを確認
      verify(
        mockGroupMemberRepository.deleteGroupMembersByGroupId('group-1'),
      ).called(1);
      verify(mockGroupRepository.deleteGroup('group-1')).called(1);
    });

    testWidgets('グループ削除時にエラーが発生した場合、エラーメッセージが表示されること', (
      WidgetTester tester,
    ) async {
      // Arrange
      final managedGroups = [
        Group(
          id: 'group-1',
          administratorId: testMember.id,
          name: 'Test Group 1',
          memo: 'Test memo 1',
        ),
      ];

      when(
        mockGroupRepository.getGroupsByAdministratorId(testMember.id),
      ).thenAnswer((_) async => managedGroups);

      when(
        mockGroupMemberRepository.getGroupMembersByGroupId('group-1'),
      ).thenAnswer((_) async => []);

      // グループメンバー削除は成功するが、グループ削除でエラーが発生
      when(
        mockGroupMemberRepository.deleteGroupMembersByGroupId('group-1'),
      ).thenAnswer((_) async {});
      when(
        mockGroupRepository.deleteGroup('group-1'),
      ).thenThrow(Exception('削除エラー'));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupManagement(
              member: testMember,
              groupRepository: mockGroupRepository,
              memberRepository: mockMemberRepository,
              groupMemberRepository: mockGroupMemberRepository,
              groupEventRepository: mockGroupEventRepository,
              tripEntryRepository: mockTripEntryRepository,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 削除ボタンをタップ
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // 確認ダイアログで削除ボタンをタップ
      await tester.tap(find.text('削除'));
      await tester.pumpAndSettle();

      // Assert - エラーメッセージが表示されることを確認
      expect(find.text('削除に失敗しました: Exception: 削除エラー'), findsOneWidget);
    });
  });
}
