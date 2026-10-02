const { readFileSync } = require('node:fs');
const { test, before, after, beforeEach } = require('node:test');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, setDoc, getDoc, updateDoc, deleteDoc, collection, query, where, getDocs, writeBatch, Timestamp } = require('firebase/firestore');
let env;
before(async () => {
  env = await initializeTestEnvironment({projectId: 'demo-memora-calendar', firestore: {rules: readFileSync(process.env.CALENDAR_RULES_PATH || 'firestore_calendar.rules', 'utf8')}});
});
after(async () => { if (env) await env.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    await setDoc(doc(db, 'members/owner'), {accountId: 'alice'});
    await setDoc(doc(db, 'members/friend'), {accountId: 'bob'});
    await setDoc(doc(db, 'groups/family'), {ownerId: 'owner', calendarDeleting: false});
    await setDoc(doc(db, 'groups/other'), {ownerId: 'owner'});
    for (const [id, memberId] of [['a', 'owner'], ['b', 'friend']]) {
      await setDoc(doc(db, `group_members/${id}`), {groupId: 'family', memberId, isAdministrator: memberId === 'owner'});
      await setDoc(doc(db, `calendar_memberships/family/accounts/${memberId === 'owner' ? 'alice' : 'bob'}`), {memberId, membershipId: id});
    }
    await setDoc(doc(db, 'calendar_labels/label'), {groupId: 'family', name: '家族全員', color: '#123ABC', eventCount: 0, lastEventId: null});
    await setDoc(doc(db, 'calendar_labels/other-label'), {groupId: 'other', name: '別グループ', color: '#FFFFFF', eventCount: 0, lastEventId: null});
  });
});
function db(uid) { return uid ? env.authenticatedContext(uid).firestore() : env.unauthenticatedContext().firestore(); }
function event(labelId = 'label') {
  return {groupId: 'family', labelId, title: '旅行', startDateTime: Timestamp.fromDate(new Date('2026-10-01T00:00:00Z')), endDateTime: Timestamp.fromDate(new Date('2026-10-03T00:00:00Z')), isAllDay: true};
}
async function create(uid, id = 'event', labelId = 'label', count = 1) {
  const store = db(uid); const batch = writeBatch(store);
  batch.set(doc(store, `calendar_events/${id}`), event(labelId));
  batch.update(doc(store, `calendar_labels/${labelId}`), {eventCount: count, lastEventId: id});
  return batch.commit();
}

