import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/usecases/group/get_group_with_members_by_id_usecase.dart';

import 'calendar_group_test_support.mocks.dart';

@GenerateMocks([GetGroupWithMembersByIdUsecase])
GetGroupWithMembersByIdUsecase calendarTestGroupLoader() {
  final mock = MockGetGroupWithMembersByIdUsecase();
  when(mock.execute(any)).thenAnswer(
    (call) async => GroupDto(
      id: call.positionalArguments.first as String,
      ownerId: 'owner',
      name: '家族',
      members: const [],
    ),
  );
  return mock;
}
