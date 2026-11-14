import {fixture,write,remove,expectCommit} from './firestore_rules_fixture.mjs';
const f=await fixture('references');
for(const [id,reference,status] of [
  ['group',{labelType:'group',memberId:null,labelId:null},200],
  ['member',{labelType:'member',memberId:'m',labelId:null},200],
  ['custom',{labelType:'custom',memberId:null,labelId:'l'},200],
  ['unknown',{labelType:'invalid',memberId:null,labelId:null},403],
  ['missing-member',{labelType:'member',memberId:null,labelId:null},403],
  ['extra-label',{labelType:'group',memberId:null,labelId:'l'},403],
  ['missing-label',{labelType:'custom',memberId:null,labelId:null},403],
]) {
  const path=`calendar_events/reference-${id}`;
  await expectCommit('owner',[remove(path)],200,'初期化');
  await expectCommit(f.uid,[write(path,{groupId:f.group,version:1,...reference})],status,id);
}
await expectCommit('owner',[remove('calendar_events/reference-parent'),remove('calendar_event_overrides/reference-child')],200,'個別回を初期化');
for(const cancelled of [false,true]) {
  await expectCommit(f.uid,[
  write('calendar_events/reference-parent',{version:1,groupId:f.group,labelType:'group',memberId:null,labelId:null}),
  write('calendar_event_overrides/reference-child',{eventId:'reference-parent',groupId:f.group,isCancelled:cancelled}),
  ],cancelled?200:403,'個別回は親と同時に取消情報として保存する');
}
console.log('固定・任意ラベルの参照種別と個別回の保存を確認しました');
