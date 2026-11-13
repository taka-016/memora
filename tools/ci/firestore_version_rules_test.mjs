import assert from 'node:assert/strict';
import {fixture,write,remove,expectCommit,commit,archivedDelete,raw,token} from './firestore_rules_fixture.mjs';
const f=await fixture('versions',['version-groups']);
const invalidStored=[undefined,null,'1',raw({doubleValue:1}),0,-1];
for(const collection of ['members','member_invitations','group_events','member_events','trip_entries','groups','calendar_events','dvc_point_contracts','calendar_labels']) {
  const id=`version-${collection}`, path=`${collection}/${id}`;
  const base={version:1,groupId:f.group,name:'編集前',...(collection==='members'?{accountId:null,ownerId:f.member,groupIds:[],managedGroupIds:[]}:{}),...(collection==='groups'?{ownerId:f.member}:{}),...(collection==='member_invitations'?{inviterId:f.member,inviteeId:f.invitee,invitationCode:id}:{}),...(collection==='calendar_events'?{labelType:'group',memberId:null,labelId:null}:{}),...(collection==='calendar_labels'?{eventCount:0}: {})};
  await expectCommit('owner',[remove(path),remove(`deleted_${collection}/${id}`)],200,'初期化');
  await expectCommit(f.uid,[write(path,base)],200,`${collection}の初期作成`);
  const next={...base,version:2,name:'編集後'};
  if(collection==='member_invitations') {
    await expectCommit(f.uid,[write(path,next)],403,'招待の同コード更新は拒否し再発行で置換する');
  } else {
    const concurrent=await Promise.all([commit(f.uid,[write(path,next)]),commit(f.uid,[write(path,next)])]);
    assert.deepEqual(concurrent.map(v=>v[0]).sort(),[200,403],`${collection}の競合`);
    await expectCommit(f.uid,[write(path,next)],403,`${collection}の古い期待値`);
    for(const invalid of [undefined,null,'3',raw({doubleValue:3}),2,4]) await expectCommit(f.uid,[write(path,{...next,version:invalid})],403,`${collection}の不正な更新値`);
  }
  for(const invalid of invalidStored) {
    await expectCommit('owner',[write(path,{...base,version:invalid})],200,'不正な保存値を準備');
    const result=collection==='members'||collection==='groups'?await archivedDelete(f.uid,collection,id):await commit(f.uid,[remove(path)]);
    assert.equal(result[0],403,`${collection}の不正バージョン削除拒否: ${result[1]}`);
  }
  await expectCommit('owner',[write(path,base)],200,'初期値へ戻す');
  const deleted=collection==='members'||collection==='groups'?await archivedDelete(f.uid,collection,id):await commit(f.uid,[remove(path)]);
  assert.equal(deleted[0],200,`${collection}の正規削除: ${deleted[1]}`);
  for(const bearer of [null,token(f.uid,false)]) {
    await expectCommit(bearer,[write(path,base)],403,`${collection}の未認証・未確認の作成拒否`);
    await expectCommit('owner',[write(path,base)],200,'認証検証の準備');
    await expectCommit(bearer,[write(path,next)],403,`${collection}の未認証・未確認の更新拒否`);
    await expectCommit(bearer,[remove(path)],403,`${collection}の未認証・未確認の削除拒否`);
    await expectCommit('owner',[remove(path)],200,'認証検証の後片付け');
  }
  await expectCommit(f.uid,[write(`${path}/nested/doc`,base)],403,'再帰ルールの迂回を拒否');
}
const label={version:7,groupId:f.group,name:'ラベル',eventCount:1};
await expectCommit('owner',[write('calendar_labels/version-count',label)],200,'件数検証の準備');
await expectCommit(f.uid,[write('calendar_labels/version-count',{...label,eventCount:2})],200,'件数だけの更新');
for(const invalid of invalidStored) {
  await expectCommit('owner',[write('calendar_labels/version-count',{...label,version:invalid})],200,'不正な件数用バージョンを準備');
  await expectCommit(f.uid,[write('calendar_labels/version-count',{...label,version:invalid,eventCount:2})],403,'不正な既存バージョンの件数更新を拒否');
}
await expectCommit(f.uid,[write('unknown/doc',{})],403,'未知のコレクションを拒否');
console.log('認可済み利用者のバージョン・同時更新・認証・迂回拒否を確認しました');
