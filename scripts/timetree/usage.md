# TimeTreeのICS取り込みスクリプト

オンライン版のFirestoreに一度だけ取り込む場合は、[設定ひな形](config.example.json)をリポジトリ直下の`timetree-import.local.json`へコピーし、`groupName`に取り込み先のグループ名、対応表の`memberName`に各分類を紐づけるメンバーの表示名を記入してください。対応表の`category`にある「〇〇の予定」を実際のICSの分類名へ変更し、`color`も取り込む分類の色と一致させてください。「家族の予定」の行は`groupLabel: true`を設定済みで、既存の「グループの予定」ラベルへ紐づきます。この行のメンバー名は不要です。それ以外は分類なしの行も含め、対応するメンバー名を記入してください。グループ名・メンバー名は一意である前提です。

リポジトリ直下で実行してください。Firebaseの接続先はアプリ設定の`.firebaserc`から取得し、既定のデータベースを使用します。IDの記入や新規ラベルの作成は不要です。入力ICS・レポートのパスは設定ファイルからの相対指定です。

書き込み時はFirestoreの読み書き権限を持つGoogle CloudアカウントのOAuthアクセストークンを、設定で指定した環境変数へ設定します。Google Cloud CLIを利用する場合は、`gcloud auth login`後に`export GOOGLE_OAUTH_ACCESS_TOKEN="$(gcloud auth print-access-token)"`で取得できます。

`dart run scripts/timetree/import_timetree.dart timetree-import.local.json`で確認用レポートを作成し、予定・ラベル対応・除外理由・手修正事項を確認してください。実際に取り込む場合は同じコマンドの末尾に`--apply`を追加します。レポートの出力後に入力確認があります。元UIDによる重複判定は行わないため、成功後に再実行しないでください。結果不明の場合はレポートの予定IDで登録結果を確認してください。ICS、認証情報、記入済み設定、レポートは共有・コミットしないでください。

## 取り込み済み予定の通知補完

成功した取り込みレポートに記載された予定と、その個別回のうち、現在の通知が空のものにアプリの初期設定を追加します。終日は当日・1日前・2日前、時間指定は開始時・30分前・1時間前です。終日の通知時刻はアプリの終日通知時刻（初期値7:00）に従います。設定済みの通知と取消済みの個別回は維持します。

同じ設定ファイルを使用します。事前にOAuthアクセストークンを設定し、確認モードで対象とスキップ理由を確認してください。

```bash
dart run scripts/timetree/set_missing_notifications.dart timetree-import.local.json
```

確認レポートは元の取り込みレポートと同じフォルダの`timetree-notifications.report.json`へ出力します。元の取り込みレポートは保持します。通知・更新日時・親予定のバージョンを一括更新し、読み取り後に予定が編集されていた場合は全体を適用しません。

実際に補完する場合は次を実行し、確認で「通知を設定する」と入力してください。

```bash
dart run scripts/timetree/set_missing_notifications.dart timetree-import.local.json --apply
```

設定済みの通知はスキップするため、再実行しても既存の通知を置き換えません。実行後にアプリを開くと、更新された設定から通知が再予約されます。アプリの通知権限も有効にしてください。
