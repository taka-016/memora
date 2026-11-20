import assert from 'node:assert/strict';
import {commit, expectCommit, remove, root, token, write} from './firestore_rules_fixture.mjs';

const availability = 'app_settings/availability';
const group = 'shared-rules-group';
const trip = 'trip_entries/shared-rules-trip';
const uid = 'verified-user-without-permissions';

async function get(path, bearer) {
  const headers = bearer ? {Authorization: `Bearer ${bearer}`} : {};
  return (await fetch(`${root}/${path}`, {headers})).status;
}

await expectCommit('owner', [
  write(availability, {minimumBuildNumber: 0}),
  write(`groups/${group}`, {ownerId: 'another-member', version: 1}),
], 200, '公開設定と別アカウントのグループを準備');
await expectCommit(uid, [write(trip, {groupId: group, version: 1})], 200, 'メール確認済みならグループに所属していなくても記録を保存できる');
assert.equal(await get(trip, token(uid)), 200);
assert.equal(await get('trip_entries', token(uid)), 200);
assert.equal(await get(trip), 403);
assert.equal(await get(trip, token(uid, false)), 403);
assert.equal(await get(availability), 200);
await expectCommit(uid, [write(availability, {minimumBuildNumber: 1})], 403, 'アプリから利用可否設定を変更できない');
await expectCommit(uid, [write(trip, {groupId: group, version: 3})], 403, 'バージョンを飛ばして更新できない');
await expectCommit(uid, [write(trip, {groupId: group, version: 2})], 200, '次のバージョンへ更新できる');
await expectCommit(uid, [remove(trip)], 200, '記録を削除できる');

const invitation = 'member_invitations/rules-test-code';
const member = 'members/rules-test-invitee';
await expectCommit('another-verified-user', [
  write(member, {accountId: null, ownerId: 'inviter', version: 1}),
  write(invitation, {invitationCode: 'rules-test-code', inviteeId: 'rules-test-invitee', version: 1}),
], 200, '別アカウントが招待を発行できる');
assert.equal(await get(invitation, token(uid)), 200, '招待を取得できる');
await expectCommit(uid, [
  write(member, {accountId: uid, ownerId: 'inviter', version: 2}),
  remove(invitation),
], 200, '受理用の文書なしで招待を受理できる');
await expectCommit('another-verified-user', [
  write(member, {accountId: 'another-verified-user', ownerId: 'inviter', version: 3}),
], 403, '紐づいたアカウントを上書きできない');
for (const collection of ['account_permissions', 'member_invitation_claims']) {
  await expectCommit(uid, [write(`${collection}/obsolete`, {})], 403, '廃止したコレクションに書き込めない');
}

for (const [caseId, attemptTypes] of [
  ['new-new', ['new', 'new']],
  ['new-invite', ['new', 'invited']],
  ['invite-invite', ['invited', 'invited']],
]) {
  const accountId = `register-${caseId}`;
  const registration = `member_account_registrations/${accountId}`;
  const paths = attemptTypes.map((_, index) => `members/${accountId}-${index}`);
  const writes = attemptTypes.map((type, index) => [
    write(registration, {}),
    write(paths[index], {accountId, ownerId: null, version: type === 'new' ? 1 : 2}),
  ]);
  for (const [index, type] of attemptTypes.entries()) {
    if (type === 'invited') {
      await expectCommit('owner', [
        write(paths[index], {accountId: null, ownerId: null, version: 1}),
      ], 200, '招待されたメンバーを用意する');
    }
  }
  const results = await Promise.all(writes.map(batch => commit(accountId, batch)));
  const statuses = results.map(([status]) => status);
  assert.equal(statuses.filter(status => status === 200).length, 1, '同時登録では一方だけ確定する');
  const loser = statuses.findIndex(status => status !== 200);
  assert.ok([403, 409].includes(statuses[loser]), results[loser][1]);
  await expectCommit(accountId, writes[loser], 403, '同じアカウントの再度の登録を拒否する');
  assert.equal(await get(registration, token(accountId)), 403, '登録の競合に使う文書を読み取らない');
  await expectCommit('another-verified-user', [remove(registration)], 403, '別アカウントは登録文書を削除できない');
  await expectCommit(accountId, [remove(registration)], 200, '本人は登録文書を削除できる');
}
