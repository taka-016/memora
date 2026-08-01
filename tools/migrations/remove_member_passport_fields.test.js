const assert = require('node:assert/strict');
const test = require('node:test');

const {
  buildDeleteUpdate,
  migrateCollection,
  parseArgs,
} = require('./remove_member_passport_fields');

test('削除対象フィールドがある場合だけ更新内容を返す', () => {
  const deleteFieldValue = Symbol('delete');

  assert.deepEqual(
    buildDeleteUpdate(
      { passportNumber: 'AB1234567', passportExpiration: null },
      deleteFieldValue,
    ),
    {
      passportNumber: deleteFieldValue,
      passportExpiration: deleteFieldValue,
    },
  );
  assert.equal(buildDeleteUpdate({ displayName: '山田太郎' }), null);
});

test('既定値はdry-runで明示的なapplyだけ書き込みを有効にする', () => {
  assert.deepEqual(parseArgs([]), {
    apply: false,
    projectId: undefined,
    databaseId: undefined,
    batchSize: 450,
  });
  assert.equal(parseArgs(['--apply']).apply, true);
});

test('dry-runでは対象件数を返してFirestoreへ書き込まない', async () => {
  const commits = [];
  const updates = [];
  const db = createFakeFirestore({ commits, updates });

  const matchedDocs = await migrateCollection({
    db,
    deleteFieldValue: 'DELETE',
    apply: false,
    batchSize: 1,
  });

  assert.equal(matchedDocs, 2);
  assert.deepEqual(updates, []);
  assert.deepEqual(commits, []);
});

test('applyでは対象ドキュメントから両フィールドを削除する', async () => {
  const commits = [];
  const updates = [];
  const db = createFakeFirestore({ commits, updates });

  const matchedDocs = await migrateCollection({
    db,
    deleteFieldValue: 'DELETE',
    apply: true,
    batchSize: 1,
  });

  assert.equal(matchedDocs, 2);
  assert.deepEqual(updates, [
    ['member-1', { passportNumber: 'DELETE' }],
    ['member-2', { passportExpiration: 'DELETE' }],
  ]);
  assert.equal(commits.length, 2);
});

function createFakeFirestore({ commits, updates }) {
  const docs = [
    createFakeDocument('member-1', { passportNumber: 'AB1234567' }),
    createFakeDocument('member-2', { passportExpiration: '2030-01-01' }),
    createFakeDocument('member-3', { displayName: '山田太郎' }),
  ];

  return {
    collection(collectionName) {
      assert.equal(collectionName, 'members');
      return { get: async () => ({ docs }) };
    },
    batch() {
      return {
        update(ref, update) {
          updates.push([ref.id, update]);
        },
        async commit() {
          commits.push(true);
        },
      };
    },
  };
}

function createFakeDocument(id, data) {
  return {
    ref: { id },
    data: () => data,
  };
}
