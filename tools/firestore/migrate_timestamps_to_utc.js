#!/usr/bin/env node

const admin = require('firebase-admin');

const dryRun = process.argv.includes('--dry-run');

const timestampTargets = [
  { collection: 'groups', fields: ['createdAt', 'updatedAt'] },
  { collection: 'group_members', fields: ['createdAt', 'updatedAt'] },
  { collection: 'group_events', fields: ['createdAt', 'updatedAt'] },
  { collection: 'members', fields: ['createdAt', 'updatedAt'] },
  { collection: 'member_events', fields: ['createdAt', 'updatedAt'] },
  { collection: 'member_invitations', fields: ['createdAt', 'updatedAt'] },
  { collection: 'trip_entries', fields: ['createdAt', 'updatedAt'] },
  {
    collection: 'pins',
    fields: ['createdAt', 'updatedAt', 'visitStartDate', 'visitEndDate'],
  },
  { collection: 'tasks', fields: ['createdAt', 'updatedAt'] },
  { collection: 'dvc_point_contracts', fields: ['createdAt', 'updatedAt'] },
  { collection: 'dvc_limited_points', fields: ['createdAt', 'updatedAt'] },
  { collection: 'dvc_point_usages', fields: ['createdAt', 'updatedAt'] },
];

function isTimestamp(value) {
  return (
    value &&
    typeof value.seconds === 'number' &&
    typeof value.nanoseconds === 'number'
  );
}

function normalizeTimestamp(value) {
  if (!isTimestamp(value)) {
    return null;
  }
  return new admin.firestore.Timestamp(value.seconds, value.nanoseconds);
}

async function migrateCollection(db, target) {
  const snapshot = await db.collection(target.collection).get();
  let checkedFields = 0;
  let updatedDocs = 0;
  let skippedFields = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const updates = {};

    for (const field of target.fields) {
      if (!(field in data) || data[field] == null) {
        continue;
      }
      checkedFields += 1;
      const normalized = normalizeTimestamp(data[field]);
      if (normalized == null) {
        skippedFields += 1;
        console.warn(
          `[skip] ${target.collection}/${doc.id}.${field} is not Timestamp`,
        );
        continue;
      }
      updates[field] = normalized;
    }

    if (Object.keys(updates).length === 0) {
      continue;
    }

    updatedDocs += 1;
    if (!dryRun) {
      await doc.ref.update(updates);
    }
  }

  return { checkedFields, updatedDocs, skippedFields };
}

async function main() {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
  const db = admin.firestore();

  let totalCheckedFields = 0;
  let totalUpdatedDocs = 0;
  let totalSkippedFields = 0;

  for (const target of timestampTargets) {
    const result = await migrateCollection(db, target);
    totalCheckedFields += result.checkedFields;
    totalUpdatedDocs += result.updatedDocs;
    totalSkippedFields += result.skippedFields;
    console.log(
      [
        `[${target.collection}]`,
        `checkedFields=${result.checkedFields}`,
        `targetDocs=${result.updatedDocs}`,
        `skippedFields=${result.skippedFields}`,
      ].join(' '),
    );
  }

  console.log(
    [
      dryRun ? '[dry-run]' : '[updated]',
      `checkedFields=${totalCheckedFields}`,
      `targetDocs=${totalUpdatedDocs}`,
      `skippedFields=${totalSkippedFields}`,
    ].join(' '),
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
