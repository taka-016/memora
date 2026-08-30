part of 'top_page_test_support.dart';

extension TopPageAuthenticationTests on TopPageTestContext {
  void registerAuthenticationTests() {
    testWidgets('同じユーザーで再ログインした場合はグループ一覧を再取得する', (WidgetTester tester) async {
      const user = UserDto(
        id: 'test_user_id',
        loginId: 'test@example.com',
        isVerified: true,
      );
      final authNotifier = _MutableAuthNotifier(
        const AuthState.authenticated(user),
      );
      await tester.pumpWidget(
        createTestWidget(authNotifier: authNotifier, currentMember: testMember),
      );
      await tester.pumpAndSettle();

      authNotifier.unauthenticate();
      await tester.pumpAndSettle();

      authNotifier.authenticate(user);
      await tester.pumpAndSettle();

      verify(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          testMember.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).called(2);
    });
    testWidgets('_currentMember取得でエラーになった場合、SnackBarでエラーを表示してログアウトする', (
      WidgetTester tester,
    ) async {
      // Arrange
      const testUser = UserDto(
        id: 'test_user_id',
        loginId: 'test@example.com',
        isVerified: true,
      );

      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          any,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => groupsWithMembers);

      final fakeAuthNotifier = FakeAuthNotifier(
        const AuthState.authenticated(testUser),
      );
      final widget = createTestWidget(
        memberQueryService: mockMemberQueryService,
        authService: mockAuthService,
        authNotifier: fakeAuthNotifier,
        currentMemberNotifier: FakeCurrentMemberNotifier.error(
          'メンバー情報の取得に失敗しました。再度ログインしてください。',
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump();
      await tester.pump();

      // Assert
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('メンバー情報の取得に失敗しました。再度ログインしてください。'), findsOneWidget);
      expect(fakeAuthNotifier.logoutCalled, isTrue);
    });
  }
}
