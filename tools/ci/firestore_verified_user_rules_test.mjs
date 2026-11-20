import assert from 'node:assert/strict';
import {expectCommit, remove, root, token, write} from './firestore_rules_fixture.mjs';

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
