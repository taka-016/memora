#!/usr/bin/env node

const passportFields = ['passportNumber', 'passportExpiration'];

function hasOwn(data, key) {
  return Object.prototype.hasOwnProperty.call(data, key);
}

function buildDeleteUpdate(data, deleteFieldValue) {
  const update = {};

  for (const field of passportFields) {
    if (hasOwn(data, field)) {
      update[field] = deleteFieldValue;
    }
  }

  return Object.keys(update).length > 0 ? update : null;
}

function parseArgs(argv) {
  const options = {
    apply: false,
    projectId: undefined,
    databaseId: undefined,
    batchSize: 450,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--apply') {
      options.apply = true;
    } else if (arg === '--project') {
      options.projectId = argv[++i];
    } else if (arg === '--database') {
      options.databaseId = argv[++i];
    } else if (arg === '--batch-size') {
      options.batchSize = Number(argv[++i]);
    } else if (arg === '--help' || arg === '-h') {
      options.help = true;
    } else {
      throw new Error(`不明なオプションです: ${arg}`);
    }
  }

  if (!Number.isInteger(options.batchSize) || options.batchSize < 1) {
    throw new Error('--batch-sizeには正の整数を指定してください。');
  }
  if (options.batchSize > 500) {
    throw new Error('--batch-sizeには500以下を指定してください。');
  }

  return options;
}

function printUsage() {
  console.log(`使用方法:
  node tools/migrations/remove_member_passport_fields.js [--apply] [--project PROJECT_ID] [--database DATABASE_ID] [--batch-size 450]

説明:
  membersコレクションからpassportNumberとpassportExpirationを削除します。
  既定ではdry-runを実行し、--applyを指定した場合だけ書き込みます。

認証:
  Application Default Credentialsを使用してください。例:
  export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json`);
}

function initializeFirestore(options) {
  const { initializeApp, applicationDefault } = require('firebase-admin/app');
  const { getFirestore } = require('firebase-admin/firestore');

  initializeApp({
    credential: applicationDefault(),
    projectId: options.projectId,
  });

  return options.databaseId ? getFirestore(options.databaseId) : getFirestore();
}

async function migrateCollection({
  db,
  deleteFieldValue,
  apply,
  batchSize,
}) {
  const snapshot = await db.collection('members').get();
  let batch = db.batch();
  let pendingWrites = 0;
  let matchedDocs = 0;

  for (const doc of snapshot.docs) {
    const update = buildDeleteUpdate(doc.data(), deleteFieldValue);
    if (update == null) {
      continue;
    }

    matchedDocs += 1;
    if (!apply) {
      continue;
    }

    batch.update(doc.ref, update);
    pendingWrites += 1;

    if (pendingWrites >= batchSize) {
      await batch.commit();
      batch = db.batch();
      pendingWrites = 0;
    }
  }

  if (apply && pendingWrites > 0) {
    await batch.commit();
  }

  return matchedDocs;
}

async function migrateFirestore(options) {
  const { FieldValue } = require('firebase-admin/firestore');
  const db = initializeFirestore(options);

  return migrateCollection({
    db,
    deleteFieldValue: FieldValue.delete(),
    apply: options.apply,
    batchSize: options.batchSize,
  });
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  if (options.help) {
    printUsage();
    return;
  }

  const matchedDocs = await migrateFirestore(options);
  const mode = options.apply ? 'apply' : 'dry-run';
  console.log(`[${mode}] members: ${matchedDocs}件`);
  if (!options.apply) {
    console.log('書き込みは行っていません。反映する場合は--applyを指定してください。');
  }
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}

module.exports = {
  buildDeleteUpdate,
  migrateCollection,
  parseArgs,
};
