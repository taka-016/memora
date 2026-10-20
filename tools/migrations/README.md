# Firestoreバージョン初期化と切替手順

[ADR-005](../../docs/adr/adr-005-version-based-concurrency-control.md)・[ADR-006](../../docs/adr/adr-006-atomic-aggregate-updates.md)の既存データ初期化用。永続キャッシュはこの切替が完了するまで無効のままにする。

## 管理処理

Node.js 22以上を使用する。Emulatorでは依存パッケージ・認証は不要。本番では既存の管理スクリプトと同じ`firebase-admin`のApplication Default Credentialsを使用する。必要ならリポジトリ外の作業ディレクトリへ`npm install --prefix "$ADMIN_DEPS" firebase-admin`で導入し、`NODE_PATH="$ADMIN_DEPS/node_modules"`を設定する。認証情報はリポジトリ外で管理する。

```bash
# 変更なしの全件検証。未初期化・不正値・DVC紐付け未完了があれば終了コード1。
node tools/migrations/initialize_firestore_versions.js --project "$MEMORA_PROJECT" --database '(default)'
# versionフィールドが存在しないドキュメントだけを初期化し、全件再検証する。
node tools/migrations/initialize_firestore_versions.js --project "$MEMORA_PROJECT" --database '(default)' --apply
```

対象は`firestore.rules`の`isVersionedCollection()`が定義する9コレクション。通常の子コレクション・退避先は初期化しない。ページを最後まで取得し、コレクション別の対象数・未設定数・不正数、不正ドキュメント名、書き込み済み件数、最終の`complete`をJSON行で出力する。検証時と初期化後に全件読み取りが発生する。

整数の1以上を保持し、既存値を1に巻き戻さない。null・文字列・浮動小数（1.0も含む）・0以下は不正値として止め、管理処理で補正しない。整数・浮動小数の型を区別するため、Firestore REST形式をそのまま検証する。DVC契約の`groupId`、全ポイント利用・期間限定ポイントの`contractId`と契約の存在・`groupId`一致を検証する。紐付けが未完了なら書き込みを始めない。事前検証に問題がなければ`version`フィールドだけを書き、取得時の`updateTime`を前提条件にする。途中失敗時も成功済みの初期化を残し、再実行で残りだけを処理する。

## 本番切替

以下は実施担当者が対象プロジェクト・データベース・バックアップ先・配布先を確定した後に実行する。停止中は閲覧できるが、作成・編集・削除はすべて利用できない。Admin SDK、管理コンソール、バッチなどRulesを経由しない書き込みも担当者が停止する。

1. `OnlineAppServices.initialize()`の`persistenceEnabled: false`を確認し、`./check.sh online`と`./release.sh online`を実行する。対応APKを合意した配布先に配布し、起動・ログイン・通常の保存と競合時の表示を確認する。未初期化データの保存はRulesで拒否される。アプリでversionを補完しない。
2. 作業記録へコミットSHA、APKのハッシュ・配布先・配布日時、プロジェクトID・DB名・担当者を記録する。現在デプロイされているRulesの内容とリリースIDを保存する。Cloud Firestoreの管理エクスポート用バケットとIAM権限を準備し、切替前バックアップを取得して完了を確認する。
3. 一時設定を用意し、書き込み停止Rulesをデプロイする。停止Rulesが全クライアントに反映するまで待ち、対応アプリの作成・更新・削除が拒否され、閲覧が継続できることを確認する。バックグラウンド処理など管理者の書き込みも停止した状態で、復旧用の最終エクスポートを取得する。長時間実行されるエクスポートが完了し、保存先と復元権限が確認できるまで初期化へ進まない。
4. 変更なしの全件検証を実行し、件数・不正値・DVC紐付けを記録する。未設定による終了コード1は初期化対象を意味する。不正値・紐付け未完了・通信失敗の場合は停止を維持し、データの担当者が原因と修正内容を判断する。DVCの紐付け先を自動推定しない。
5. 初期化、独立した全件検証、厳格Rulesへの切替を下記の順で実行する。いずれかが失敗したら書き込み停止を維持する。`missing: 0`・`invalid: 0`・`complete: true`のログを保存する。空のDBでも完了するため、対象プロジェクトと対象件数が事前記録と一致することも確認する。
6. 厳格Rulesの反映後、対応アプリで保存完了表示まで確認する。古い画面からの更新が拒否されること、不正なversionを持つ要求が拒否されることを確認する。切替時刻、RulesリリースID、検証ログ、担当者を記録する。成功を確認したら管理者の処理を再開する。永続キャッシュの有効化はtodo第7節として別途行う。

