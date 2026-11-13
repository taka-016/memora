import assert from 'node:assert/strict';
import {fixture,write,remove,expectCommit,archivedDelete,token,root} from './firestore_rules_fixture.mjs';
const ids=['verified','unverified','anonymous'].map(type=>`archive-groups-${type}`);
const f=await fixture('archive',ids);
for(const table of ['groups','members']) {
  for(const [label,bearer,allowed] of [['verified',f.uid,true],['unverified',token(f.uid,false),false],['anonymous',null,false]]) {
    const id=`archive-${table}-${label}`,data={version:1,ownerId:f.member,name:'退避情報',...(table==='members'?{accountId:null,groupIds:[],managedGroupIds:[]}: {})};
    await expectCommit('owner',[remove(`deleted_${table}/${id}`),write(`${table}/${id}`,data),write(`group_events/${id}`,{version:1,groupId:id,memo:'保持する記録'})],200,'退避対象を準備');
    const [status,body]=await archivedDelete(bearer,table,id);
    assert.equal(status,allowed?200:403,`${table} ${label}: ${body}`);
    for(const [path,expected] of [[`${table}/${id}`,allowed?404:200],[`deleted_${table}/${id}`,allowed?200:404],[`group_events/${id}`,200]]) {
      const r=await fetch(`${root}/${path}`,{headers:{Authorization:'Bearer owner'}});
      assert.equal(r.status,expected,`${table}の親退避と関連データ保持`);
    }
  }
}
console.log('グループ・メンバー退避の認証条件と原子的書き込みを確認しました');
