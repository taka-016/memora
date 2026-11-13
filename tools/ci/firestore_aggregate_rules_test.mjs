import assert from 'node:assert/strict';
import {fixture,write,remove,expectCommit,commit,archivedDelete,root,token} from './firestore_rules_fixture.mjs';
const group='aggregate-managed-group';
const f=await fixture('aggregates',[group]);
const cases=[['trip_entries','locations','tripId'],['trip_entries','tasks','tripId'],['trip_entries','itinerary_items','tripId'],['calendar_events','calendar_event_overrides','eventId'],['dvc_point_contracts','dvc_point_usages','contractId'],['dvc_point_contracts','dvc_limited_points','contractId']];
for(const [parents,children,key] of cases) {
  const id=`aggregate-${children}`,parent=`${parents}/${id}`,child=`${children}/${id}`,other=`${parents}/${id}-other`;
  const parentData=version=>({version,groupId:f.group,...(parents==='calendar_events'?{labelType:'group',memberId:null,labelId:null}:{})});
  const childData={[key]:id,groupId:f.group,name:'変更前',...(children==='calendar_event_overrides'?{isCancelled:true}:{})};
  await expectCommit('owner',[remove(parent),remove(child),remove(other),remove(`${child}-a`),remove(`${child}-b`)],200,'親子を初期化');
  await expectCommit(f.uid,[write(child,childData)],403,`${children}の親なし作成`);
  await expectCommit(f.uid,[write(parent,parentData(1)),write(child,childData)],200,`${children}の親子作成`);
  for(const operation of [write(child,{...childData,name:'変更'}),remove(child),write(`${child}-new`,childData)]) await expectCommit(f.uid,[operation],403,`${children}の親更新なしの保存拒否`);
  await expectCommit(f.uid,[write(parent,parentData(2)),write(child,{...childData,name:'変更'})],200,`${children}の親子更新`);
  const concurrent=await Promise.all([commit(f.uid,[write(parent,parentData(3)),write(`${child}-a`,childData)]),commit(f.uid,[write(parent,parentData(3)),write(`${child}-b`,childData)])]);
  assert.deepEqual(concurrent.map(v=>v[0]).sort(),[200,403],`${children}の集約競合`);
  await expectCommit(f.uid,[write(parent,parentData(3)),remove(child)],403,'古い親バージョンの再試行を拒否');
  await expectCommit(f.uid,[write(parent,parentData(4)),write(other,parentData(1)),write(child,{...childData,[key]:`${id}-other`})],403,'親の付け替えを拒否');
  await expectCommit(f.uid,[write(parent,parentData(4)),remove(child)],200,'親更新と子削除');
  await expectCommit(f.uid,[write(parent,parentData(5)),write(child,childData)],200,'子の再追加');
  await expectCommit(f.uid,[write(parent,parentData(5)),remove(child),write(`${child}-replacement`,childData)],403,'古い親による全件置換を拒否');
  await expectCommit(f.uid,[remove(parent),remove(child)],200,'親子を同時削除');
  await expectCommit(f.uid,[remove(`${child}-a`)],403,'削除後の親を権限に使わない');
  await expectCommit(f.uid,[remove(`${child}-b`)],403,'削除後の親を権限に使わない');
}
const membership=`group_members/${group}:${f.invitee}`;
await expectCommit('owner',[remove(`deleted_groups/${group}`),write(`groups/${group}`,{version:1,ownerId:f.member}),write(`members/${f.invitee}`,{version:1,accountId:null,ownerId:f.member,groupIds:[group],managedGroupIds:[]}),remove(membership)],200,'所属集約を準備');
const link={groupId:group,memberId:f.invitee,isAdministrator:false};
await expectCommit(f.uid,[write(membership,link)],403,'所属だけの作成を拒否');
await expectCommit(f.uid,[write(`groups/${group}`,{version:2,ownerId:f.member}),write(membership,link)],200,'親更新と所属作成');
await expectCommit(f.uid,[write(`groups/${group}`,{version:3,ownerId:f.member}),write(membership,{...link,isAdministrator:true})],403,'役割と認可一覧の不一致を拒否');
await expectCommit(f.uid,[write(`groups/${group}`,{version:3,ownerId:f.member}),write(membership,{...link,isAdministrator:true}),write(`members/${f.invitee}`,{version:2,accountId:null,ownerId:f.member,groupIds:[group],managedGroupIds:[group],changedGroupId:group})],200,'親更新と管理者変更と認可一覧を同時保存');
assert.equal((await archivedDelete(f.uid,'groups',group))[0],200,'所属を保持してグループを退避');
await expectCommit(f.uid,[remove(membership)],403,'退避した親に残る所属は操作の根拠にならない');
await expectCommit('owner',[write('dvc_point_contracts/independent',{version:1,groupId:f.group})],200,'独立した契約を準備');
const independent=await Promise.all([commit(f.uid,[write(`groups/${f.group}`,{version:2,ownerId:f.member})]),commit(f.uid,[write('dvc_point_contracts/independent',{version:2,groupId:f.group}),write('dvc_point_usages/independent',{contractId:'independent',groupId:f.group})])]);
assert.deepEqual(independent.map(v=>v[0]),[200,200],'グループとDVC契約の競合単位は独立する');
const mixed=version=>Array.from({length:4},(_,i)=>[
  write(`trip_entries/mixed-${i}`,{version,groupId:f.group}),
  ...Array.from({length:3},(_,j)=>write(`tasks/mixed-${i}-${j}`,{tripId:`mixed-${i}`,groupId:f.group,name:'準備'})),
]).flat();
await expectCommit('owner',mixed(1),200,'複数集約を準備');
await expectCommit(f.uid,mixed(2),200,'4親と12子を参照上限内で保存');
const begun=await fetch(`${root}:beginTransaction`,{method:'POST',headers:{Authorization:`Bearer ${token(f.uid)}`,'Content-Type':'application/json'},body:JSON.stringify({options:{readWrite:{}}})});
assert.equal(begun.status,200);
const {transaction}=await begun.json();
const saved=await fetch(`${root}:commit`,{method:'POST',headers:{Authorization:`Bearer ${token(f.uid)}`,'Content-Type':'application/json'},body:JSON.stringify({writes:mixed(3),transaction})});
assert.equal(saved.status,200,await saved.text());
console.log('集約の原子性・競合・直接更新と親の付け替え拒否・参照上限内の保存を確認しました');
