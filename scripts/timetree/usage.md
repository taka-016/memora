# TimeTreeのICS取り込みスクリプト

オンライン版のFirestoreに一度だけ取り込む場合は、[設定ひな形](config.example.json)をリポジトリ直下の`timetree-import.local.json`へコピーし、`groupName`に取り込み先のグループ名、対応表の`memberName`に各分類を紐づけるメンバーの表示名を記入してください。対応表には今回のICSから抽出した分類・色を設定済みです。分類なしの行も含め、各行に対応するメンバー名を記入してください。グループ名・メンバー名は一意である前提です。

リポジトリ直下で実行してください。Firebaseの接続先はアプリ設定の`.firebaserc`から取得し、既定のデータベースを使用します。IDの記入や新規ラベルの作成は不要です。入力ICS・レポートのパスは設定ファイルからの相対指定です。

書き込み時はFirestoreの読み書き権限を持つGoogle CloudアカウントのOAuthアクセストークンを、設定で指定した環境変数へ設定します。Google Cloud CLIを利用する場合は、`gcloud auth login`後に`export GOOGLE_OAUTH_ACCESS_TOKEN="$(gcloud auth print-access-token)"`で取得できます。

`dart run scripts/timetree/import_timetree.dart timetree-import.local.json`で確認用レポートを作成し、予定・ラベル対応・除外理由・手修正事項を確認してください。実際に取り込む場合は同じコマンドの末尾に`--apply`を追加します。レポートの出力後に入力確認があります。元UIDによる重複判定は行わないため、成功後に再実行しないでください。結果不明の場合はレポートの予定IDで登録結果を確認してください。ICS、認証情報、記入済み設定、レポートは共有・コミットしないでください。
