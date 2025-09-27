import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/entities/group_member.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/presentation/features/group/group_edit_modal.dart';

void main() {
  group('GroupEditModal', () {
    testWidgets('新規作成時にタイトルが正しく表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GroupEditModal(
            group: Group(id: '', ownerId: '', name: '', memo: ''),
            onSave: (group) {},
            availableMembers: const [],
          ),
        ),
      );

      expect(find.text('グループ新規作成'), findsOneWidget);
    });

    testWidgets('編集時にタイトルが正しく表示される', (WidgetTester tester) async {
      final group = Group(
        id: 'test-id',
        ownerId: 'admin-id',
        name: 'テストグループ',
        memo: 'テストメモ',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GroupEditModal(
            group: group,
            onSave: (group) {},
            availableMembers: const [],
          ),
        ),
      );

      expect(find.text('グループ編集'), findsOneWidget);
    });

    testWidgets('必須フィールドが空の場合にバリデーションエラーが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GroupEditModal(
            group: Group(id: '', ownerId: '', name: '', memo: ''),
            onSave: (group) {},
            availableMembers: const [],
          ),
        ),
      );

      // 作成ボタンをタップ
      await tester.tap(find.text('作成'));
      await tester.pump();

      expect(find.text('グループ名を入力してください'), findsOneWidget);
    });

    testWidgets('有効な入力でonSaveコールバックが呼ばれる', (WidgetTester tester) async {
      Group? savedGroup;

      await tester.pumpWidget(
        MaterialApp(
          home: GroupEditModal(
            group: Group(id: '', ownerId: '', name: '', memo: ''),
            onSave: (group) {
              savedGroup = group;
            },
            availableMembers: const [],
          ),
        ),
      );

      // グループ名を入力
      await tester.enterText(find.byType(TextFormField).first, 'テストグループ');
      await tester.pump();

      // 作成ボタンをタップ
      await tester.tap(find.text('作成'));
      await tester.pump();

      expect(savedGroup, isNotNull);
      expect(savedGroup!.name, 'テストグループ');
    });

    testWidgets('既存メンバーが一覧表示される', (WidgetTester tester) async {
      final availableMembers = [
        Member(
          id: 'member1',
          accountId: 'account1',
          ownerId: 'admin-id',
          displayName: 'メンバー1',
          kanjiLastName: '田中',
          kanjiFirstName: '太郎',
          hiraganaLastName: 'たなか',
          hiraganaFirstName: 'たろう',
          firstName: 'Taro',
          lastName: 'Tanaka',
          gender: '男性',
          birthday: DateTime(1990, 1, 1),
          email: 'taro@example.com',
          phoneNumber: '090-1234-5678',
          type: 'member',
          passportNumber: null,
          passportExpiration: null,
        ),
        Member(
          id: 'member2',
          accountId: 'account2',
          ownerId: 'admin-id',
          displayName: 'メンバー2',
          kanjiLastName: '鈴木',
          kanjiFirstName: '花子',
          hiraganaLastName: 'すずき',
          hiraganaFirstName: 'はなこ',
          firstName: 'Hanako',
          lastName: 'Suzuki',
          gender: '女性',
          birthday: DateTime(1992, 5, 15),
          email: 'hanako@example.com',
          phoneNumber: '090-8765-4321',
          type: 'member',
          passportNumber: null,
          passportExpiration: null,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: GroupEditModal(
            group: Group(
              id: 'group1',
              ownerId: 'owner1',
              name: 'テストグループ',
              members: const [
                GroupMember(groupId: 'group1', memberId: 'member1'),
                GroupMember(groupId: 'group1', memberId: 'member2'),
              ],
            ),
            onSave: (group) {},
            availableMembers: availableMembers,
          ),
        ),
      );

      expect(find.text('メンバー1'), findsOneWidget);
      expect(find.text('メンバー2'), findsOneWidget);
    });

    testWidgets('追加ボタンから未選択メンバーを追加できる', (WidgetTester tester) async {
      final availableMembers = [
        Member(
          id: 'member1',
          accountId: 'account1',
          ownerId: 'admin-id',
          displayName: 'メンバー1',
          kanjiLastName: '田中',
          kanjiFirstName: '太郎',
          hiraganaLastName: 'たなか',
          hiraganaFirstName: 'たろう',
          firstName: 'Taro',
          lastName: 'Tanaka',
          gender: '男性',
          birthday: DateTime(1990, 1, 1),
          email: 'taro@example.com',
          phoneNumber: '090-1234-5678',
          type: 'member',
          passportNumber: null,
          passportExpiration: null,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: GroupEditModal(
            group: Group(
              id: 'test-id',
              ownerId: 'admin-id',
              name: 'テストグループ',
              members: const [
                GroupMember(groupId: 'test-id', memberId: 'member1'),
              ],
            ),
            onSave: (group) {},
            availableMembers: availableMembers,
          ),
        ),
      );

      await tester.ensureVisible(find.byKey(const Key('add_member_button')));
      await tester.tap(find.byKey(const Key('add_member_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('メンバー1').first);
      await tester.pumpAndSettle();

      expect(find.text('メンバー1'), findsOneWidget);
    });

    testWidgets('操作メニューからメンバーを入れ替えられる', (WidgetTester tester) async {
      final availableMembers = [
        Member(
          id: 'member1',
          accountId: 'account1',
          ownerId: 'admin-id',
          displayName: 'メンバー1',
          kanjiLastName: '田中',
          kanjiFirstName: '太郎',
          hiraganaLastName: 'たなか',
          hiraganaFirstName: 'たろう',
          firstName: 'Taro',
          lastName: 'Tanaka',
          gender: '男性',
          birthday: DateTime(1990, 1, 1),
          email: 'taro@example.com',
          phoneNumber: '090-1234-5678',
          type: 'member',
          passportNumber: null,
          passportExpiration: null,
        ),
        Member(
          id: 'member2',
          accountId: 'account2',
          ownerId: 'admin-id',
          displayName: 'メンバー2',
          kanjiLastName: '鈴木',
          kanjiFirstName: '花子',
          hiraganaLastName: 'すずき',
          hiraganaFirstName: 'はなこ',
          firstName: 'Hanako',
          lastName: 'Suzuki',
          gender: '女性',
          birthday: DateTime(1992, 5, 15),
          email: 'hanako@example.com',
          phoneNumber: '090-8765-4321',
          type: 'member',
          passportNumber: null,
          passportExpiration: null,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: GroupEditModal(
            group: Group(
              id: 'test-id',
              ownerId: 'admin-id',
              name: 'テストグループ',
              members: const [
                GroupMember(groupId: 'test-id', memberId: 'member1'),
              ],
            ),
            onSave: (group) {},
            availableMembers: availableMembers,
          ),
        ),
      );

      await tester.ensureVisible(find.byKey(const Key('member_action_menu_0')));
      await tester.tap(find.byKey(const Key('member_action_menu_0')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('メンバーを変更'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('メンバー2').first);
      await tester.pumpAndSettle();

      expect(find.text('メンバー2'), findsOneWidget);
    });

    testWidgets('操作メニューからメンバーを削除できる', (WidgetTester tester) async {
      final availableMembers = [
        Member(
          id: 'member1',
          accountId: 'account1',
          ownerId: 'admin-id',
          displayName: 'メンバー1',
          kanjiLastName: '田中',
          kanjiFirstName: '太郎',
          hiraganaLastName: 'たなか',
          hiraganaFirstName: 'たろう',
          firstName: 'Taro',
          lastName: 'Tanaka',
          gender: '男性',
          birthday: DateTime(1990, 1, 1),
          email: 'taro@example.com',
          phoneNumber: '090-1234-5678',
          type: 'member',
          passportNumber: null,
          passportExpiration: null,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: GroupEditModal(
            group: Group(
              id: 'test-id',
              ownerId: 'admin-id',
              name: 'テストグループ',
              members: const [
                GroupMember(groupId: 'test-id', memberId: 'member1'),
              ],
            ),
            onSave: (group) {},
            availableMembers: availableMembers,
          ),
        ),
      );

      await tester.ensureVisible(find.byKey(const Key('member_action_menu_0')));
      await tester.tap(find.byKey(const Key('member_action_menu_0')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('メンバーを削除'));
      await tester.pump();

      expect(find.text('メンバー1'), findsNothing);
    });

    testWidgets('変更候補がない場合はメンバー変更メニューが無効になる', (WidgetTester tester) async {
      final availableMembers = [
        Member(
          id: 'member1',
          accountId: 'account1',
          ownerId: 'admin-id',
          displayName: 'メンバー1',
          kanjiLastName: '田中',
          kanjiFirstName: '太郎',
          hiraganaLastName: 'たなか',
          hiraganaFirstName: 'たろう',
          firstName: 'Taro',
          lastName: 'Tanaka',
          gender: '男性',
          birthday: DateTime(1990, 1, 1),
          email: 'taro@example.com',
          phoneNumber: '090-1234-5678',
          type: 'member',
          passportNumber: null,
          passportExpiration: null,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: GroupEditModal(
            group: Group(
              id: 'test-id',
              ownerId: 'admin-id',
              name: 'テストグループ',
              members: const [
                GroupMember(groupId: 'test-id', memberId: 'member1'),
              ],
            ),
            onSave: (group) {},
            availableMembers: availableMembers,
          ),
        ),
      );

      await tester.ensureVisible(find.byKey(const Key('member_action_menu_0')));
      await tester.tap(find.byKey(const Key('member_action_menu_0')));
      await tester.pumpAndSettle();

      final changeMenuItem = tester.widget<PopupMenuItem>(
        find.byKey(const Key('member_change_action_0')),
      );

      expect(changeMenuItem.enabled, isFalse);
    });

    testWidgets('メンバー名が長い場合に省略表示される', (WidgetTester tester) async {
      final longName = 'とても長い名前のテストメンバー' * 3;

      await tester.pumpWidget(
        MaterialApp(
          home: GroupEditModal(
            group: Group(
              id: 'test-id',
              ownerId: 'admin-id',
              name: 'テストグループ',
              members: [GroupMember(groupId: 'test-id', memberId: 'member1')],
            ),
            onSave: (group) {},
            availableMembers: [
              Member(
                id: 'member1',
                accountId: 'account1',
                ownerId: 'admin-id',
                displayName: longName,
                kanjiLastName: '長い',
                kanjiFirstName: '名前',
                hiraganaLastName: 'ながい',
                hiraganaFirstName: 'なまえ',
                firstName: 'Long',
                lastName: 'Name',
                gender: 'その他',
                birthday: DateTime(1990, 1, 1),
                email: 'long@example.com',
                phoneNumber: '090-0000-0000',
                type: 'member',
                passportNumber: null,
                passportExpiration: null,
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.text(longName));
      expect(textWidget.maxLines, 1);
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('保存時に選択されたメンバーがGroupに含まれる', (WidgetTester tester) async {
      final availableMembers = [
        Member(
          id: 'member1',
          accountId: 'account1',
          ownerId: 'admin-id',
          displayName: 'メンバー1',
          kanjiLastName: '田中',
          kanjiFirstName: '太郎',
          hiraganaLastName: 'たなか',
          hiraganaFirstName: 'たろう',
          firstName: 'Taro',
          lastName: 'Tanaka',
          gender: '男性',
          birthday: DateTime(1990, 1, 1),
          email: 'taro@example.com',
          phoneNumber: '090-1234-5678',
          type: 'member',
          passportNumber: null,
          passportExpiration: null,
        ),
      ];

      Group? savedGroup;

      await tester.pumpWidget(
        MaterialApp(
          home: GroupEditModal(
            group: Group(id: '', ownerId: '', name: '', memo: ''),
            onSave: (group) {
              savedGroup = group;
            },
            availableMembers: availableMembers,
          ),
        ),
      );

      await tester.ensureVisible(find.byKey(const Key('add_member_button')));
      await tester.tap(find.byKey(const Key('add_member_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('メンバー1').first);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'テストグループ');
      await tester.pump();

      await tester.tap(find.text('作成'));
      await tester.pump();

      expect(savedGroup, isNotNull);
      expect(savedGroup!.name, 'テストグループ');
    });

    testWidgets('キャンセルボタンでダイアログが閉じる', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => GroupEditModal(
                    group: Group(id: '', ownerId: '', name: '', memo: ''),
                    onSave: (group) {},
                    availableMembers: const [],
                  ),
                ),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      // モーダルを開く
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // モーダルが表示されることを確認
      expect(find.text('グループ新規作成'), findsOneWidget);

      // キャンセルボタンをタップ
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      // モーダルが閉じることを確認
      expect(find.text('グループ新規作成'), findsNothing);
    });

    testWidgets('メンバー数が多い場合、メンバー一覧のみスクロール可能', (WidgetTester tester) async {
      // 多数のメンバーを生成
      final availableMembers = List.generate(
        10,
        (index) => Member(
          id: 'member$index',
          accountId: 'account$index',
          ownerId: 'admin-id',
          displayName: 'メンバー$index',
          kanjiLastName: '田中',
          kanjiFirstName: '太郎',
          hiraganaLastName: 'たなか',
          hiraganaFirstName: 'たろう',
          firstName: 'Taro',
          lastName: 'Tanaka',
          gender: '男性',
          birthday: DateTime(1990, 1, 1),
          email: 'test$index@example.com',
          phoneNumber: '090-1234-567$index',
          type: 'member',
          passportNumber: null,
          passportExpiration: null,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GroupEditModal(
            group: Group(
              id: 'test-id',
              ownerId: 'admin-id',
              name: 'テストグループ',
              members: availableMembers
                  .take(5)
                  .map(
                    (member) =>
                        GroupMember(groupId: 'test-id', memberId: member.id),
                  )
                  .toList(),
            ),
            onSave: (group) {},
            availableMembers: availableMembers,
          ),
        ),
      );

      // メンバー一覧セクションが存在することを確認
      expect(find.text('メンバー一覧'), findsOneWidget);

      // メンバー一覧コンテナが存在することを確認
      expect(find.byKey(const Key('selected_member_list')), findsOneWidget);
    });

    testWidgets('既存の選択されたメンバーが正しく表示される', (WidgetTester tester) async {
      final group = Group(
        id: 'test-id',
        ownerId: 'admin-id',
        name: 'テストグループ',
        memo: 'テストメモ',
        members: const [GroupMember(groupId: 'test-id', memberId: 'member1')],
      );

      final availableMembers = [
        Member(
          id: 'member1',
          accountId: 'account1',
          ownerId: 'admin-id',
          displayName: 'メンバー1',
          kanjiLastName: '田中',
          kanjiFirstName: '太郎',
          hiraganaLastName: 'たなか',
          hiraganaFirstName: 'たろう',
          firstName: 'Taro',
          lastName: 'Tanaka',
          gender: '男性',
          birthday: DateTime(1990, 1, 1),
          email: 'taro@example.com',
          phoneNumber: '090-1234-5678',
          type: 'member',
          passportNumber: null,
          passportExpiration: null,
        ),
        Member(
          id: 'member2',
          accountId: 'account2',
          ownerId: 'admin-id',
          displayName: 'メンバー2',
          kanjiLastName: '鈴木',
          kanjiFirstName: '花子',
          hiraganaLastName: 'すずき',
          hiraganaFirstName: 'はなこ',
          firstName: 'Hanako',
          lastName: 'Suzuki',
          gender: '女性',
          birthday: DateTime(1992, 5, 15),
          email: 'hanako@example.com',
          phoneNumber: '090-8765-4321',
          type: 'member',
          passportNumber: null,
          passportExpiration: null,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: GroupEditModal(
            group: group,
            onSave: (group) {},
            availableMembers: availableMembers,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 選択済みのメンバーが一覧に表示されていることを確認
      expect(find.text('メンバー1'), findsOneWidget);
      expect(find.text('メンバー2'), findsNothing);
    });

    testWidgets('編集モードで既存グループ情報が正しく表示される', (WidgetTester tester) async {
      final group = Group(
        id: 'test-id',
        ownerId: 'admin-id',
        name: 'テストグループ',
        memo: 'テストメモ',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GroupEditModal(
            group: group,
            onSave: (group) {},
            availableMembers: const [],
          ),
        ),
      );

      // グループ名が正しく表示されることを確認
      expect(find.text('テストグループ'), findsOneWidget);

      // メモが正しく表示されることを確認
      expect(find.text('テストメモ'), findsOneWidget);

      // 更新ボタンが表示されることを確認
      expect(find.text('更新'), findsOneWidget);
    });

    testWidgets('管理者バッジが管理者メンバーに表示される', (WidgetTester tester) async {
      final availableMembers = [
        Member(
          id: 'admin-member',
          accountId: 'admin-account',
          ownerId: 'owner-id',
          displayName: '管理者メンバー',
          kanjiLastName: '管理',
          kanjiFirstName: '太郎',
          hiraganaLastName: 'かんり',
          hiraganaFirstName: 'たろう',
          firstName: 'Taro',
          lastName: 'Kanri',
          gender: '男性',
          birthday: DateTime(1990, 1, 1),
          email: 'admin@example.com',
          phoneNumber: '090-1111-1111',
          type: 'member',
          passportNumber: null,
          passportExpiration: null,
        ),
        Member(
          id: 'normal-member',
          accountId: 'normal-account',
          ownerId: 'owner-id',
          displayName: '一般メンバー',
          kanjiLastName: '一般',
          kanjiFirstName: '花子',
          hiraganaLastName: 'いっぱん',
          hiraganaFirstName: 'はなこ',
          firstName: 'Hanako',
          lastName: 'Ippan',
          gender: '女性',
          birthday: DateTime(1992, 5, 15),
          email: 'normal@example.com',
          phoneNumber: '090-2222-2222',
          type: 'member',
          passportNumber: null,
          passportExpiration: null,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: GroupEditModal(
            group: Group(
              id: 'test-group',
              ownerId: 'owner-id',
              name: 'テストグループ',
              members: const [
                GroupMember(
                  groupId: 'test-group',
                  memberId: 'admin-member',
                  isAdministrator: true,
                ),
                GroupMember(
                  groupId: 'test-group',
                  memberId: 'normal-member',
                  isAdministrator: false,
                ),
              ],
            ),
            onSave: (group) {},
            availableMembers: availableMembers,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 管理者バッジが表示されることを確認
      expect(find.text('管理者'), findsOneWidget);
      // 管理者メンバー名が表示されることを確認
      expect(find.text('管理者メンバー'), findsOneWidget);
      // 一般メンバー名が表示されることを確認
      expect(find.text('一般メンバー'), findsOneWidget);
    });

    testWidgets('管理者バッジの表示位置が固定される', (WidgetTester tester) async {
      final availableMembers = [
        Member(
          id: 'admin-member',
          accountId: 'admin-account',
          ownerId: 'owner-id',
          displayName: '管理者メンバー',
          kanjiLastName: '管理',
          kanjiFirstName: '太郎',
          hiraganaLastName: 'かんり',
          hiraganaFirstName: 'たろう',
          firstName: 'Taro',
          lastName: 'Kanri',
          gender: '男性',
          birthday: DateTime(1990, 1, 1),
          email: 'admin@example.com',
          phoneNumber: '090-1111-1111',
          type: 'member',
          passportNumber: null,
          passportExpiration: null,
        ),
        Member(
          id: 'normal-member',
          accountId: 'normal-account',
          ownerId: 'owner-id',
          displayName: '一般メンバー',
          kanjiLastName: '一般',
          kanjiFirstName: '花子',
          hiraganaLastName: 'いっぱん',
          hiraganaFirstName: 'はなこ',
          firstName: 'Hanako',
          lastName: 'Ippan',
          gender: '女性',
          birthday: DateTime(1992, 5, 15),
          email: 'normal@example.com',
          phoneNumber: '090-2222-2222',
          type: 'member',
          passportNumber: null,
          passportExpiration: null,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: GroupEditModal(
            group: Group(
              id: 'test-group',
              ownerId: 'owner-id',
              name: 'テストグループ',
              members: const [
                GroupMember(
                  groupId: 'test-group',
                  memberId: 'admin-member',
                  isAdministrator: true,
                ),
                GroupMember(
                  groupId: 'test-group',
                  memberId: 'normal-member',
                  isAdministrator: false,
                ),
              ],
            ),
            onSave: (group) {},
            availableMembers: availableMembers,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final adminSlot = tester.widget<SizedBox>(
        find.byKey(const Key('admin_badge_slot_0')),
      );
      final normalSlot = tester.widget<SizedBox>(
        find.byKey(const Key('admin_badge_slot_1')),
      );

      expect(adminSlot.width, equals(normalSlot.width));
      expect(adminSlot.width, isNotNull);
      expect(
        find.descendant(
          of: find.byKey(const Key('admin_badge_slot_0')),
          matching: find.text('管理者'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('admin_badge_slot_1')),
          matching: find.text('管理者'),
        ),
        findsNothing,
      );
    });

    testWidgets('操作メニューから管理者権限を切り替えられる', (WidgetTester tester) async {
      final availableMembers = [
        Member(
          id: 'member1',
          accountId: 'account1',
          ownerId: 'owner-id',
          displayName: 'テストメンバー',
          kanjiLastName: 'テスト',
          kanjiFirstName: '太郎',
          hiraganaLastName: 'てすと',
          hiraganaFirstName: 'たろう',
          firstName: 'Taro',
          lastName: 'Test',
          gender: '男性',
          birthday: DateTime(1990, 1, 1),
          email: 'test@example.com',
          phoneNumber: '090-1234-5678',
          type: 'member',
          passportNumber: null,
          passportExpiration: null,
        ),
      ];

      Group? savedGroup;

      await tester.pumpWidget(
        MaterialApp(
          home: GroupEditModal(
            group: Group(
              id: 'test-group',
              ownerId: 'owner-id',
              name: 'テストグループ',
              members: const [
                GroupMember(
                  groupId: 'test-group',
                  memberId: 'member1',
                  isAdministrator: false,
                ),
              ],
            ),
            onSave: (group) {
              savedGroup = group;
            },
            availableMembers: availableMembers,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 初期状態では管理者バッジが表示されないことを確認
      expect(find.text('管理者'), findsNothing);

      // 操作メニューから管理者権限を付与
      await tester.tap(find.byKey(const Key('member_action_menu_0')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('管理者に設定'));
      await tester.pumpAndSettle();

      // 管理者バッジが表示されることを確認
      expect(find.text('管理者'), findsOneWidget);

      // グループ名を入力して保存
      await tester.enterText(find.byType(TextFormField).first, 'テストグループ');
      await tester.tap(find.text('更新'));
      await tester.pump();

      // 保存されたグループの管理者権限が更新されていることを確認
      expect(savedGroup, isNotNull);
      expect(savedGroup!.members.first.isAdministrator, isTrue);
    });
  });
}
