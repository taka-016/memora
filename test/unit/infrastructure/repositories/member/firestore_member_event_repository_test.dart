import 'dart:async';

import '../../../../helpers/test_exception.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/member/member_event.dart';
import 'package:memora/infrastructure/repositories/member/firestore_member_event_repository.dart';

import '../../../../helpers/firestore_transaction_store.dart';

void main() {
  const event = MemberEvent(
    id: 'm_2026',
    memberId: 'm',
    year: 2026,
    memo: '変更',
    version: 3,
  );
  for (final memo in ['変更', '']) {
    for (final version in [3, 4, null]) {
      test('メモ「$memo」の保存は取得時バージョン$versionを照合する', () async {
        final store = FirestoreTransactionStore();
        store.rows['member_events/m_2026'] = {
          'memberId': 'm',
          'year': 2026,
          'memo': '元',
          'version': version,
        };
        final repo = FirestoreMemberEventRepository(firestore: store.firestore);
        final saving = repo.saveMemberEvent(event.copyWith(memo: memo));
        if (version != 3) {
          await expectLater(saving, throwsA(isA<FirebaseException>()));
          expect(store.rows['member_events/m_2026']!['memo'], '元');
        } else {
          expect(await saving, memo.isEmpty ? '' : 'm_2026');
          expect(
            store.rows['member_events/m_2026']?['version'],
            memo.isEmpty ? null : 4,
          );
        }
      });
    }
  }
  for (final memo in ['新規', '']) {
    test('初回のメモ「$memo」は別端末の初回保存を上書き・削除しない', () async {
      final store = FirestoreTransactionStore();
      store.rows['member_events/m_2026'] = {
        'memberId': 'm',
        'year': 2026,
        'memo': '他端末',
        'version': 1,
      };
      final repo = FirestoreMemberEventRepository(firestore: store.firestore);
      await expectLater(
        repo.saveMemberEvent(
          MemberEvent(id: '', memberId: 'm', year: 2026, memo: memo),
        ),
        throwsA(isA<FirebaseException>()),
      );
      expect(store.rows['member_events/m_2026']!['memo'], '他端末');
    });
  }
  test('初回保存後は固定IDと初期バージョンを保存する', () async {
    final store = FirestoreTransactionStore();
    final repo = FirestoreMemberEventRepository(firestore: store.firestore);
    expect(
      await repo.saveMemberEvent(
        const MemberEvent(id: '', memberId: 'm', year: 2026, memo: '新規'),
      ),
      'm_2026',
    );
    expect(store.rows['member_events/m_2026']!['version'], 1);
  });
  for (final rejected in [false, true]) {
    test('重複整理は本体保存${rejected ? '拒否時に行わない' : '成功後だけ行う'}', () async {
      final store = FirestoreTransactionStore();
      store.rows['member_events/m_2026'] = {
        'memberId': 'm',
        'year': 2026,
        'memo': '元',
        'version': rejected ? 4 : 3,
      };
      store.rows['member_events/duplicate'] = {
        'memberId': 'm',
        'year': 2026,
        'memo': '重複',
        'version': 2,
      };
      final repo = FirestoreMemberEventRepository(firestore: store.firestore);
      if (rejected) {
        await expectLater(
          repo.saveMemberEvent(event),
          throwsA(isA<FirebaseException>()),
        );
        expect(store.rows.containsKey('member_events/duplicate'), isTrue);
      } else {
        await repo.saveMemberEvent(event);
        expect(store.rows.containsKey('member_events/duplicate'), isFalse);
      }
    });
  }
  test('旧IDのイベントも取得時の期待値を確認して固定IDへ保存する', () async {
    final store = FirestoreTransactionStore();
    store.rows['member_events/old'] = {
      'memberId': 'm',
      'year': 2026,
      'memo': '元',
      'version': 3,
    };
    await FirestoreMemberEventRepository(firestore: store.firestore)
        .saveMemberEvent(event.copyWith(id: 'old'));
    expect(store.rows['member_events/m_2026']!['version'], 1);
    expect(store.rows.containsKey('member_events/old'), isFalse);
  });
  for (final failed in [false, true]) {
    test('本体・重複整理の確定まで待ち${failed ? '書き込み拒否を伝える' : '成功する'}', () async {
      final store = FirestoreTransactionStore();
      store.rows['member_events/duplicate'] = {
        'memberId': 'm',
        'year': 2026,
        'version': 1,
      };
      final saving = Completer<void>();
      final saved = Completer<void>();
      final cleaning = Completer<void>();
      final cleaned = Completer<void>();
      store.beforeCommit = () async {
        if (store.commits == 0) {
          saving.complete();
          await saved.future;
        } else {
          cleaning.complete();
          await cleaned.future;
        }
      };
      var finished = false;
      final future = FirestoreMemberEventRepository(firestore: store.firestore)
          .saveMemberEvent(
            const MemberEvent(id: '', memberId: 'm', year: 2026, memo: '新規'),
          )
          .whenComplete(() => finished = true);
      final result = expectLater(
        future,
        failed ? throwsA(isA<TestException>()) : completion('m_2026'),
      );
      await saving.future;
      expect(finished, isFalse);
      saved.complete();
      await cleaning.future;
      expect(finished, isFalse);
      if (failed) store.commitError = TestException('整理失敗');
      cleaned.complete();
      await result;
      expect(store.rows.containsKey('member_events/duplicate'), failed);
    });
  }
  for (final memo in ['新規', '']) {
    test('同時初回作成を照合後の再試行で拒否する（メモ「$memo」）', () async {
      final store = FirestoreTransactionStore();
      store.beforeRetry = () => store.rows['member_events/m_2026'] = {
        'memberId': 'm',
        'year': 2026,
        'memo': '同時保存',
        'version': 1,
      };
      await expectLater(
        FirestoreMemberEventRepository(firestore: store.firestore)
            .saveMemberEvent(
              MemberEvent(id: '', memberId: 'm', year: 2026, memo: memo),
            ),
        throwsA(isA<FirebaseException>()),
      );
      expect(store.rows['member_events/m_2026']!['memo'], '同時保存');
      expect(store.commits, 0);
    });
  }
  for (final conflict in [false, true]) {
    test('空メモは重複も含め${conflict ? '同時更新時はすべて維持する' : '同時に削除する'}', () async {
      final store = FirestoreTransactionStore();
      store.rows['member_events/m_2026'] = {
        'memberId': 'm',
        'year': 2026,
        'memo': '元',
        'version': 3,
      };
      store.rows['member_events/duplicate'] = {
        'memberId': 'm',
        'year': 2026,
        'memo': '重複',
        'version': 2,
      };
      if (conflict) {
        store.beforeRetry = () =>
            store.rows['member_events/duplicate']!['version'] = 4;
      }
      final saving = FirestoreMemberEventRepository(firestore: store.firestore)
          .saveMemberEvent(event.copyWith(memo: ''));
      if (conflict) {
        await expectLater(saving, throwsA(isA<FirebaseException>()));
        expect(
          store.rows.keys,
          unorderedEquals(['member_events/m_2026', 'member_events/duplicate']),
        );
        expect(store.commits, 0);
      } else {
        expect(await saving, '');
        expect(store.rows, isEmpty);
        expect(store.commits, 1);
      }
    });
  }
}
