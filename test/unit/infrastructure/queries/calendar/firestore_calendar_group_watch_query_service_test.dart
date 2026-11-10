import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/infrastructure/queries/calendar/firestore_calendar_group_watch_query_service.dart';

import '../../../../helpers/test_exception.dart';
import '../../repositories/group/firestore_group_repository_test.mocks.dart';

void main() {
  test('初回とメンバー変更は受信データを使い全員を再取得せず所属変更と解除を反映する', () async {
    final firestore = MockFirebaseFirestore();
    final groups = MockCollectionReference<Map<String, dynamic>>();
    final members = MockCollectionReference<Map<String, dynamic>>();
    final links = MockCollectionReference<Map<String, dynamic>>();
    final groupRef = MockDocumentReference<Map<String, dynamic>>();
    final memberRef = MockDocumentReference<Map<String, dynamic>>();
    final groupDoc = MockDocumentSnapshot<Map<String, dynamic>>();
    final memberDoc = MockDocumentSnapshot<Map<String, dynamic>>();
    final linkDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
    final query = MockQuery<Map<String, dynamic>>();
    final snapshot = MockQuerySnapshot<Map<String, dynamic>>();
    var memberCancelled = false;
    var parentCancelled = false;
    final parentStream =
        StreamController<DocumentSnapshot<Map<String, dynamic>>>(
          onCancel: () {
            parentCancelled = true;
          },
        );
    final memberStream =
        StreamController<DocumentSnapshot<Map<String, dynamic>>>(
          onCancel: () {
            memberCancelled = true;
          },
        );
    final groupData = <String, dynamic>{
      'name': '家族',
      'ownerId': 'm',
      'color': '#123456',
    };
    final memberData = <String, dynamic>{'displayName': '太郎'};
    final linkData = <String, dynamic>{
      'groupId': 'g',
      'memberId': 'm',
      'color': '#FF0000',
    };
    when(firestore.collection('groups')).thenReturn(groups);
    when(firestore.collection('members')).thenReturn(members);
    when(firestore.collection('group_members')).thenReturn(links);
    when(groups.doc('g')).thenReturn(groupRef);
    when(members.doc('m')).thenReturn(memberRef);
    when(groupRef.snapshots()).thenAnswer((_) => parentStream.stream);
    when(memberRef.snapshots()).thenAnswer((_) => memberStream.stream);
    when(groupRef.get()).thenAnswer((_) async => groupDoc);
    when(memberRef.get()).thenAnswer((_) async => memberDoc);
    when(groupDoc.exists).thenReturn(true);
    when(memberDoc.exists).thenReturn(true);
    when(groupDoc.id).thenReturn('g');
    when(memberDoc.id).thenReturn('m');
    when(groupDoc.data()).thenAnswer((_) => groupData);
    when(memberDoc.data()).thenAnswer((_) => memberData);
    when(linkDoc.data()).thenAnswer((_) => linkData);
    when(links.where('groupId', isEqualTo: 'g')).thenReturn(query);
    when(query.get()).thenAnswer((_) async => snapshot);
    when(snapshot.docs).thenReturn([linkDoc]);
    final values = <GroupDto?>[];
    final errors = <Object>[];
    final subscription = FirestoreCalendarGroupWatchQueryService(firestore)
        .watchCalendarGroup('g')
        .listen(values.add, onError: errors.add);
    addTearDown(() async {
      await subscription.cancel();
      await parentStream.close();
      await memberStream.close();
    });
    Future<void> flush() => Future<void>(() {});
    parentStream.add(groupDoc);
    await flush();
    memberStream.add(memberDoc);
    await flush();
    expect(values.last!.members.single.displayName, '太郎');
    verifyNever(groupRef.get());
    verifyNever(memberRef.get());
    verify(query.get()).called(1);
    memberData['displayName'] = '花子';
    memberStream.add(memberDoc);
    await flush();
    expect(values.last!.members.single.displayName, '花子');
    verifyNever(query.get());
    verifyNever(groupRef.get());
    verifyNever(memberRef.get());
    linkData['textColor'] = '#000000';
    groupData['textColor'] = '#FFFFFF';
    linkData['color'] = '#00FF00';
    groupData['color'] = '#654321';
    parentStream.add(groupDoc);
    await flush();
    expect(values.last!.textColor, '#FFFFFF');
    expect(values.last!.members.single.textColor, '#000000');
    expect(values.last!.color, '#654321');
    expect(values.last!.members.single.color, '#00FF00');
    memberStream.addError(TestException('監視失敗'));
    await flush();
    expect(errors, hasLength(1));
    when(snapshot.docs).thenReturn([]);
    parentStream.add(groupDoc);
    await flush();
    expect(values.last!.members, isEmpty);
    expect(memberCancelled, isTrue);
    await subscription.cancel();
    expect(parentCancelled, isTrue);
  });
}
