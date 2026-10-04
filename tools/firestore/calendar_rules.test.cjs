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

test('任意のRGB文字色を保存し不正な文字色を拒否する', async () => {
  const store = db('alice');
  const data = {groupId: 'family', name: '全員', color: '#123ABC', textColor: '#Ab12Cd', eventCount: 0, lastEventId: null};
  await assertSucceeds(setDoc(doc(store, 'calendar_labels/text-color'), data));
  await assertSucceeds(updateDoc(doc(store, 'calendar_labels/text-color'), {textColor: '#000000'}));
  for (const textColor of ['white', '#GGGGGG', '#12345', '#12345678', null, 123]) {
    await assertFails(setDoc(doc(store, 'calendar_labels/invalid-color'), {...data, textColor}));
    await assertFails(updateDoc(doc(store, 'calendar_labels/text-color'), {textColor}));
  }
});

test('ラベルの並び順は非負整数として保存し不正値を拒否する', async () => {
  const store = db('alice');
  await assertSucceeds(updateDoc(doc(store, 'calendar_labels/label'), {sortOrder: 3}));
  for (const sortOrder of [-1, 1.5, '1', null]) {
    await assertFails(updateDoc(doc(store, 'calendar_labels/label'), {sortOrder}));
  }
});

test('繰り返し系列と別ラベルの個別回を同時保存し共有・参照数・取消しを維持する', async () => {
  const store = db('alice');
  await setDoc(doc(store, 'calendar_labels/child'), {groupId: 'family', name: '子ども', color: '#123ABC', eventCount: 0, lastEventId: null});
  const original = Timestamp.fromDate(new Date('2026-10-02T00:00:00Z'));
  const batch = writeBatch(store);
  batch.set(doc(store, 'calendar_events/series'), {...event(), recurrenceRule: 'FREQ=DAILY;COUNT=3', timeZone: null,
    referencedLabelIds: ['label', 'child'], overrides: {child: [{originalStartDateTime: original, isCancelled: false,
      title: '移動', startDateTime: original, endDateTime: original, isAllDay: true}]}, cancelledOccurrences: []});
  batch.update(doc(store, 'calendar_labels/label'), {eventCount: 1, lastEventId: 'series'});
  batch.update(doc(store, 'calendar_labels/child'), {eventCount: 1, lastEventId: 'series'});
  await assertSucceeds(batch.commit());
  await assertSucceeds(getDoc(doc(db('bob'), 'calendar_events/series')));
  await assertFails(getDoc(doc(db('outsider'), 'calendar_events/series')));
  await assertFails(deleteDoc(doc(store, 'calendar_labels/child')));
  const cancelled = writeBatch(store);
  cancelled.update(doc(store, 'calendar_events/series'), {referencedLabelIds: ['label'], overrides: {}, cancelledOccurrences: [original]});
  cancelled.update(doc(store, 'calendar_labels/child'), {eventCount: 0, lastEventId: 'series'});
  await assertSucceeds(cancelled.commit());
  await assertSucceeds(deleteDoc(doc(store, 'calendar_labels/child')));
});


