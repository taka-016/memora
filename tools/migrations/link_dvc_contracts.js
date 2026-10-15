#!/usr/bin/env node

function buildLinkPlan(contracts, pointUsages, limitedPoints) {
  const plan = [];
  for (const [collection, children] of [
    ['dvc_point_usages', pointUsages],
    ['dvc_limited_points', limitedPoints],
  ]) {
    for (const child of children) {
      const parents = contracts.filter((contract) => contract.groupId === child.groupId);
      if (child.contractId != null && child.contractId !== '') {
        if (!parents.some((contract) => contract.id === child.contractId)) {
          throw new Error(`既存の契約参照が不正です: ${collection}/${child.id}`);
        }
        continue;
      }
      if (parents.length !== 1) {
        throw new Error(`契約を一意に特定できません: ${collection}/${child.id}（${parents.length}件）`);
      }
      plan.push({ collection, id: child.id, contractId: parents[0].id });
    }
  }
  return plan;
}

function parseArgs(argv) {
  const options = { apply: false };
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === '--apply') options.apply = true;
    else if (arg === '--project') options.projectId = argv[++index];
    else if (arg === '--group') options.groupId = argv[++index];
    else if (arg === '--help') options.help = true;
    else throw new Error(`不明な引数です: ${arg}`);
  }
  if (!options.help && !options.groupId) throw new Error('--groupで移行対象のグループIDを指定してください');
  return options;
}

async function migrate(db, { groupId, apply }) {
  const snapshots = new Map();
  for (const name of ['dvc_point_contracts', 'dvc_point_usages', 'dvc_limited_points']) {
    const snapshot = await db.collection(name).where('groupId', '==', groupId).get();
    snapshots.set(name, snapshot.docs);
  }
  const records = (name) => snapshots.get(name).map((doc) => ({ ...doc.data(), id: doc.id }));
  const plan = buildLinkPlan(records('dvc_point_contracts'), records('dvc_point_usages'), records('dvc_limited_points'));
  console.log(JSON.stringify({
    mode: apply ? '適用' : '確認のみ', groupId,
    contracts: snapshots.get('dvc_point_contracts').length,
    pointUsages: snapshots.get('dvc_point_usages').length,
    limitedPoints: snapshots.get('dvc_limited_points').length,
    updates: plan.length,
    contractIds: [...new Set(plan.map((item) => item.contractId))],
  }));
  if (!apply || plan.length === 0) return;
  if (plan.length > 500) throw new Error('一括更新の上限500件を超えています。書き込みは行っていません');
  const batch = db.batch();
  for (const item of plan) {
    const doc = snapshots.get(item.collection).find((value) => value.id === item.id);
    batch.update(doc.ref, { contractId: item.contractId }, { lastUpdateTime: doc.updateTime });
  }
  await batch.commit();
  console.log(`紐付け完了: ${plan.length}件。確認のみで再実行し、updatesが0件になることを確認してください。`);
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  if (options.help) {
    console.log('使用方法: node tools/migrations/link_dvc_contracts.js --group GROUP_ID [--project PROJECT_ID] [--apply]\n既定は確認のみ。認証にはGOOGLE_APPLICATION_CREDENTIALSを使用します。');
    return;
  }
  const { initializeApp, applicationDefault } = require('firebase-admin/app');
  const { getFirestore } = require('firebase-admin/firestore');
  const app = initializeApp({ credential: applicationDefault(), projectId: options.projectId });
  try {
    await migrate(getFirestore(app), options);
  } finally {
    await app.delete();
  }
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
  });
}

module.exports = { buildLinkPlan, migrate };