設定生成例（リポジトリのルートで、変数に確定した値を設定して実行）:

```bash
export MEMORA_PROJECT='対象プロジェクトID'
export MEMORA_DATABASE='(default)'
export MEMORA_CUTOVER_DIR="$(mktemp -d)"
node <<'JS'
const fs = require('node:fs');
const path = require('node:path');
for (const [name, rules] of [['stop', 'tools/migrations/firestore_write_stop.rules'], ['strict', 'firestore.rules']]) {
  fs.writeFileSync(path.join(process.env.MEMORA_CUTOVER_DIR, `${name}.json`), JSON.stringify({
    firestore: { database: process.env.MEMORA_DATABASE, rules: path.resolve(rules) },
  }));
}
JS
firebase deploy --only firestore:rules --project "$MEMORA_PROJECT" --config "$MEMORA_CUTOVER_DIR/stop.json"
```

停止確認後の最終バックアップ例（Cloud Firestoreと同じ場所のバケットを用意する）:

```bash
gcloud firestore export "$MEMORA_BACKUP_URI" --project "$MEMORA_PROJECT" --database "$MEMORA_DATABASE"
```

管理エクスポートは[公式手順](https://firebase.google.com/docs/firestore/manage-data/export-import)に従う。全コレクションを対象とし、サブコレクションや退避データも保持する。

停止とバックアップの確認後、別のbashで次を実行する。途中で失敗すると厳格Rulesのデプロイまで進まない。

```bash
bash <<'BASH'
set -euo pipefail
unset FIRESTORE_EMULATOR_HOST
node tools/migrations/initialize_firestore_versions.js --project "$MEMORA_PROJECT" --database "$MEMORA_DATABASE" --apply | tee "$MEMORA_CUTOVER_DIR/apply.log"
node tools/migrations/initialize_firestore_versions.js --project "$MEMORA_PROJECT" --database "$MEMORA_DATABASE" | tee "$MEMORA_CUTOVER_DIR/verify.log"
firebase deploy --only firestore:rules --project "$MEMORA_PROJECT" --config "$MEMORA_CUTOVER_DIR/strict.json"
BASH
```

## 失敗時の復旧

- 初期化の途中失敗・検証失敗・Rules切替失敗: 停止Rulesを維持（切替途中なら再適用）し、ログの成功件数と不正ドキュメントを確認する。通信・権限・DVC紐付け等の原因を解消して初期化を再実行し、全件検証が成功してから厳格Rulesへ切り替える。初期化済みversionを戻さない。
- データ自体を復旧する必要がある場合: 停止Rulesと管理者書き込み停止を維持し、最終バックアップのURIを指定して`gcloud firestore import "$MEMORA_BACKUP_URI" --project "$MEMORA_PROJECT" --database "$MEMORA_DATABASE"`を実行する。インポートはバックアップの同IDを上書きするため、対象と復旧時点を確認する。完了後に対象件数・業務データを確認し、再び初期化と全件検証を行う。データを削除・再作成しない。
- 切替後に問題が分かった場合: まず停止Rulesを再適用し、停止後のバックアップと変更履歴を保存する。切替後の更新を失う可能性があるため、切替前バックアップをそのまま上書きしない。担当者が復旧対象を判断する。未初期化・初期化失敗が残る間は元のRulesへ戻して書き込みを再開しない。

## Emulator検証

実プロジェクトの設定を使わず、専用の空のEmulatorを起動する。テストは`demo-memora`の全データを消去し、停止Rulesと厳格Rulesを切り替えるため、他のテストと同時実行しない。

```bash
export MEMORA_EMULATOR_CONFIG="$(mktemp)"
node -e 'require("node:fs").writeFileSync(process.env.MEMORA_EMULATOR_CONFIG, JSON.stringify({firestore:{rules:require("node:path").resolve("firestore.rules")},emulators:{firestore:{port:8080},ui:{enabled:false},singleProjectMode:true}}))'
firebase emulators:exec --only firestore --project demo-memora --config "$MEMORA_EMULATOR_CONFIG" 'node tools/ci/firestore_version_initialization_test.mjs'
```

既存の`firestore_version_rules_test.mjs`・`firestore_aggregate_rules_test.mjs`・`firestore_deleted_parent_rules_test.mjs`も厳格Rulesで検証する。
