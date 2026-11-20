import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/infrastructure/services/firestore_startup_common_data_source.dart';

import '../queries/group/firestore_group_query_service_test.mocks.dart';

void main() {
  test('共通データでも所属を名前順、メンバーを設定した表示順で取得する', () async {
    final firestore = MockFirebaseFirestore();
    final groups = MockCollectionReference<Map<String, dynamic>>();
    final groupMembers = MockCollectionReference<Map<String, dynamic>>();
    final members = MockCollectionReference<Map<String, dynamic>>();
    when(firestore.collection('groups')).thenReturn(groups);
    when(firestore.collection('group_members')).thenReturn(groupMembers);
    when(firestore.collection('members')).thenReturn(members);
    final memberships = MockQuery<Map<String, dynamic>>();
    final memberGroups = MockQuerySnapshot<Map<String, dynamic>>();
    when(groupMembers.where('memberId', isEqualTo: '本人'))
        .thenReturn(memberships);
    when(memberships.get(any)).thenAnswer((_) async => memberGroups);
    final links = [
      for (final id in ['b', 'a']) _membership(id),
    ];
    when(memberGroups.docs).thenReturn(links);
    for (final entry in {'b': 'Bグループ', 'a': 'Aグループ'}.entries) {
      final reference = MockDocumentReference<Map<String, dynamic>>();
      final snapshot = MockDocumentSnapshot<Map<String, dynamic>>();
      when(groups.doc(entry.key)).thenReturn(reference);
      when(reference.get(any)).thenAnswer((_) async => snapshot);
      when(snapshot.exists).thenReturn(true);
      when(snapshot.id).thenReturn(entry.key);
      when(snapshot.data()).thenReturn({'name': entry.value});
      final query = MockQuery<Map<String, dynamic>>();
      final result = MockQuerySnapshot<Map<String, dynamic>>();
      when(groupMembers.where('groupId', isEqualTo: entry.key))
          .thenReturn(query);
      when(query.get(any)).thenAnswer((_) async => result);
      final membershipDocuments =
          <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      if (entry.key == 'a') {
        for (final position in [2, 1]) {
          final id = 'member-$position';
          final membership = MockQueryDocumentSnapshot<Map<String, dynamic>>();
          when(membership.data()).thenReturn({
            'groupId': 'a',
            'memberId': id,
            'orderIndex': position,
          });
          membershipDocuments.add(membership);
          final memberReference = MockDocumentReference<Map<String, dynamic>>();
          final member = MockDocumentSnapshot<Map<String, dynamic>>();
          when(members.doc(id)).thenReturn(memberReference);
          when(memberReference.get(any)).thenAnswer((_) async => member);
          when(member.exists).thenReturn(true);
          when(member.id).thenReturn(id);
          when(member.data()).thenReturn({'displayName': 'メンバー$position'});
        }
      }
      when(result.docs).thenReturn(membershipDocuments);
    }
    final source = FirestoreStartupCommonDataSource(firestore);
    final loaded = await source.loadGroups('本人');
    expect(loaded.map((group) => group.id), ['a', 'b']);
    expect(loaded.first.members.map((member) => member.memberId), [
      'member-1',
      'member-2',
    ]);
  });
}

MockQueryDocumentSnapshot<Map<String, dynamic>> _membership(String groupId) {
  final membership = MockQueryDocumentSnapshot<Map<String, dynamic>>();
  when(membership.data()).thenReturn({'groupId': groupId});
  return membership;
}
