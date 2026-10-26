import assert from 'node:assert/strict';

const host = process.env.FIRESTORE_EMULATOR_HOST;
assert.ok(host, 'Firestore Emulator上で実行してください');
const root = `http://${host}/v1/projects/demo-memora/databases/(default)/documents`;
function token(verified) {
  const encode = value => Buffer.from(JSON.stringify(value)).toString('base64url');
  return `${encode({ alg: 'none', typ: 'JWT' })}.${encode({
    iss: 'https://securetoken.google.com/demo-memora', aud: 'demo-memora',
    sub: 'tester', user_id: 'tester', iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + 3600, email_verified: verified,
    firebase: { sign_in_provider: 'password' },
  })}.`;
}
async function request(path, method, bearer, body) {
  return fetch(`${root}${path}`, {
    method, headers: { 'Content-Type': 'application/json', ...(bearer ? { Authorization: `Bearer ${bearer}` } : {}) },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
}
const collections = ['members', 'member_invitations', 'group_events', 'member_events',
  'trip_entries', 'groups', 'calendar_events', 'dvc_point_contracts', 'calendar_labels'];
const version = value => ({ integerValue: String(value) });
const verified = token(true);
const invalidStoredVersions = [undefined, { nullValue: null }, { stringValue: '1' },
  { doubleValue: 1.0 }, version(0), version(-1)];
for (const collection of collections) {
  const path = `/${collection}/version-test`;
  const write = (fields, bearer = verified) => request(path, 'PATCH', bearer, { fields });
  const seed = fields => write(fields, 'owner');
  const valid = { ...(collection === 'calendar_events' ? { labelType: { stringValue: 'group' }, memberId: { nullValue: null }, labelId: { nullValue: null } } : {}), version: version(1), name: { stringValue: '編集前' } };
  await request(path, 'DELETE', 'owner');
  assert.equal((await write(valid)).status, 200, `${collection}: 初回作成`);
  const next = { ...valid, version: version(2), name: { stringValue: '編集後' } };
  const concurrent = await Promise.all([write(next), write(next)]);
  assert.deepEqual(concurrent.map(value => value.status).sort(), [200, 403], `${collection}: 同時更新`);
  assert.equal((await write(next)).status, 403, `${collection}: 古い期待値`);
  for (const invalid of [undefined, { doubleValue: 3.0 }, { stringValue: '3' }, { nullValue: null }, version(2), version(4)]) {
    const fields = { ...next, version: invalid };
    if (invalid === undefined) delete fields.version;
    assert.equal((await write(fields)).status, 403, `${collection}: 不正な更新値 ${JSON.stringify(invalid)}`);
  }
  for (const invalid of [undefined, { stringValue: '1' }, { doubleValue: 1.0 }, version(0), version(2)]) {
    await request(path, 'DELETE', 'owner');
    const fields = { ...valid, version: invalid };
    if (invalid === undefined) delete fields.version;
    assert.equal((await write(fields)).status, 403, `${collection}: 不正な初期値`);
    await seed(fields);
    assert.equal((await write(next)).status, 403, `${collection}: 不正な既存値`);
  }
  for (const invalid of invalidStoredVersions) {
    const fields = { ...valid, version: invalid };
    if (invalid === undefined) delete fields.version;
    await seed(fields);
    assert.equal((await request(path, 'DELETE', verified)).status, 403, `${collection}: 未初期化・不正バージョンの削除拒否`);
  }
  await seed(valid);
  assert.equal((await request(path, 'DELETE', verified)).status, 200, `${collection}: 初期化済みの削除`);
  for (const bearer of [null, token(false)]) {
    await request(path, 'DELETE', 'owner');
    assert.equal((await write(valid, bearer)).status, 403, `${collection}: 認証なしの作成`);
    await seed(valid);
    assert.equal((await write(next, bearer)).status, 403, `${collection}: 認証なしの更新`);
    assert.equal((await request(path, 'DELETE', bearer)).status, 403, `${collection}: 認証なしの削除`);
  }
  assert.equal((await request(`${path}/nested/doc`, 'PATCH', verified, { fields: valid })).status, 403, `${collection}: 再帰ルールの迂回`);
}
assert.equal((await request('/unknown/doc', 'PATCH', verified, { fields: {} })).status, 403, '未知のコレクションの迂回');
console.log('全対象のバージョン・同時更新・認証・迂回拒否を確認しました');

const labelPath = '/calendar_labels/count-test';
const seedLabel = { version: version(7), name: { stringValue: '家族' }, color: { stringValue: '#112233' }, sortOrder: version(0), eventCount: version(1) };
await request(labelPath, 'PATCH', 'owner', { fields: seedLabel });
assert.equal((await request(labelPath, 'PATCH', verified, { fields: { ...seedLabel, eventCount: version(2) } })).status, 200, '内部件数だけの更新');
for (const field of ['version', 'name', 'color', 'sortOrder']) {
  const changed = { ...seedLabel, eventCount: version(3), [field]: field === 'version' || field === 'sortOrder' ? version(7) : { stringValue: '変更' } };
  if (field === 'version') changed.version = version(6);
  assert.equal((await request(labelPath, 'PATCH', verified, { fields: changed })).status, 403, `内部件数ルールによる${field}の迂回`);
}

for (const invalid of invalidStoredVersions) {
  const fields = { ...seedLabel, version: invalid };
  if (invalid === undefined) delete fields.version;
  await request(labelPath, 'PATCH', 'owner', { fields });
  assert.equal((await request(labelPath, 'PATCH', verified, { fields: { ...fields, eventCount: version(2) } })).status, 403, '未初期化・不正バージョンのラベル内部更新拒否');
}
