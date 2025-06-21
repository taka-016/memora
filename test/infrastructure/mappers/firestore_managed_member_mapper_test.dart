import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/mappers/firestore_managed_member_mapper.dart';
import 'package:memora/domain/entities/managed_member.dart';
import '../repositories/firestore_group_member_repository_test.mocks.dart';

void main() {
  group('FirestoreManagedMemberMapper', () {
    test('FirestoreのDocumentSnapshotからManagedMemberへ変換できる', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('managedmember001');
      when(mockDoc.data()).thenReturn({
        'memberId': 'member001',
        'managedMemberId': 'member002',
      });

      final managedMember = FirestoreManagedMemberMapper.fromFirestore(mockDoc);

      expect(managedMember.id, 'managedmember001');
      expect(managedMember.memberId, 'member001');
      expect(managedMember.managedMemberId, 'member002');
    });

    test('ManagedMemberからFirestoreのMapへ変換できる', () {
      final managedMember = ManagedMember(
        id: 'managedmember001',
        memberId: 'member001',
        managedMemberId: 'member002',
      );

      final data = FirestoreManagedMemberMapper.toFirestore(managedMember);

      expect(data['memberId'], 'member001');
      expect(data['managedMemberId'], 'member002');
      expect(data['createdAt'], isA<FieldValue>());
    });
  });
}