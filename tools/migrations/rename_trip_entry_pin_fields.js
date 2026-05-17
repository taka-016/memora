#!/usr/bin/env node

const tripEntryRenames = {
  tripName: 'name',
  tripYear: 'year',
  tripStartDate: 'startDate',
  tripEndDate: 'endDate',
  tripMemo: 'memo',
};

const pinRenames = {
  visitStartDate: 'visitStartDateTime',
  visitEndDate: 'visitEndDateTime',
  visitMemo: 'memo',
};

function hasOwn(data, key) {
  return Object.prototype.hasOwnProperty.call(data, key);
}

function buildRenameUpdate(data, renames, deleteFieldValue) {
  const update = {};
  let changed = false;

  for (const [oldField, newField] of Object.entries(renames)) {
    if (!hasOwn(data, oldField)) {
      continue;
    }

    if (!hasOwn(data, newField)) {
      update[newField] = data[oldField];
    }
    update[oldField] = deleteFieldValue;
    changed = true;
  }

  return changed ? update : null;
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
      throw new Error(`Unknown option: ${arg}`);
    }
  }

  if (!Number.isInteger(options.batchSize) || options.batchSize < 1) {
    throw new Error('--batch-size must be a positive integer.');
  }
  if (options.batchSize > 500) {
    throw new Error('--batch-size must be 500 or less.');
  }

  return options;
}

function printUsage() {
  console.log(`Usage:
  node tools/migrations/rename_trip_entry_pin_fields.js [--apply] [--project PROJECT_ID] [--database DATABASE_ID] [--batch-size 450]

Description:
  Renames Firestore fields without overwriting already-migrated values.
  Default mode is dry-run. Pass --apply to write changes.

Required auth:
  Use Application Default Credentials, for example:
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
  collectionName,
  renames,
  deleteFieldValue,
  apply,
  batchSize,
}) {
  const snapshot = await db.collection(collectionName).get();
  let batch = db.batch();
  let pendingWrites = 0;
  let matchedDocs = 0;

  for (const doc of snapshot.docs) {
    const update = buildRenameUpdate(doc.data(), renames, deleteFieldValue);
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
  const deleteFieldValue = FieldValue.delete();

  const tripEntries = await migrateCollection({
    db,
    collectionName: 'trip_entries',
    renames: tripEntryRenames,
    deleteFieldValue,
    apply: options.apply,
    batchSize: options.batchSize,
  });

  const pins = await migrateCollection({
    db,
    collectionName: 'pins',
    renames: pinRenames,
    deleteFieldValue,
    apply: options.apply,
    batchSize: options.batchSize,
  });

  return { tripEntries, pins };
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  if (options.help) {
    printUsage();
    return;
  }

  const result = await migrateFirestore(options);
  const mode = options.apply ? 'applied' : 'dry-run';
  console.log(
    `[${mode}] trip_entries: ${result.tripEntries} docs, pins: ${result.pins} docs`,
  );
  if (!options.apply) {
    console.log('No writes were performed. Re-run with --apply to update.');
  }
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}

module.exports = {
  buildRenameUpdate,
  parseArgs,
  pinRenames,
  tripEntryRenames,
};
