import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/repositories/group_repository.dart';
import 'package:memora/presentation/widgets/group_settings.dart';

import 'group_settings_test.mocks.dart';

@GenerateMocks([GroupRepository])
void main() {
  late MockGroupRepository mockGroupRepository;
  late Member testMember;

  setUp(() {
    mockGroupRepository = MockGroupRepository();
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

  group('GroupSettings', () {
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

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: GroupSettings(
            member: testMember,
            groupRepository: mockGroupRepository,
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
      expect(find.text('グループ設定'), findsOneWidget);
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
          home: GroupSettings(
            member: testMember,
            groupRepository: mockGroupRepository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('管理しているグループがありません'), findsOneWidget);
      expect(find.text('グループを追加してください'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('グループ追加ボタンが表示されること', (WidgetTester tester) async {
      // Arrange
      when(
        mockGroupRepository.getGroupsByAdministratorId(testMember.id),
      ).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: GroupSettings(
            member: testMember,
            groupRepository: mockGroupRepository,
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
            body: GroupSettings(
              member: testMember,
              groupRepository: mockGroupRepository,
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

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: GroupSettings(
            member: testMember,
            groupRepository: mockGroupRepository,
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

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: GroupSettings(
            member: testMember,
            groupRepository: mockGroupRepository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });
  });
}
