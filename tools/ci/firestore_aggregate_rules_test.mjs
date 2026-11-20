import {expectCommit, remove, write} from './firestore_rules_fixture.mjs';

const uid = 'verified-user-aggregate';
const cases = [
  ['locations', 'tripId'],
  ['tasks', 'tripId'],
  ['itinerary_items', 'tripId'],
  ['calendar_event_overrides', 'eventId'],
  ['dvc_point_usages', 'contractId'],
  ['dvc_limited_points', 'contractId'],
];
for (const [collection, parentKey] of cases) {
  const path = `${collection}/existing-child`;
  const data = {
    [parentKey]: 'parent-id',
    groupId: 'any-group',
    ...(collection === 'calendar_event_overrides' ? {isCancelled: true} : {}),
  };
  await expectCommit('owner', [write(path, data)], 200, '編集対象を準備');
  await expectCommit(uid, [write(path, {...data, [parentKey]: 'different-parent'})], 403, '別の親への付け替えは拒否');
  await expectCommit(uid, [write(path, {...data, memo: '編集'})], 200, '同じ親を指定した編集を許可');
  await expectCommit(uid, [remove(path)], 200, '削除を許可');
}

await expectCommit(uid, [write('group_members/invalid-id', {
  groupId: 'group',
  memberId: 'member',
})], 403, '所属を示す文書はグループIDとメンバーIDを文書IDに使う');
await expectCommit(uid, [write('group_members/group:member', {
  groupId: 'group',
  memberId: 'member',
  color: '#123456',
})], 200, '正しい文書IDと色の所属を保存できる');
await expectCommit(uid, [write('group_members/group:member', {
  groupId: 'group',
  memberId: 'member',
  color: 'invalid',
})], 403, '所属の色形式を検証する');
