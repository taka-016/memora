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
const string = value => ({ stringValue: value });
const integer = value => ({ integerValue: String(value) });
const nil = { nullValue: null };
const reference = (type, member = nil, label = nil) => ({ labelType: string(type), memberId: member, labelId: label });
async function put(path, fields) {
  const response = await fetch(`${root}/${path}`, {
    method: 'PATCH', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
    body: JSON.stringify({ fields }),
  });
  return [response.status, await response.text()];
}
for (const [name, fields, status] of [
  ['group', reference('group'), 200],
  ['member', reference('member', string('m')), 200],
  ['custom', reference('custom', nil, string('l')), 200],
  ['unknown', reference('invalid'), 403],
  ['missing-member', reference('member'), 403],
  ['extra-label', reference('group', nil, string('l')), 403],
  ['missing-label', reference('custom'), 403],
]) {
  const [actual, body] = await put(`calendar_events/reference-${name}`, { ...fields, version: integer(1) });
  assert.equal(actual, status, `${name}: ${body}`);
}
// 個別回も親の競合検出と参照種別を同じ書き込みで検証する。
const documentRoot = root.split('/v1/')[1];
const parent = `${documentRoot}/calendar_events/reference-parent`;
const child = `${documentRoot}/calendar_event_overrides/reference-child`;
const response = await fetch(`${root}:commit`, {
  method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
  body: JSON.stringify({ writes: [
    { update: { name: parent, fields: { ...reference('group'), version: integer(1) } } },
    { update: { name: child, fields: { ...reference('member', string('m')), eventId: string('reference-parent'), isCancelled: { booleanValue: false } } } },
  ] }),
});
assert.equal(response.status, 200, await response.text());
console.log('固定・任意ラベルの参照種別と個別回の保存を確認しました');