test('所属メンバー間で予定とラベルを共有し他のメンバーも編集できる', async () => {
  await assertSucceeds(create('alice'));
  const bob = db('bob');
  await assertSucceeds(getDocs(query(collection(bob, 'calendar_events'), where('groupId', '==', 'family'))));
  await assertSucceeds(getDoc(doc(bob, 'calendar_labels/label')));
  await assertSucceeds(updateDoc(doc(bob, 'calendar_events/event'), {title: '変更'}));
  await assertSucceeds(updateDoc(doc(bob, 'calendar_labels/label'), {name: '全員', color: '#FFFFFF'}));
});
test('未認証と非所属のアカウントの読取・作成・更新・削除を拒否する', async () => {
  await create('alice');
  for (const uid of [null, 'outsider']) {
    const store = db(uid);
    for (const path of ['calendar_events/event', 'calendar_labels/label']) {
      await assertFails(getDoc(doc(store, path)));
      await assertFails(updateDoc(doc(store, path), {title: '攻撃'}));
      await assertFails(deleteDoc(doc(store, path)));
    }
    await assertFails(create(uid, 'attack', 'label', 2));
    await assertFails(getDocs(query(collection(store, 'calendar_events'), where('groupId', '==', 'family'))));
    await assertFails(setDoc(doc(store, 'calendar_labels/attack'), {groupId: 'family', name: '攻撃', color: '#FFFFFF', eventCount: 0, lastEventId: null}));
  }
});
test('既存の所属だけからアクセス参照を作成でき所属削除とアカウント変更で直ちに失効する', async () => {
  const bob = db('bob');
  await assertSucceeds(setDoc(doc(bob, 'calendar_memberships/family/accounts/bob'), {memberId: 'friend', membershipId: 'b'}));
  await assertFails(setDoc(doc(db('outsider'), 'calendar_memberships/family/accounts/outsider'), {memberId: 'friend', membershipId: 'b'}));
  await env.withSecurityRulesDisabled(async context => { await deleteDoc(doc(context.firestore(), 'group_members/b')); });
  await assertFails(getDoc(doc(bob, 'calendar_labels/label')));
  await env.withSecurityRulesDisabled(async context => { await updateDoc(doc(context.firestore(), 'members/owner'), {accountId: 'changed'}); });
  await assertFails(getDoc(doc(db('alice'), 'calendar_labels/label')));
});
test('別グループのラベル・グループの変更・不正な期間や必須値を拒否する', async () => {
  await assertFails(create('alice', 'wrong', 'other-label'));
  await create('alice');
  const store = db('alice');
  for (const change of [{groupId: 'other'}, {labelId: 'missing'}, {title: '  '}, {endDateTime: Timestamp.fromMillis(1)}, {isAllDay: 'true'}]) {
    await assertFails(updateDoc(doc(store, 'calendar_events/event'), change));
  }
  await assertFails(updateDoc(doc(store, 'calendar_labels/label'), {groupId: 'other'}));
  await assertFails(updateDoc(doc(store, 'calendar_labels/label'), {color: '#GGGGGG'}));
});
test('予定と参照数を同時に更新し使用中ラベル削除や参照数の改ざんを拒否する', async () => {
  const store = db('alice');
  await assertFails(setDoc(doc(store, 'calendar_events/event'), event()));
  await create('alice');
  await assertFails(deleteDoc(doc(store, 'calendar_labels/label')));
  await assertFails(updateDoc(doc(store, 'calendar_labels/label'), {eventCount: 0}));
  const batch = writeBatch(store);
  batch.delete(doc(store, 'calendar_events/event'));
  batch.update(doc(store, 'calendar_labels/label'), {eventCount: 0, lastEventId: 'event'});
  await assertSucceeds(batch.commit());
  await assertSucceeds(deleteDoc(doc(store, 'calendar_labels/label')));
});
test('予定のラベル変更は両方の参照数を同時に変更した場合だけ許可する', async () => {
  const store = db('alice');
  await assertSucceeds(setDoc(doc(store, 'calendar_labels/new'), {groupId: 'family', name: '太郎', color: '#FFFFFF', eventCount: 0, lastEventId: null}));
  await create('alice');
  await assertFails(updateDoc(doc(store, 'calendar_events/event'), {labelId: 'new'}));
  const batch = writeBatch(store);
  batch.update(doc(store, 'calendar_events/event'), {labelId: 'new'});
  batch.update(doc(store, 'calendar_labels/label'), {eventCount: 0, lastEventId: 'event'});
  batch.update(doc(store, 'calendar_labels/new'), {eventCount: 1, lastEventId: 'event'});
  await assertSucceeds(batch.commit());
  await assertSucceeds(deleteDoc(doc(store, 'calendar_labels/label')));
  await assertFails(deleteDoc(doc(store, 'calendar_labels/new')));
});
test('グループ削除開始後は新規登録や変更を拒否し削除処理は再実行できる', async () => {
  await create('alice');
  await env.withSecurityRulesDisabled(async context => { await updateDoc(doc(context.firestore(), 'groups/family'), {calendarDeleting: true}); });
  await assertFails(create('bob', 'new', 'label', 2));
  await assertFails(updateDoc(doc(db('bob'), 'calendar_events/event'), {title: '変更'}));
  const store = db('alice'); const batch = writeBatch(store);
  batch.delete(doc(store, 'calendar_events/event'));
  batch.update(doc(store, 'calendar_labels/label'), {eventCount: 0, lastEventId: 'event'});
  await assertSucceeds(batch.commit());
  await assertSucceeds(deleteDoc(doc(store, 'calendar_labels/label')));
});
