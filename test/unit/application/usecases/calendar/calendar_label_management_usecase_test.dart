import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/usecases/calendar/calendar_label_management_usecase.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';

import '../../../../helpers/calendar_group_test_support.dart';
import '../../../../helpers/calendar_group_test_support.mocks.dart';
import 'calendar_usecases_test.mocks.dart';

void main() {
  test('所有者・管理者のみ任意ラベルを変更でき一般メンバーの保存を拒否する', () async {
    final repository = MockCalendarLabelRepository();
    final groups =
        calendarTestGroupLoader() as MockGetGroupWithMembersByIdUsecase;
    when(groups.execute('g')).thenAnswer(
      (_) async => const GroupDto(
        id: 'g',
        ownerId: 'owner',
        name: '家族',
        members: [
          GroupMemberDto(
            memberId: 'admin',
            groupId: 'g',
            displayName: '管理者',
            isAdministrator: true,
          ),
        ],
      ),
    );
    final usecase = CalendarLabelManagementUsecase(repository, groups);
    const label = CalendarLabelDto(
      id: 'label',
      groupId: 'g',
      name: '予定',
      color: '#123456',
    );
    await expectLater(
      usecase.save(label, 'member'),
      throwsA(isA<ApplicationValidationException>()),
    );
    verifyNever(repository.saveCalendarLabel(any));
    when(repository.saveCalendarLabel(any)).thenAnswer((_) async => 'label');
    await usecase.save(label, 'owner');
    await usecase.save(label, 'admin');
    verify(repository.saveCalendarLabel(any)).called(2);
    await expectLater(
      usecase.delete('g', 'label', 'member'),
      throwsA(isA<ApplicationValidationException>()),
    );
    await expectLater(
      usecase.reorder('g', ['label'], 'member'),
      throwsA(isA<ApplicationValidationException>()),
    );
    verifyNever(repository.deleteCalendarLabel(any));
    verifyNever(repository.reorderCalendarLabels(any, any));
  });
}
