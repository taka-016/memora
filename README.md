# memora

家族などのグループ内で、イベントを記録・共有するためのFlutterアプリケーションです。

## 概要

Memoraは、家族や友人などのグループで思い出を記録・整理・共有するためのFlutterモバイルアプリです。年表UIを中心に、個人・グループのイベント、旅行履歴、ライフイベントを時系列で管理できます。

### 主な機能

- **年表表示**: 過去・現在・未来のイベントや旅行、ライフイベントを、年ごとの列で俯瞰表示（行高さの調整にも対応）
- **グループ・メンバー管理**: 複数グループの作成・管理、メンバーの柔軟な所属設定（メンバーの複数グループ所属に対応）
- **イベント管理**: 個人・グループイベントの作成、編集、削除。必須項目（名称・日付）を検証しつつ時系列で管理
- **旅行管理**: 開始/終了日の検証、訪問先ピン管理、訪問日時管理、ドラッグ&ドロップによる旅程並び替えに対応
- **地図連携**: Google Maps連携による地名検索、任意地点へのピン配置、経路表示、訪問履歴の可視化
- **ライフイベント自動計算**: メンバーの生年月日を基に、七五三・学齢・成人などの将来イベントを自動算出して表示

## ドキュメント

詳細設計は以下を参照してください。

- [ユーザーストーリー](./project_docs/user_stories.md) - 利用シナリオと受け入れ条件
- [ER図](./project_docs/er_diagram.md) - データベース設計
- [ユースケース図](./project_docs/usecase_diagram.md) - 主要な利用目的とアプリモードごとの利用可否
- [ADR](./project_docs/adr/) - 今後も維持するアーキテクチャ上の判断
- [TODO一覧](./project_docs/todo.md) - 開発進捗

## 開発

日常の操作は[justfile](./justfile)にまとめています。`just`または`just --list`で目的に合うタスクを確認し、`just --show <タスク名>`で実行内容を確認できます。

### 前提条件とjustの導入

ホストにDocker Engine・Compose・Git・SSHクライアントを用意し、`~/.gitconfig`を設定してください。WSL2でも利用できます。初回の構築にはインターネット接続が必要です。

ホストにjust 1.59.0をインストールします。開発コンテナにはjustが含まれます。

```bash
mkdir -p "$HOME/.local/bin"
curl -fsSL https://just.systems/install.sh -o /tmp/install-just.sh
bash /tmp/install-just.sh --tag 1.59.0 --to "$HOME/.local/bin"
rm /tmp/install-just.sh
export PATH="$HOME/.local/bin:$PATH"
```

PATHの設定はシェルの設定ファイルにも追加してください。

### 開発コンテナの初回起動

ホストのリポジトリルートで実行します。

```bash
just dev-up
just dev-shell
```

コンテナへ渡す環境変数は、初回起動時に作成される`docker/.env`に設定します。アプリのコード生成用の`.env`とは別です。

SSH接続を使う場合は、次のコマンドで接続し、作業ディレクトリへ移動してください。VS CodeのRemote-SSHも利用できます。

```bash
ssh -i ssh_keys/memora_ed25519 -p 2222 root@localhost
cd /workspaces/memora
```

### 紹介ページ・ポリシーの公開

紹介ページ、プライバシーポリシー、利用規約は`docs/`の静的ページです。開発用の設計資料やtodoは`project_docs/`に置き、公開対象に含めません。運営者名・問い合わせ先・情報の取扱いが実際の運用と一致することを確認してから公開してください。

