# オンラインの認可文書の補完

このコマンドは`members`・`groups`・`group_members`から`account_permissions`を生成・照合します。アプリとルールの切替は行いません。

実行前に、旧版アプリ・バックグラウンド更新・他の管理操作を停止してFirestoreをバックアップしてください。読み取りから補完終了まで元データを変更しない運用が前提です。対象プロジェクトの読み書き権限を持つOAuthアクセストークンを`FIRESTORE_ACCESS_TOKEN`に設定します。

```bash
dart run scripts/firebase/backfill_account_permissions.dart <projectId> <report.json>
```

レポートの`documents`と`issues`を確認してください。本人の重複対応、所属文書の重複、所有者の所属不足、既存認可との不一致があれば適用を拒否します。削除済みのグループ・メンバーに残る所属は認可に含めません。既存データを削除・再作成せず、不一致を自動修正することもありません。

不整合を解消して確認をやり直した後、同じ指定へ`--apply`を付けて実行します。

```bash
dart run scripts/firebase/backfill_account_permissions.dart <projectId> <report.json> --apply
```

未作成の認可文書だけを最大500件ずつ保存します。補完開始後に作成された認可文書も上書きしません。全件をまとめた原子性は保証しません。失敗・結果不明の場合はレポートの`appliedAccountIds`・`pendingAccountIds`とFirestoreを照合し、確認からやり直してください。既存の一致する認可文書は再保存しません。

この処理だけではルール切替の準備は完了しません。所属の保存形式、権限更新、招待受理、認可に限定したクエリとStreamの実装、および`member_events.groupId`の手動補完を確認した上でルールを切り替える必要があります。
