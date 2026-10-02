# Firestoreのカレンダールール検証

リポジトリには既存機能の本番Firestoreルールが含まれていないため、`firestore_calendar.rules`はカレンダーと所属確認用の読取を含む検証用ルールとする。本番へこのファイルだけをデプロイせず、既存ルールの`/databases/{database}/documents`内へカレンダーの関数と`calendar_events`、`calendar_labels`、`calendar_memberships`のmatchを組み込む。

既存ルールの全パスへの許可がこれらのコレクションにも適用される場合は、その許可を対象コレクションごとに限定する。Firestoreルールは複数のmatchの許可をORで評価するため、広い許可が残るとカレンダーの制限を回避できる。`members.accountId`と`group_members`の書込についても、本人・管理者・有効な招待による変更だけを既存ルールで許可する必要がある。

`calendar_memberships/{groupId}/accounts/{uid}`は認証アカウントと既存の所属を結ぶ参照であり、カレンダー取得・保存時とグループ削除開始時に作成・更新する。読書きのたびに正本の`members`と`group_members`を照合するため、脱退・メンバー削除・アカウント変更で即座に失効する。既存グループの一括移行は不要。失効した参照には予定・ラベルの本文を保持しない。

グループ削除時に`groups.calendarDeleting`をtrueへ更新する。既存のグループ管理ルールで管理者によるこの更新を許可し、削除開始後にfalseへ戻す更新を許可しないこと。予定とラベルを先に削除してから所属とグループを削除する。中断した場合はグループ削除を再実行する。

ラベルの`eventCount`と`lastEventId`は予定の作成・削除・ラベル変更と同じトランザクションで更新し、ルールでも対応する予定の変更を検証する。使用中のラベルは削除不可。名前と色の変更は予定の参照IDを維持する。

## 実行

Node.js、Firebase CLI、Java 21以上を用意し、リポジトリのルートで実行する。認証は不要で、本番へ接続しない。

```sh
npm ci --prefix tools/firestore
firebase --config firebase_calendar_emulator.json --project demo-memora-calendar emulators:exec --only firestore 'node --test tools/firestore/calendar_rules.test.cjs'
```

この検証は`./check.sh`のFlutterテストとは別に実行する。非所属・未認証アクセス、所属失効、別グループのラベル、参照数の改ざん、ラベル変更・削除、グループ削除中の登録を検証する。