1. ページを含む変更を`main`へ反映する。
2. [リポジトリのPages設定](https://github.com/taka-016/memora/settings/pages)で、Sourceを「Deploy from a branch」、Branchを`main`、フォルダを`/docs`にして保存する。
3. デプロイ完了後、以下の3ページが開けることを確認する。

| 項目 | 公開後のURL |
| --- | --- |
| アプリのホームページ | `https://taka-016.github.io/memora/` |
| プライバシーポリシー | `https://taka-016.github.io/memora/privacy.html` |
| 利用規約 | `https://taka-016.github.io/memora/terms.html` |

OAuth審査で求められるサイトの所有確認は、Google Cloudプロジェクトの所有者または編集者のGoogleアカウントで[Search Console](https://search.google.com/search-console)から行います。GitHub Pagesの標準ドメインではDNSを変更できないため、「URLプレフィックス」に公開サイトのURLを指定し、HTMLファイルまたはHTMLタグによる確認方法を選びます。HTMLファイル方式では、Googleが発行した確認ファイルを内容・名前を変えずに`docs/`直下へ追加し、公開先の指定URLで取得できるようにしてから確認してください。HTMLタグ方式では、発行されたタグを`docs/index.html`の`head`内へ追加して公開します。所有確認後も確認ファイル・タグは残します。

Google Auth Platformの「承認済みドメイン」には、ページURLではなく`taka-016.github.io`を追加し、その後「ブランディング」の各項目へ上表のURLを登録します。GitHub Pagesの設定・Search Consoleの所有確認・OAuth審査は、リポジトリへのpushだけでは完了しません。詳細は[GitHubの公開設定](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site)、[Googleの所有確認](https://support.google.com/webmasters/answer/9008080)、[OAuthホームページの要件](https://support.google.com/cloud/answer/13807376)を参照してください。

### アプリの初期設定

開発コンテナの`/workspaces/memora`で、次の手順を実施します。

1. `cp .env.example .env`で設定ファイルを作成し、`GOOGLE_PLACES_APIKEY`を設定する。
2. `flutter pub get`で依存関係をインストールする。
3. `dart run build_runner build --delete-conflicting-outputs`で設定コードを生成する。
4. 生成に成功したら、機密情報を含む設定ファイルを`rm .env`で削除する。

Google Cloud ConsoleでMaps SDK for AndroidとPlaces API (New)を有効にし、`android/local.properties`にも`MAPS_API_KEY=<APIキー>`を設定してください。変更後はアプリの再ビルドが必要です。

オンライン版はFirebaseの設定も必要です。[Firebase Console](https://console.firebase.google.com/)でプロジェクトを作成し、次を有効にしてください。

- Authentication（Google・メールアドレス/パスワード）
- Firestore Database（本番モード）
- Identity Toolkit API
- Token Service API

必要に応じてFirestoreのセキュリティルールを設定した後、`just setup-firebase`を実行し、メニューで必要な処理を選びます。初回は「すべて実行」を選択し、画面の案内に従ってログインとプロジェクト選択を行ってください。処理を直接指定する方法は[justfile](./justfile)を参照してください。

設定の生成・更新時は、Google Cloudの「APIとサービス → 認証情報」からFirebase用APIキーをコピーして入力してください（環境変数`FIREBASE_API_KEY`でも指定可）。指定したキーは`android/app/google-services.json`と`lib/firebase_options.dart`の両方へ反映されます。既存ファイルの削除は不要です。設定更新後はアプリを再ビルドしてください。

### Googleカレンダー連携の事前設定

オンライン版の連携機能を導入する前に、Firebaseと同じGoogle Cloudプロジェクトを選び、次を設定してください。設定後はオンライン版のカレンダー画面にある「Googleカレンダー連携」からGoogleアカウントを追加し、アカウントごとに表示対象を選びます。

1. [APIライブラリ](https://console.cloud.google.com/apis/library/calendar-json.googleapis.com)でGoogle Calendar APIを有効にする。
2. [Google Auth Platform](https://console.cloud.google.com/auth/overview)の「ブランディング」でアプリ名、サポートメール、連絡先を設定する。「対象」で利用対象を選び、外部向けの開発中はテストユーザーに連携を試すGoogleアカウントを追加する。
3. 「データアクセス」に以下の2スコープを登録する。カレンダーの書き込み権限は追加しない。
   - `https://www.googleapis.com/auth/calendar.calendarlist.readonly`
   - `https://www.googleapis.com/auth/calendar.events.readonly`
4. 「クライアント」でAndroid用OAuthクライアントを確認・作成する。オンライン版のパッケージ名は`com.example.memora`。実行するAPKの署名証明書のSHA-1を登録し、debug・releaseで署名が異なる場合はそれぞれ用意する。Google Play App Signingを使う場合は、配信APKのアプリ署名証明書を使う。証明書はリポジトリの`android`ディレクトリで`./gradlew signingReport`を実行して確認できる。
5. 同じプロジェクトのWebアプリケーション用OAuthクライアント（`client_type: 3`）も含む最新の`android/app/google-services.json`をFirebase Consoleから取得する。前述の手順に従ってFirebase設定を更新する。WebクライアントIDはAndroid SDKの初期化に使用するもので、サーバーの実装やクライアントシークレットのアプリへの埋め込みは不要。
6. 外部公開前に、公開先、プライバシーポリシー等の必要事項を整え、登録スコープに必要なOAuth審査と公開設定を完了する。

開発中は、予定を参照するGoogleアカウントをテストユーザーへ登録してください。memoraのログイン用アカウントだけを登録しても、別アカウントの連携は試せません。

OAuthクライアントはアプリを識別します。取得する予定のGoogleアカウントは利用者が連携時に選び、memoraへログインするアカウントと異なっていても構いません。APIキーやFirebaseのログイントークンでは非公開の予定を参照できません。

詳細はGoogle公式の[API有効化](https://developers.google.com/workspace/guides/enable-apis)、[同意画面の設定](https://developers.google.com/workspace/guides/configure-oauth-consent)、[Calendar APIのスコープ](https://developers.google.com/workspace/calendar/api/auth)、[署名証明書の確認](https://developers.google.com/android/guides/client-auth)を参照してください。

### アプリモードと成果物

`run`・`build`・`release`・`check`の第1引数は`online`または`offline`で、省略時は`online`です。両モードは同じ端末にインストールできますが、データは共有しません。機能の違いは[ユースケース図](./project_docs/usecase_diagram.md)を参照してください。

テスト対象や追加オプションはモードの後ろへ指定します（例: `just check offline test/unit/`）。

release APKの出力先は`build/app/outputs/flutter-apk/memora-<version>-<mode>.apk`です。生成したバージョンとモードに合わせて、`adb install -r <APKのパス>`でインストールできます。

アプリの初期化は`adb shell pm clear <application ID>`、アンインストールは`adb uninstall <application ID>`で行います。application IDはオンライン版が`com.example.memora`、オフライン版が`com.example.memora.offline`です。どちらの操作も対象アプリのデータを削除します。

### ヘッドレスAndroidエミュレータ

ホストはx86_64のLinux環境とし、Dockerから`/dev/kvm`へアクセスできるようにしてください。WSL2でもDocker Engineを動かす環境で`ls -l /dev/kvm`を確認します。

外部通信とGoogleサービスは利用できないため、オフライン版の確認に使用します。開発コンテナで起動し、ADBを接続します。実機の誤操作を避けるため、端末IDを指定してください。

```bash
just emulator-up
emulator_serial=localfilesystem:/root/.android/memora-adb/adbd.sock
adb connect "$emulator_serial"
just run offline -d "$emulator_serial"
adb -s "$emulator_serial" exec-out screencap -p > /tmp/memora-screen.png
```

`just run`を終了してから、切断・停止します。端末内のデータは次回起動時も残ります。

```bash
adb disconnect "$emulator_serial"
just emulator-stop
```

環境検証用の`just test-emulator`も終了時にエミュレータを停止します。

## ライセンス

このプロジェクトはGNU Affero General Public License v3.0（AGPL-3.0）の下で公開されています。  
詳細は[LICENSE](./LICENSE)を参照してください。
