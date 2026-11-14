import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/presentation/features/group/group_edit_modal.dart';
import 'package:memora/presentation/features/calendar/calendar_labels_dialog.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_labels_notifier.dart';

class _Labels extends CalendarLabelsNotifier {
  @override
  CalendarLabelsState build(String groupId) => CalendarLabelsState(canManage: true);
}
void main() {
  for (final role in ['owner', 'admin', 'member']) {
    testWidgets('既存グループの任意ラベル管理への入口を役割に合わせる（$role）', (tester) async {
      await tester.pumpWidget(ProviderScope(overrides: [calendarLabelsNotifierProvider('g').overrideWith(_Labels.new)], child: MaterialApp(home: GroupEditModal(
        group: const GroupDto(id: 'g', ownerId: 'owner', name: '家族', members: [GroupMemberDto(memberId: 'admin', groupId: 'g', displayName: '管理者', isAdministrator: true)]),
        currentMember: MemberDto(id: role, displayName: role), availableMembers: const [], onSave: (_) async => true,
      ))));
      if (role == 'member') {
        expect(find.text('色ラベルの設定'), findsNothing);
      } else {
        await tester.ensureVisible(find.text('色ラベルの設定'));
        await tester.tap(find.text('色ラベルの設定')); await tester.pumpAndSettle();
        expect(find.byType(CalendarLabelsDialog), findsOneWidget);
        await tester.tap(find.text('閉じる')); await tester.pumpAndSettle();
        expect(find.byType(CalendarLabelsDialog), findsNothing);
      }
    });
  }
}
