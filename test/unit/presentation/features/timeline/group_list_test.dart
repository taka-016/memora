import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_with_members_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/domain/value_objects/order_by.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/interfaces/group_query_service.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/presentation/features/timeline/group_list.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../helpers/test_exception.dart';

import 'group_list_test.mocks.dart';

@GenerateMocks([GroupQueryService])
void main() {
  late MockGroupQueryService mockGroupQueryService;
  late Member testMember;
  late MemberDto testMemberDto;

  setUp(() {
    mockGroupQueryService = MockGroupQueryService();
    testMember = Member(
      id: 'admin1',
      hiraganaFirstName: 'たろう',
      hiraganaLastName: 'やまだ',
      kanjiFirstName: '太郎',
      kanjiLastName: '山田',
      firstName: 'Taro',
      lastName: 'Yamada',
      displayName: 'タロちゃん',
      type: 'family',
      birthday: DateTime(1990, 1, 1),
      gender: 'male',
    );
    testMemberDto = MemberDto(
      id: 'admin1',
      displayName: 'タロちゃん',
      email: 'taro@example.com',
    );
  });

  Widget createTestWidget({Member? member}) {
    return ProviderScope(
      overrides: [
        groupQueryServiceProvider.overrideWithValue(mockGroupQueryService),
      ],
      child: MaterialApp(
        home: Scaffold(body: GroupList(member: member ?? testMember)),
      ),
    );
  }

  group('GroupList', () {
    testWidgets('グループ一覧が表示される', (WidgetTester tester) async {
      // Arrange
      final member1 = MemberDto(
        id: 'member1',
        displayName: '田中',
        email: 'tanaka@example.com',
      );
      final member2 = MemberDto(
        id: 'member2',
        displayName: '佐藤',
        email: 'sato@example.com',
      );
      final groupsWithMembers = [
        GroupWithMembersDto(
          groupId: '1',
          groupName: 'グループ1',
          members: [member1],
        ),
        GroupWithMembersDto(
          groupId: '2',
          groupName: 'グループ2',
          members: [member1, member2],
        ),
      ];
      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          testMember.id,
          groupsOrderBy: [const OrderBy('name', descending: false)],
          membersOrderBy: [const OrderBy('displayName', descending: false)],
        ),
      ).thenAnswer((_) async => groupsWithMembers);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('グループ一覧'), findsOneWidget);
      expect(find.text('グループ1'), findsOneWidget);
      expect(find.text('グループ2'), findsOneWidget);
      expect(find.text('1人のメンバー'), findsOneWidget);
      expect(find.text('2人のメンバー'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_ios), findsNWidgets(2));
    });

    testWidgets('グループが存在しない場合、空状態が表示される', (WidgetTester tester) async {
      // Arrange
      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          testMember.id,
          groupsOrderBy: [const OrderBy('name', descending: false)],
          membersOrderBy: [const OrderBy('displayName', descending: false)],
        ),
      ).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('グループがありません'), findsOneWidget);
      expect(find.text('グループを作成'), findsNothing);
    });

    testWidgets('エラーが発生した場合、エラー状態が表示される', (WidgetTester tester) async {
      // Arrange
      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          testMember.id,
          groupsOrderBy: [const OrderBy('name', descending: false)],
          membersOrderBy: [const OrderBy('displayName', descending: false)],
        ),
      ).thenThrow(TestException('エラーテスト'));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('エラーが発生しました'), findsOneWidget);
      expect(find.text('再読み込み'), findsOneWidget);
    });

    testWidgets('エラー状態で再読み込みボタンをタップすると、再度データを読み込む', (
      WidgetTester tester,
    ) async {
      // Arrange
      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          testMember.id,
          groupsOrderBy: [const OrderBy('name', descending: false)],
          membersOrderBy: [const OrderBy('displayName', descending: false)],
        ),
      ).thenThrow(TestException('エラーテスト'));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 正常なデータを返すように変更
      final groupsWithMembers = [
        GroupWithMembersDto(
          groupId: '1',
          groupName: 'テストグループ',
          members: [testMemberDto],
        ),
      ];
      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          testMember.id,
          groupsOrderBy: [const OrderBy('name', descending: false)],
          membersOrderBy: [const OrderBy('displayName', descending: false)],
        ),
      ).thenAnswer((_) async => groupsWithMembers);

      // 再読み込みボタンをタップ
      await tester.tap(find.text('再読み込み'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('グループ一覧'), findsOneWidget);
      expect(find.text('テストグループ'), findsOneWidget);
      expect(find.text('エラーが発生しました'), findsNothing);
      verify(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          testMember.id,
          groupsOrderBy: [const OrderBy('name', descending: false)],
          membersOrderBy: [const OrderBy('displayName', descending: false)],
        ),
      ).called(2); // 最初のエラー + 再読み込み
    });

    testWidgets('グループ行をタップしたときにコールバック関数が呼ばれる', (WidgetTester tester) async {
      // Arrange
      GroupWithMembersDto? selectedGroup;
      final groupsWithMembers = [
        GroupWithMembersDto(
          groupId: '1',
          groupName: 'テストグループ',
          members: [testMemberDto],
        ),
      ];
      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          testMember.id,
          groupsOrderBy: [const OrderBy('name', descending: false)],
          membersOrderBy: [const OrderBy('displayName', descending: false)],
        ),
      ).thenAnswer((_) async => groupsWithMembers);

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupQueryServiceProvider.overrideWithValue(mockGroupQueryService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: GroupList(
                member: testMember,
                onGroupSelected: (groupWithMembers) {
                  selectedGroup = groupWithMembers;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // グループ行をタップ
      await tester.tap(find.text('テストグループ'));
      await tester.pumpAndSettle();

      // Assert
      expect(selectedGroup, isNotNull);
      expect(selectedGroup!.groupId, '1');
      expect(selectedGroup!.groupName, 'テストグループ');
    });
  });
}
