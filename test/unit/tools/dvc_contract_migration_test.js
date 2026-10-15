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

const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { migrate } = require('../../../tools/migrations/link_dvc_contracts.js');

test('適用前にバックアップを保存し、取得時点の更新日時を条件に紐付けだけを一括更新する', async () => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'dvc-migration-'));
  const backupPath = path.join(directory, 'before.json');
  const writes = [];
  let commits = 0;
  const db = {
    collection(name) {
      const data = name === 'dvc_point_contracts' ? [contract] : name === 'dvc_point_usages' ? usages : limited;
      return { where() { return { async get() { return { docs: data.map((row) => ({ id: row.id, data: () => row, ref: `${name}/${row.id}`, updateTime: '取得時点' })) }; } }; } };
    },
    batch() {
      return {
        update(...args) { writes.push(args); },
        async commit() {
          assert.equal(fs.existsSync(backupPath), true);
          commits += 1;
        },
      };
    },
  };
  try {
    await migrate(db, { groupId: 'g1', apply: true, backupPath });
    const backup = JSON.parse(fs.readFileSync(backupPath, 'utf8'));
    assert.equal(backup.groupId, 'g1');
    assert.equal(backup.tables.dvc_point_usages[0].id, 'u1');
    assert.deepEqual(writes, [
      ['dvc_point_usages/u1', { contractId: 'c1' }, { lastUpdateTime: '取得時点' }],
      ['dvc_limited_points/l1', { contractId: 'c1' }, { lastUpdateTime: '取得時点' }],
    ]);
    assert.equal(commits, 1);
  } finally {
    fs.rmSync(directory, { recursive: true, force: true });
  }
});
