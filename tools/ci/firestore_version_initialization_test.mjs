import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const { migrate, createClient } = require('../migrations/initialize_firestore_versions.js');
const host = process.env.FIRESTORE_EMULATOR_HOST;
assert.ok(host, 'Firestore Emulator上で実行してください');
const project = 'demo-memora';
const client = createClient({ project, database: '(default)', host });
const root = `http://${host}/v1/projects/${project}/databases/(default)/documents`;
const integer = value => ({ integerValue: String(value) });
const string = value => ({ stringValue: value });
const targets = ['members', 'member_invitations', 'group_events', 'member_events',
  'trip_entries', 'groups', 'calendar_events', 'dvc_point_contracts', 'calendar_labels'];
const strict = await readFile(new URL('../../firestore.rules', import.meta.url), 'utf8');
const stopped = await readFile(new URL('../migrations/firestore_write_stop.rules', import.meta.url), 'utf8');
// Rulesの対象追加時に管理処理の初期化漏れを検出する。
const defined = strict.match(/function isVersionedCollection\(collection\)\s*\{\s*return collection in \[([^\]]+)\]/)[1];
assert.deepEqual([...defined.matchAll(/'([^']+)'/g)].map(match => match[1]).sort(), [...targets].sort());
async function rules(content) {
  const response = await fetch(`http://${host}/emulator/v1/projects/${project}:securityRules`, {
    method: 'PUT', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ rules: { files: [{ name: 'firestore.rules', content }] } }),
  });
  assert.equal(response.status, 200, await response.text());
}
const encode = value => Buffer.from(JSON.stringify(value)).toString('base64url');
const token = `${encode({ alg: 'none', typ: 'JWT' })}.${encode({
  iss: `https://securetoken.google.com/${project}`, aud: project,
  sub: 'tester', user_id: 'tester', iat: Math.floor(Date.now() / 1000),
  exp: Math.floor(Date.now() / 1000) + 3600, email_verified: true,
  firebase: { sign_in_provider: 'password' },
})}.`;
async function request(path, method, fields, bearer = 'owner') {
  return fetch(`${root}/${path}`, {
    method, headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${bearer}` },
    ...(fields ? { body: JSON.stringify({ fields }) } : {}),
  });
}
async function seed(path, fields) {
  const response = await request(path, 'PATCH', fields);
  assert.equal(response.status, 200, await response.text());
}
async function get(path) {
  const response = await request(path, 'GET');
  assert.equal(response.status, 200);
  return (await response.json()).fields;
}
const logs = [];
const run = (apply = false, source = client) => migrate(source, { apply, log: value => logs.push(value) });
try {
  // 専用Emulatorの全データを初期化する。本番接続は冒頭で禁止している。
  await fetch(`http://${host}/emulator/v1/projects/${project}/databases/(default)/documents`, { method: 'DELETE' });
  await rules(stopped);
  for (const collection of targets) {
    await seed(`${collection}/old`, { name: string('既存'), ...(collection === 'dvc_point_contracts' ? { groupId: string('g') } : {}) });
    await seed(`${collection}/initialized`, { version: integer(7), ...(collection === 'dvc_point_contracts' ? { groupId: string('g') } : {}) });
  }
  await seed('dvc_point_usages/child', { contractId: string('old'), groupId: string('g') });
  await seed('dvc_limited_points/child', { contractId: string('initialized'), groupId: string('g') });
  await seed('deleted_groups/archive', { name: string('退避') });
  for (const collection of [...targets, 'locations', 'tasks', 'itinerary_items', 'group_members', 'calendar_event_overrides', 'dvc_point_usages', 'dvc_limited_points', 'deleted_groups', 'deleted_members']) {
    assert.equal((await request(`${collection}/new`, 'PATCH', { version: integer(1) }, token)).status, 403, `${collection}: 停止中の作成拒否`);
    await seed(`${collection}/stop-check`, { version: integer(1), ...(collection.startsWith('dvc_') ? { groupId: string('g'), contractId: string('old') } : {}) });
    assert.equal((await request(`${collection}/stop-check`, 'PATCH', { version: integer(2) }, token)).status, 403, `${collection}: 停止中の更新拒否`);
    assert.equal((await request(`${collection}/stop-check`, 'DELETE', undefined, token)).status, 403, `${collection}: 停止中の削除拒否`);
    await request(`${collection}/stop-check`, 'DELETE');
  }
  assert.equal((await request('members/old', 'GET', undefined, token)).status, 200, '停止中も既存データを読める');
  let report = await run();
  assert.equal(report.missing, targets.length);
  assert.equal(report.complete, false);
  assert.equal((await get('members/old')).version, undefined, '事前確認は変更しない');
  for (const invalid of [integer(0), integer(-1), { doubleValue: 1 }, string('1'), { nullValue: null }]) {
    await seed('members/invalid', { version: invalid });
    report = await run(true);
    assert.equal(report.invalid, 1);
    assert.equal(report.complete, false);
    assert.equal((await get('members/old')).version, undefined, '不正値がある間は初期化しない');
  }
  await request('members/invalid', 'DELETE');
  await seed('dvc_point_usages/unlinked', { groupId: string('g') });
  assert.equal((await run(true)).invalid, 1, '契約未紐付けを拒否');
  await seed('dvc_point_usages/unlinked', { groupId: string('different'), contractId: string('old') });
  assert.equal((await run(true)).invalid, 1, '契約とのグループ不一致を拒否');
  await request('dvc_point_usages/unlinked', 'DELETE');
  let writes = 0;
  const interrupted = {
    list: client.list,
    initialize: async doc => {
      if (++writes === 3) throw new Error('テスト用の途中停止');
      return client.initialize(doc);
    },
  };
  await assert.rejects(run(true, interrupted), /テスト用の途中停止/);
  assert.equal((await run()).missing, targets.length - 2, '途中までの成功を保持');
  report = await run(true);
  assert.equal(report.complete, true, '再実行で全件検証まで完了');
  assert.equal((await run(true)).updated, 0, '再実行で巻き戻さない');
  for (const collection of targets) {
    assert.deepEqual((await get(`${collection}/old`)).version, integer(1));
    assert.deepEqual((await get(`${collection}/initialized`)).version, integer(7));
  }
  assert.equal((await get('deleted_groups/archive')).version, undefined, '対象外を変更しない');
  // 取得後に管理者が更新しても、初期化が上書きしない。
  await seed('members/race', { name: string('取得時') });
  const stale = (await client.list('members')).find(doc => doc.name.endsWith('/race'));
  await seed('members/race', { version: integer(9) });
  await assert.rejects(client.initialize(stale));
  assert.deepEqual((await get('members/race')).version, integer(9));
  await rules(strict);
  await seed('members/missed', { name: string('未初期化') });
  assert.equal((await run()).complete, false, '全件検証で初期化漏れを検出');
  for (const method of ['PATCH', 'DELETE']) {
    assert.equal((await request('members/missed', method, method === 'PATCH' ? { version: integer(1) } : undefined, token)).status, 403, '切替後も未初期化の編集を拒否');
  }
  await seed('calendar_labels/missed', { eventCount: integer(0) });
  assert.equal((await request('calendar_labels/missed', 'PATCH', { eventCount: integer(1) }, token)).status, 403, '未初期化ラベルの内部更新を拒否');
  assert.equal((await request('members/old', 'PATCH', { version: integer(2), name: string('保存成功') }, token)).status, 200, '切替後の保存成功');
  assert.equal((await request('members/old', 'PATCH', { version: integer(2) }, token)).status, 403, '古い期待値を拒否');
  assert.ok(logs.length > 0, '件数と完了状況を出力');
  console.log('初期化・不正値・DVC紐付け・再実行・途中復旧・停止・厳格Rules切替を確認しました');
} finally {
  await rules(strict);
}
