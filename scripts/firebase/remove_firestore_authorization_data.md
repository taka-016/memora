# Firestoreで廃止した認可用データの削除

[ADR-012](../../project_docs/adr/adr-012-firestore-access-without-document-reads.md)に対応する一度限りの作業です。対象プロジェクトのFirestore書き込み権限を持つ管理者が、対応版とFirestoreルールの切替後に実行します。切替後は旧版で本人や所属グループを取得できなくなります。

対象は `account_permissions` と `member_invitation_claims` のドキュメント、および `members` の `groupIds`、`managedGroupIds`、`changedGroupId` です。所属を保存する `group_members`、招待コードを保存する `member_invitations`、メンバー情報の退避先 `deleted_members` は操作の対象外です。

対象プロジェクトと対象ドキュメントをレポートで事前確認します。

```sh
export FIRESTORE_ACCESS_TOKEN="$(gcloud auth print-access-token)"
dart run scripts/firebase/remove_firestore_authorization_data.dart <projectId> <report.json>
```

レポート確認後に適用します。

```sh
dart run scripts/firebase/remove_firestore_authorization_data.dart <projectId> <report.json> --apply
```

スクリプトは取得時から変更されたドキュメントを含む書き込みを拒否します。失敗した場合はレポートで適用済み件数を確認し、同じコマンドを再実行できます。