test('個別回の参照数省略・別グループ・存在しないラベルをルールで拒否する', async () => {
  const store = db('alice');
  await create('alice');
  await setDoc(doc(store, 'calendar_labels/child'), {groupId: 'family', name: '子', color: '#123ABC', eventCount: 0, lastEventId: null});
  for (const labelId of ['child', 'other-label', 'missing']) {
    await assertFails(updateDoc(doc(store, 'calendar_events/event'), {recurrenceRule: 'FREQ=DAILY',
      referencedLabelIds: ['label', labelId], overrides: {[labelId]: [{originalStartDateTime: event().startDateTime,
        title: '変更', startDateTime: event().startDateTime, endDateTime: event().endDateTime, isAllDay: true}]}, cancelledOccurrences: []}));
  }
});
test('親ラベルを個別回で既に使用しているラベルへ付け替えて参照集合を保つ', async () => {
  const store = db('alice');
  await setDoc(doc(store, 'calendar_labels/child'), {groupId: 'family', name: '子', color: '#123ABC', eventCount: 0, lastEventId: null});
  const batch = writeBatch(store);
  batch.set(doc(store, 'calendar_events/series'), {...event(), recurrenceRule: 'FREQ=DAILY',
    referencedLabelIds: ['label', 'child'], overrides: {child: []}, cancelledOccurrences: []});
  batch.update(doc(store, 'calendar_labels/label'), {eventCount: 1, lastEventId: 'series'});
  batch.update(doc(store, 'calendar_labels/child'), {eventCount: 1, lastEventId: 'series'});
  await assertSucceeds(batch.commit());
  const changed = writeBatch(store);
  changed.update(doc(store, 'calendar_events/series'), {labelId: 'child', referencedLabelIds: ['child']});
  changed.update(doc(store, 'calendar_labels/label'), {eventCount: 0, lastEventId: 'series'});
  await assertSucceeds(changed.commit());
});

test('上限の3ラベルを参照する系列も一括作成・削除できる', async () => {
  const store = db('alice');
  for (const id of ['child', 'friend']) {
    await setDoc(doc(store, `calendar_labels/${id}`), {groupId: 'family', name: id, color: '#123ABC', eventCount: 0, lastEventId: null});
  }
  const batch = writeBatch(store);
  batch.set(doc(store, 'calendar_events/series'), {...event(), recurrenceRule: 'FREQ=DAILY',
    referencedLabelIds: ['label', 'child', 'friend'], overrides: {child: [], friend: []}, cancelledOccurrences: []});
  for (const id of ['label', 'child', 'friend']) batch.update(doc(store, `calendar_labels/${id}`), {eventCount: 1, lastEventId: 'series'});
  await assertSucceeds(batch.commit());
  const deleted = writeBatch(store);
  deleted.delete(doc(store, 'calendar_events/series'));
  for (const id of ['label', 'child', 'friend']) deleted.update(doc(store, `calendar_labels/${id}`), {eventCount: 0, lastEventId: 'series'});
  await assertSucceeds(deleted.commit());
  for (const id of ['label', 'child', 'friend']) await assertSucceeds(deleteDoc(doc(store, `calendar_labels/${id}`)));
});

test('3ラベルを別の3ラベルへ同時置換して読取上限を超える場合は全体を維持する', async () => {
  const store = db('alice');
  const old = ['label', 'child', 'friend'];
  const next = ['new1', 'new2', 'new3'];
  for (const id of ['child', 'friend', ...next]) {
    await setDoc(doc(store, `calendar_labels/${id}`), {groupId: 'family', name: id, color: '#123ABC', eventCount: 0, lastEventId: null});
  }
  const created = writeBatch(store);
  created.set(doc(store, 'calendar_events/series'), {...event(), recurrenceRule: 'FREQ=DAILY', referencedLabelIds: old,
    overrides: {child: [], friend: []}, cancelledOccurrences: []});
  for (const id of old) created.update(doc(store, `calendar_labels/${id}`), {eventCount: 1, lastEventId: 'series'});
  await assertSucceeds(created.commit());
  const replaced = writeBatch(store);
  replaced.update(doc(store, 'calendar_events/series'), {labelId: 'new1', referencedLabelIds: next, overrides: {new2: [], new3: []}});
  for (const id of old) replaced.update(doc(store, `calendar_labels/${id}`), {eventCount: 0, lastEventId: 'series'});
  for (const id of next) replaced.update(doc(store, `calendar_labels/${id}`), {eventCount: 1, lastEventId: 'series'});
  await assertFails(replaced.commit());
  if ((await getDoc(doc(store, 'calendar_events/series'))).data().labelId !== 'label') throw new Error('元の系列が失われました');
  for (const id of old) if ((await getDoc(doc(store, `calendar_labels/${id}`))).data().eventCount !== 1) throw new Error('元の参照数が失われました');
  for (const id of next) if ((await getDoc(doc(store, `calendar_labels/${id}`))).data().eventCount !== 0) throw new Error('失敗した更新が残りました');
});

