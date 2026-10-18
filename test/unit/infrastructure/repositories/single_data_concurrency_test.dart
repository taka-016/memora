import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/infrastructure/repositories/member/firestore_member_repository.dart';
import 'package:memora/infrastructure/repositories/member/firestore_member_invitation_repository.dart';
import 'package:memora/infrastructure/repositories/member/firestore_member_event_repository.dart';
import 'package:memora/infrastructure/repositories/group/firestore_group_event_repository.dart';

import '../../../helpers/firestore_transaction_store.dart';

void main() {
  for (final collection in [
    'members',
    'member_invitations',
    'member_events',
    'group_events',
  ]) {
    for (final current in [3, 4, null]) {
      test('$collectionの削除・退避は期待値3と現在値$currentを照合する', () async {
        final store = FirestoreTransactionStore();
        final original = <String, dynamic>{'version': current, 'memo': '保持する'};
        store.rows['$collection/id'] = Map.of(original);
        final action = remove(store, collection);
        if (current != 3) {
          await expectLater(action, throwsA(isA<FirebaseException>()));
          expect(store.rows['$collection/id'], original);
          expect(store.rows.containsKey('deleted_members/id'), isFalse);
        } else {
          await action;
          expect(store.rows.containsKey('$collection/id'), isFalse);
          if (collection == 'members') {
            expect(store.rows['deleted_members/id'], original);
          }
        }
      });
    }
    test('$collectionの照合後に同時更新された再試行は当初の期待値で拒否する', () async {
      final store = FirestoreTransactionStore();
      store.rows['$collection/id'] = {'version': 3};
      store.beforeRetry = () => store.rows['$collection/id'] = {'version': 4};
      await expectLater(
        remove(store, collection),
        throwsA(isA<FirebaseException>()),
      );
      expect(store.rows['$collection/id']!['version'], 4);
      expect(store.commits, 0);
    });
  }
}

Future<void> remove(FirestoreTransactionStore store, String collection) =>
    switch (collection) {
      'members' => FirestoreMemberRepository(
        firestore: store.firestore,
      ).deleteMember('id', expectedVersion: 3),
      'member_invitations' => FirestoreMemberInvitationRepository(
        firestore: store.firestore,
      ).deleteMemberInvitation('id', expectedVersion: 3),
      'member_events' => FirestoreMemberEventRepository(
        firestore: store.firestore,
      ).deleteMemberEvent('id', expectedVersion: 3),
      _ => FirestoreGroupEventRepository(
        firestore: store.firestore,
      ).deleteGroupEvent('id', expectedVersion: 3),
    };
