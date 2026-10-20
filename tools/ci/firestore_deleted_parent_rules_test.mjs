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
for (const table of ['groups', 'members']) {
  for (const [label, bearer, allowed] of [['確認済み', token(true), true], ['未確認', token(false), false], ['未認証', null, false]]) {
    const id = `${table}-${allowed ? 'verified' : bearer ? 'unverified' : 'anonymous'}`;
    const source = `${root.split('/v1/')[1]}/${table}/${id}`;
    const target = `${root.split('/v1/')[1]}/deleted_${table}/${id}`;
    const fields = { version: { integerValue: '1' }, ownerId: { stringValue: 'tester' }, name: { stringValue: '退避情報' } };
    assert.equal((await request(`/${table}/${id}`, 'PATCH', 'owner', { fields })).status, 200);
    const response = await request(':commit', 'POST', bearer, { writes: [
      { update: { name: target, fields } }, { delete: source },
    ] });
    assert.equal(response.status, allowed ? 200 : 403, `${table}: ${label}: ${await response.text()}`);
    const original = await request(`/${table}/${id}`, 'GET', 'owner');
    const archived = await request(`/deleted_${table}/${id}`, 'GET', 'owner');
    assert.equal(original.status, allowed ? 404 : 200);
    assert.equal(archived.status, allowed ? 200 : 404);
    if (allowed) assert.deepEqual((await archived.json()).fields, fields);
  }
}
console.log('グループ・メンバー退避の認証条件と原子的書き込みを確認しました');
