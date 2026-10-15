const test = require('node:test');
const assert = require('node:assert/strict');
const { buildLinkPlan } = require('../../../tools/migrations/link_dvc_contracts.js');

const contract = { id: 'c1', groupId: 'g1' };
const usages = [{ id: 'u1', groupId: 'g1' }];
const limited = [{ id: 'l1', groupId: 'g1' }];

test('唯一の契約へ利用履歴と期間限定ポイントを紐付け、再実行で変更しない', () => {
  const plan = buildLinkPlan([contract], usages, limited);
  assert.deepEqual(plan, [
    { collection: 'dvc_point_usages', id: 'u1', contractId: 'c1' },
    { collection: 'dvc_limited_points', id: 'l1', contractId: 'c1' },
  ]);
  assert.deepEqual(buildLinkPlan([contract], [{ ...usages[0], contractId: 'c1' }], [{ ...limited[0], contractId: 'c1' }]), []);
});

for (const contracts of [[], [contract, { ...contract, id: 'c2' }]]) {
  test(`契約が${contracts.length}件の場合は推測で紐付けない`, () => {
    assert.throws(() => buildLinkPlan(contracts, usages, limited), /契約を一意に特定できません/);
  });
}

test('他グループの契約や不正な紐付けを上書きしない', () => {
  assert.throws(() => buildLinkPlan([{ ...contract, groupId: 'g2' }], usages, limited), /契約を一意に特定できません/);
  assert.throws(() => buildLinkPlan([contract], [{ ...usages[0], contractId: 'other' }], limited), /既存の契約参照が不正/);
});
