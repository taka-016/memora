import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/member/member.dart';
import 'package:memora/domain/entities/member/member_invitation.dart';
import 'package:memora/infrastructure/repositories/member/firestore_member_invitation_repository.dart';

import '../../../../helpers/firestore_transaction_store.dart';
import '../../../../helpers/test_exception.dart';

void main() {
  const member = Member(
    id: 'm',
    displayName: '本人',
    accountId: 'user',
    version: 7,
  );
  const invitations = [
    MemberInvitation(
      id: 'i',
      inviteeId: 'm',
      inviterId: 'owner',
      invitationCode: 'code',
      version: 2,
    ),
    MemberInvitation(
      id: 'j',
      inviteeId: 'm',
      inviterId: 'owner',
      invitationCode: 'other',
      version: 4,
    ),
  ];
  late FirestoreTransactionStore store;
  late FirestoreMemberInvitationRepository repo;
  setUp(() {
    store = FirestoreTransactionStore();
    store.rows.addAll({
      'members/m': {'version': 7, 'displayName': '本人'},
      'member_invitations/i': {
        'version': 2,
        'inviteeId': 'm',
        'invitationCode': 'code',
      },
      'member_invitations/j': {
        'version': 4,
        'inviteeId': 'm',
        'invitationCode': 'other',
      },
      'member_invitations/else': {'version': 1, 'inviteeId': 'else'},
    });
    repo = FirestoreMemberInvitationRepository(firestore: store.firestore);
  });
  test('メンバーの更新と同じ対象の招待2件の削除が一度の確定で完了する', () async {
    await repo.acceptInvitation(member, invitations);
    expect(store.rows['members/m']!['accountId'], 'user');
    expect(store.rows['members/m']!['version'], 8);
    expect(
      store.rows.keys,
      unorderedEquals(['members/m', 'member_invitations/else']),
    );
    expect(store.commits, 1);
  });
  for (final path in [
    'members/m',
    'member_invitations/i',
    'member_invitations/j',
  ]) {
    for (final deleted in [false, true]) {
      for (final retry in [false, true]) {
        test(
          '$pathの${deleted ? '削除' : '編集・再発行'}を${retry ? '再試行' : '初回照合'}で検知し一部も確定しない',
          () async {
            void change() {
              if (deleted) {
                store.rows.remove(path);
              } else {
                store.rows[path]!['version'] = 20;
              }
            }

            if (retry) {
              store.beforeRetry = change;
            } else {
              change();
            }
            await expectLater(
              repo.acceptInvitation(member, invitations),
              throwsA(isA<FirebaseException>()),
            );
            expect(store.commits, 0);
            expect(store.rows['members/m']?['accountId'], isNull);
            for (final id in ['i', 'j']) {
              if (deleted && path == 'member_invitations/$id') continue;
              expect(store.rows.containsKey('member_invitations/$id'), isTrue);
            }
          },
        );
      }
    }
  }
  test('書き込み拒否でも紐付けと招待削除が一部だけ残らない', () async {
    store.commitError = TestException();
    await expectLater(
      repo.acceptInvitation(member, invitations),
      throwsA(isA<TestException>()),
    );
    expect(store.rows['members/m']!['accountId'], isNull);
    expect(store.rows.length, 4);
  });
  test('別端末の同じ期待値からの承認は拒否する', () async {
    await repo.acceptInvitation(member, invitations);
    await expectLater(
      repo.acceptInvitation(member.copyWith(accountId: 'other'), invitations),
      throwsA(isA<FirebaseException>()),
    );
    expect(store.rows['members/m']!['accountId'], 'user');
    expect(store.commits, 1);
  });
  test('再試行で取得対象を増やさず一覧取得後の新規招待は残す', () async {
    store.beforeRetry = () =>
        store.rows['member_invitations/new'] = {'version': 1, 'inviteeId': 'm'};
    await repo.acceptInvitation(member, invitations);
    expect(store.rows.containsKey('member_invitations/new'), isTrue);
    expect(store.reads.where((path) => path.endsWith('/new')), isEmpty);
  });
  test('承認はトランザクション確定まで完了しない', () async {
    final committing = Completer<void>();
    final committed = Completer<void>();
    store.beforeCommit = () {
      committing.complete();
      return committed.future;
    };
    var finished = false;
    final saving = repo
        .acceptInvitation(member, invitations)
        .whenComplete(() => finished = true);
    await committing.future;
    expect(finished, isFalse);
    expect(store.rows['members/m']!['accountId'], isNull);
    expect(store.rows.containsKey('member_invitations/i'), isTrue);
    committed.complete();
    await saving;
    expect(finished, isTrue);
    expect(store.rows['members/m']!['accountId'], 'user');
    expect(store.rows.containsKey('member_invitations/i'), isFalse);
  });
}
