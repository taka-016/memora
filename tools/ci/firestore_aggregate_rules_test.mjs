import assert from 'node:assert/strict';

const host = process.env.FIRESTORE_EMULATOR_HOST;
assert.ok(host, 'Firestore Emulator上で実行してください');
const root = `http://${host}/v1/projects/demo-memora/databases/(default)/documents`;
const encode = value => Buffer.from(JSON.stringify(value)).toString('base64url');
const token = `${encode({ alg: 'none', typ: 'JWT' })}.${encode({
  iss: 'https://securetoken.google.com/demo-memora', aud: 'demo-memora',
  sub: 'tester', user_id: 'tester', iat: Math.floor(Date.now() / 1000),
  exp: Math.floor(Date.now() / 1000) + 3600, email_verified: true,
  firebase: { sign_in_provider: 'password' },
})}.`;
const integer = value => ({ integerValue: String(value) });
const string = value => ({ stringValue: value });
const write = (path, fields) => ({ update: { name: `${root.split('/v1/')[1]}/${path}`, fields: { ...(path.startsWith('calendar_events/') ? { labelType: string('group'), memberId: { nullValue: null }, labelId: { nullValue: null } } : path.startsWith('calendar_event_overrides/') ? { isCancelled: { booleanValue: true } } : {}), ...fields } } });
const remove = path => ({ delete: `${root.split('/v1/')[1]}/${path}` });
async function commit(writes, bearer = token) {
  return fetch(`${root}:commit`, {
    method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${bearer}` },
    body: JSON.stringify({ writes }),
  });
}
async function expectCommit(writes, status, message) {
  const result = await commit(writes);
  const body = await result.text();
  assert.equal(result.status, status, `${message}: ${body}`);
}
const cases = [
  ['trip_entries', 'locations', 'tripId'],
  ['trip_entries', 'tasks', 'tripId'],
  ['trip_entries', 'itinerary_items', 'tripId'],
  ['groups', 'group_members', 'groupId'],
  ['calendar_events', 'calendar_event_overrides', 'eventId'],
  ['dvc_point_contracts', 'dvc_point_usages', 'contractId'],
  ['dvc_point_contracts', 'dvc_limited_points', 'contractId'],
];
for (const [parents, children, foreignKey] of cases) {
  const id = `aggregate-${children}`;
  const parent = `${parents}/${id}`;
  const child = `${children}/${id}`;
  const otherParent = `${parents}/${id}-other`;
  const parentFields = version => ({ version: integer(version) });
  const childFields = { [foreignKey]: string(id), name: string('編集前') };
  await commit([remove(child), remove(parent), remove(otherParent)], 'owner');
  await expectCommit([write(child, childFields)], 403, `${children}: 親のない追加`);
  await expectCommit([write(parent, parentFields(1)), write(child, childFields)], 200, `${children}: 親子の初回作成`);
  for (const operation of [write(child, { ...childFields, name: string('変更') }), remove(child), write(`${child}-new`, childFields)]) {
    await expectCommit([operation], 403, `${children}: 親更新なしの追加変更削除`);
  }
  await expectCommit([write(parent, parentFields(2)), write(child, { ...childFields, name: string('変更') })], 200, `${children}: 親子の更新`);
  const concurrent = await Promise.all([
    commit([write(parent, parentFields(3)), write(`${child}-a`, childFields)]),
    commit([write(parent, parentFields(3)), write(`${child}-b`, childFields)]),
  ]);
  assert.deepEqual(concurrent.map(value => value.status).sort(), [200, 403], `${children}: 異なる子の同時編集`);
  await expectCommit([write(parent, parentFields(3)), remove(child)], 403, `${children}: 古い期待値の再試行`);
  await expectCommit([write(parent, parentFields(4)), write(otherParent, parentFields(1)), write(child, { ...childFields, [foreignKey]: string(`${id}-other`) })], 403, `${children}: 親参照付け替えの迂回`);
  await expectCommit([write(parent, parentFields(4)), remove(child)], 200, `${children}: 親更新と子の削除`);
  await expectCommit([write(parent, parentFields(5)), write(child, childFields)], 200, `${children}: 子の再追加`);
  // 親の更新が不正な場合、子の全件置換も反映されない。
  await expectCommit([write(parent, parentFields(5)), remove(child), write(`${child}-replacement`, childFields)], 403, `${children}: 置換全体の拒否`);
  await expectCommit([remove(parent), remove(child)], 200, `${children}: 親子の物理削除`);
  await expectCommit([remove(`${child}-a`)], 403, `${children}: 既に親がない子の直接削除`);
  await expectCommit([remove(`${child}-b`)], 403, `${children}: 既に親がない子の直接削除`);
}
// DVCはグループと別の競合単位で、契約ごとに独立する。
await commit([remove('groups/independent'), remove('dvc_point_contracts/independent')], 'owner');
await expectCommit([write('groups/independent', { version: integer(1) }), write('dvc_point_contracts/independent', { version: integer(1) })], 200, 'グループとDVC契約の初回作成');
const independent = await Promise.all([
  commit([write('groups/independent', { version: integer(2) })]),
  commit([write('dvc_point_contracts/independent', { version: integer(2) }), write('dvc_point_usages/independent', { contractId: string('independent') })]),
]);
assert.deepEqual(independent.map(value => value.status), [200, 200], 'グループ編集とDVC契約編集の独立性');
console.log('旅行・グループ・DVCの親子の原子性・競合・直接更新と付け替え拒否を確認しました');

// 親ごとに最大3参照（getAfter・exists・get）。6親でも保守的に18参照以内。
// 同じ親を持つ子の参照はキャッシュされ、ラベル更新自体に追加参照はない。
const mixed = [
  ['trip_entries', 'tasks', 'tripId'],
  ['trip_entries', 'itinerary_items', 'tripId'],
  ['groups', 'group_members', 'groupId'],
  ['groups', 'group_members', 'groupId'],
  ['calendar_events', 'calendar_event_overrides', 'eventId'],
  ['calendar_events', 'calendar_event_overrides', 'eventId'],
];
const mixedWrites = version => mixed.flatMap(([parents, children, key], index) => {
  const id = `mixed-limit-${index}`;
  return [
    write(`${parents}/${id}`, { version: integer(version) }),
    ...Array.from({ length: 3 }, (_, child) => write(`${children}/${id}-${child}`, {
      [key]: string(id), name: string(`更新${version}`),
    })),
  ];
});
await commit(mixedWrites(1), 'owner');
const labelWrites = Array.from({ length: 5 }, (_, index) => write(`calendar_labels/mixed-limit-${index}`, {
  version: integer(1), eventCount: integer(0), name: string('ラベル'),
}));
await commit(labelWrites, 'owner');
const countWrites = labelWrites.map(value => ({ ...value, update: {
  ...value.update, fields: { ...value.update.fields, eventCount: integer(1) },
} }));
await expectCommit([...mixedWrites(2), ...countWrites], 200, '複数旅行・グループ・予定・ラベルを一括保存しアクセス回数制限内で成功');
console.log('個別回の親更新条件と複数集約・ラベルのアクセス回数制限内での保存を確認しました');
const begun = await fetch(`${root}:beginTransaction`, {
  method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
  body: JSON.stringify({ options: { readWrite: {} } }),
});
assert.equal(begun.status, 200, '複数集約を保存するトランザクションの開始');
const { transaction } = await begun.json();
const committed = await fetch(`${root}:commit`, {
  method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
  body: JSON.stringify({ writes: mixedWrites(3), transaction }),
});
assert.equal(committed.status, 200, `トランザクションもアクセス回数制限内で成功: ${await committed.text()}`);