test('これ以降の分割で両系列と3ラベルの参照数を同時に保存し共有できる', async () => {
  const store = db('alice');
  for (const id of ['child', 'friend']) await setDoc(doc(store, `calendar_labels/${id}`), {groupId: 'family', name: id, color: '#123ABC', eventCount: 0, lastEventId: null});
  const created = writeBatch(store);
  created.set(doc(store, 'calendar_events/series'), {...event(), recurrenceRule: 'FREQ=DAILY;COUNT=5', referencedLabelIds: ['label', 'child', 'friend'], overrides: {child: [], friend: []}});
  for (const id of ['label', 'child', 'friend']) created.update(doc(store, `calendar_labels/${id}`), {eventCount: 1, lastEventId: 'series'});
  await assertSucceeds(created.commit());
  const split = writeBatch(store);
  split.update(doc(store, 'calendar_events/series'), {recurrenceRule: 'FREQ=DAILY;COUNT=2', referencedLabelIds: ['label', 'child'], overrides: {child: []}, splitEventId: 'following'});
  split.set(doc(store, 'calendar_events/following'), {...event('friend'), recurrenceRule: 'FREQ=DAILY;COUNT=3', referencedLabelIds: ['friend'], overrides: {}, splitFromEventId: 'series'});
  await assertSucceeds(split.commit());
  const bob = db('bob');
  const values = await getDocs(query(collection(bob, 'calendar_events'), where('groupId', '==', 'family')));
  if (values.size !== 2) throw new Error('分割した系列を共有できません');
  for (const id of ['label', 'child', 'friend']) if ((await getDoc(doc(bob, `calendar_labels/${id}`))).data().eventCount !== 1) throw new Error('参照数が一致しません');
  await assertSucceeds(updateDoc(doc(bob, 'calendar_events/series'), {title: '再編集', splitEventId: null}));
});
test('同じラベルの系列分割は参照数を増やし省略した分割を拒否する', async () => {
  await create('alice');
  const store = db('alice');
  await updateDoc(doc(store, 'calendar_events/event'), {recurrenceRule: 'FREQ=DAILY;COUNT=5'});
  function split(withCount) {
    const batch = writeBatch(store);
    batch.update(doc(store, 'calendar_events/event'), {recurrenceRule: 'FREQ=DAILY;COUNT=2', splitEventId: 'following'});
    batch.set(doc(store, 'calendar_events/following'), {...event(), recurrenceRule: 'FREQ=DAILY;COUNT=3', splitFromEventId: 'event'});
    if (withCount) batch.update(doc(store, 'calendar_labels/label'), {eventCount: 2, lastEventId: 'event'});
    return batch.commit();
  }
  await assertFails(split(false));
  await assertSucceeds(split(true));
  if ((await getDoc(doc(db('bob'), 'calendar_labels/label'))).data().eventCount !== 2) throw new Error('分割後の参照数が一致しません');
});
test('分割先だけの作成と別グループの分割先は拒否する', async () => {
  await create('alice'); const store = db('alice');
  await assertFails(setDoc(doc(store, 'calendar_events/orphan'), {...event(), recurrenceRule: 'FREQ=DAILY', splitFromEventId: 'event'}));
  const batch = writeBatch(store);
  batch.update(doc(store, 'calendar_events/event'), {recurrenceRule: 'FREQ=DAILY', splitEventId: 'wrong'});
  batch.set(doc(store, 'calendar_events/wrong'), {...event('other-label'), groupId: 'other', recurrenceRule: 'FREQ=DAILY', splitFromEventId: 'event'});
  await assertFails(batch.commit());
});
