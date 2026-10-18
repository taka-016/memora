import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/member/member_event.dart';
import 'package:memora/infrastructure/repositories/member/firestore_member_event_repository.dart';
import '../../../../helpers/firestore_transaction_store.dart';

void main() {
  const event = MemberEvent(id: 'm_2026', memberId: 'm', year: 2026, memo: '変更', version: 3);
  for (final memo in ['変更', '']) {
    for (final version in [3, 4, null]) {
      test('メモ「$memo」の保存は取得時バージョン$versionを照合する', () async {
        final store = FirestoreTransactionStore();
        store.rows['member_events/m_2026'] = {'memberId': 'm', 'year': 2026, 'memo': '元', 'version': version};
        final repo = FirestoreMemberEventRepository(firestore: store.firestore);
        final saving = repo.saveMemberEvent(event.copyWith(memo: memo));
        if (version != 3) {
          await expectLater(saving, throwsA(isA<FirebaseException>()));
          expect(store.rows['member_events/m_2026']!['memo'], '元');
        } else {
          expect(await saving, memo.isEmpty ? '' : 'm_2026');
          expect(store.rows['member_events/m_2026']?['version'], memo.isEmpty ? null : 4);
        }
      });
    }
  }
  for (final memo in ['新規', '']) {
    test('初回のメモ「$memo」は別端末の初回保存を上書き・削除しない', () async {
      final store = FirestoreTransactionStore();
      store.rows['member_events/m_2026'] = {'memberId': 'm', 'year': 2026, 'memo': '他端末', 'version': 1};
      final repo = FirestoreMemberEventRepository(firestore: store.firestore);
      await expectLater(repo.saveMemberEvent(MemberEvent(id: '', memberId: 'm', year: 2026, memo: memo)), throwsA(isA<FirebaseException>()));
      expect(store.rows['member_events/m_2026']!['memo'], '他端末');
    });
  }
  test('初回保存後は固定IDと初期バージョンを保存する', () async {
    final store = FirestoreTransactionStore();
    final repo = FirestoreMemberEventRepository(firestore: store.firestore);
    expect(await repo.saveMemberEvent(const MemberEvent(id: '', memberId: 'm', year: 2026, memo: '新規')), 'm_2026');
    expect(store.rows['member_events/m_2026']!['version'], 1);
  });
  for (final rejected in [false, true]) {
    test('重複整理は本体保存${rejected ? '拒否時に行わない' : '成功後だけ行う'}', () async {
      final store = FirestoreTransactionStore();
      store.rows['member_events/m_2026'] = {'memberId': 'm', 'year': 2026, 'memo': '元', 'version': rejected ? 4 : 3};
      store.rows['member_events/duplicate'] = {'memberId': 'm', 'year': 2026, 'memo': '重複', 'version': 2};
      final repo = FirestoreMemberEventRepository(firestore: store.firestore);
      if (rejected) {
        await expectLater(repo.saveMemberEvent(event), throwsA(isA<FirebaseException>()));
        expect(store.rows.containsKey('member_events/duplicate'), isTrue);
      } else {
        await repo.saveMemberEvent(event);
        expect(store.rows.containsKey('member_events/duplicate'), isFalse);
      }
    });
  }
  test('旧IDのイベントも取得時の期待値を確認して固定IDへ保存する', () async {
    final store = FirestoreTransactionStore();
    store.rows['member_events/old'] = {'memberId': 'm', 'year': 2026, 'memo': '元', 'version': 3};
    await FirestoreMemberEventRepository(firestore: store.firestore).saveMemberEvent(event.copyWith(id: 'old'));
    expect(store.rows['member_events/m_2026']!['version'], 1);
    expect(store.rows.containsKey('member_events/old'), isFalse);
  });
}
