# memora

家族の予定や買い物リスト、思い出を記録・共有するFlutterモバイルアプリです。

[紹介ページ](https://taka-016.github.io/memora/)

## 概要

Memoraは、家族の日々の予定調整や買い物から、旅行の計画、思い出の振り返りまでを支えます。カレンダーで家族それぞれの予定を把握し、買い物リストで必要な品物や購入済みの品物を共有できます。年表では、家族の出来事や旅行、子どもの成長の節目を時系列で見渡せます。家族以外のグループや、自分だけの予定・記録の管理にも利用できます。

### 主な機能

- **カレンダー**: 家族の予定を日付ごとに確認し、誰に関係する予定かをラベルで識別。繰り返し予定や通知に対応し、オンライン版では端末カレンダーの自分の予定も一緒に表示
- **買い物リスト（オンライン版）**: 家族で必要な品物と数量を共有し、購入済みの品物を履歴で確認
- **年表・イベント管理**: 家族全体やメンバー別の出来事、旅行、ライフイベントを年ごとに見渡し、過去の記録や未来の計画を整理
- **旅行管理**: 家族旅行の計画や記録、訪問場所、旅程、タスクをまとめて管理
- **地図連携（オンライン版）**: 場所の検索やピンの配置、経路表示で旅程を確認し、訪問履歴を地図で振り返る
- **ライフイベント自動計算**: メンバーの生年月日を基に、七五三・学齢・成人などの将来の節目を表示
- **グループ・メンバー管理**: 家族や友人のグループを作成し、メンバーや共有する記録を管理。自分だけのグループにも対応
- **ホーム画面ウィジェット**: アプリを開かずにカレンダーや直近の旅程を確認

## ドキュメント

- [ユーザーストーリー](./project_docs/user_stories.md) — 利用シナリオ・受け入れ条件
- [ユースケース図](./project_docs/usecase_diagram.md) — 利用目的・モード別の機能
- [ER図](./project_docs/er_diagram.md) — データモデル
- [ADR](./project_docs/adr/) — アーキテクチャ上の判断
- [TODO一覧](./project_docs/todo.md) — 未完了の作業

## 開発

コマンド・用途・実行条件は[justfile](./justfile)を参照してください。`just`で一覧、`just --show <タスク名>`で実行内容を確認できます。

### 前提条件

- ホスト：Docker Engine・Compose・Git・SSHクライアント、設定済みの`~/.gitconfig`。WSL2も利用可。
- 初回構築にはインターネット接続が必要。
- ホストにjust 1.59.0を導入（開発コンテナには導入済み）。

```bash
mkdir -p "$HOME/.local/bin"
curl -fsSL https://just.systems/install.sh -o /tmp/install-just.sh
bash /tmp/install-just.sh --tag 1.59.0 --to "$HOME/.local/bin"
rm /tmp/install-just.sh
export PATH="$HOME/.local/bin:$PATH"
```

PATHの設定はシェルの設定ファイルにも追加してください。

### 開発コンテナ

ホストのリポジトリルートで実行します。

```bash
just dev-up
just dev-shell
```

- コンテナ用の環境変数：初回起動時に作成される`docker/.env`に設定。
- 作業ディレクトリ：`/workspaces/memora`。
- SSH接続（VS CodeのRemote-SSHも利用可）：

```bash
ssh -i ssh_keys/memora_ed25519 -p 2222 root@localhost
cd /workspaces/memora
```

### アプリの初期設定

開発コンテナのリポジトリルートで実施します。

1. `cp .env.example .env`でアプリ設定を作り、`GOOGLE_PLACES_APIKEY`を設定する（`docker/.env`とは別）。
2. `just pub-get`で依存関係を取得する。
3. `just generate --delete-conflicting-outputs`で設定コードを生成する。
4. 成功後、機密情報を含む設定ファイルを`rm .env`で削除する。
5. Google Cloud ConsoleでMaps SDK for Android・Places API (New)を有効にする。
6. `android/local.properties`に`MAPS_API_KEY=<APIキー>`を設定し、アプリを再ビルドする。

### オンライン版の設定

1. [Firebase Console](https://console.firebase.google.com/)でプロジェクトを作成する。
2. Authentication（メールアドレス/パスワード）、Firestore Database（本番モード）、Identity Toolkit API、Token Service APIを有効にする。
3. [Google Cloud CLI](https://cloud.google.com/sdk/docs/install)を用意し、必要なFirestoreセキュリティルールを設定する。
4. `just setup-cloud`で「すべて実行」を選び、ログイン・プロジェクト選択・設定生成を進める。APIキーの入力時は、下表のFirebase用キーを指定する。
5. 設定更新後、アプリを再ビルドする。

APIキーはGoogle Cloudの「APIとサービス → 認証情報」で確認する。Firebase用とMaps用は用途が異なるため、次のように使い分ける。

| 用途 | このプロジェクトのキー名 | 設定先 |
| --- | --- | --- |
| Firebaseの認証・接続 | `firebase for memora` | `just setup-cloud`のAPIキー入力（環境変数`FIREBASE_API_KEY`でも指定可） |
| 地図表示・位置検索 | `maps for memora` | `android/local.properties`の`MAPS_API_KEY`と、初期設定時の`.env`の`GOOGLE_PLACES_APIKEY` |

Firebase用キーにはIdentity Toolkit API・Token Service API・Firebase Installations APIを許可する。Androidアプリ制限を設定する場合は、使用するapplication IDと署名証明書のSHA-1も登録する。Maps用キーをFirebase認証に使うと、ログイン時に`SignInWithPassword are blocked`などのエラーになる。

オンライン版は、同じFirebaseプロジェクトにリリース用 `io.github.taka016.memora` とデバッグ用 `io.github.taka016.memora.debug` を登録し、両方を含む`google-services.json`を共用する。Firebase用・Maps用キーのAndroidアプリ制限には、それぞれのapplication IDと使用する署名証明書のSHA-1を登録する。

`google-services.json`をダウンロードし直した場合も、含まれるキーがFirebase用とは限らない。先頭のキーをそのまま採用せず、次の手順でFirebase用キーを反映する。

1. 新しいJSONを`android/app/google-services.json`へ配置する。
2. 同じFirebase Androidアプリの設定を置き換えた場合は、`just setup-cloud api-key`でFirebase用キーを入力する。application IDの変更などでFirebase Androidアプリを追加した場合は、`just setup-cloud configure`で対象アプリの設定を生成し、Firebase用キーを入力する。
3. アプリを再ビルドする。

キーはJSON内のリリース用・デバッグ用アプリと`lib/firebase_options.dart`へ反映される。Dart設定も1ファイルで共用し、デバッグ実行ではデバッグ用、release・profile実行ではリリース用のFirebase App IDを選ぶ。既存ファイルの削除は不要。

設定・認証時の注意：

- Google Cloud認証にはFirestore読み書き権限（`roles/datastore.user`など）のある管理用アカウントを使う。Firebase CLIとは別認証で、表示URLと認証コードでログインする。認証済みなら再ログインは不要。
- 接続先は`.firebaserc`の`projects.default`。アクセストークンは自動取得する。CIでは`FIRESTORE_ACCESS_TOKEN`に有効なOAuthアクセストークンを指定可。
- 初回のビルド番号変更・Firestore文書登録は不要。最低対応ビルド番号は配布後に旧版を停止するときだけ設定する。

### アプリモード・配布

- 実行・ビルドはAndroid向け。オンライン版とオフライン版は同じ端末にインストールでき、データは共有しない。機能差は[ユースケース図](./project_docs/usecase_diagram.md)を参照。
- バージョン名は`pubspec.yaml`で管理。オンライン版のビルド番号はリリース時に自動採番し、デバッグでは現在値を使う。`--build-number`は指定不可。
- オフライン版はFirestoreに接続せず、`pubspec.yaml`のビルド番号を使う。
- APKのインストール：`adb install -r <APKのパス>`。
- 初期化：`adb shell pm clear <application ID>`。アンインストール：`adb uninstall <application ID>`。どちらも対象アプリのデータを削除する。

デバッグ版とリリース版も同じ端末にインストールできる。オンラインの両ビルドは同じFirebaseプロジェクトを利用する。

| モード | ビルド種別 | アプリ名 | application ID |
| --- | --- | --- | --- |
| オンライン | release・profile | memora | `io.github.taka016.memora` |
| オンライン | debug | memora-debug | `io.github.taka016.memora.debug` |
| オフライン | release・profile | memora lite | `io.github.taka016.memora.offline` |
| オフライン | debug | memora lite-debug | `io.github.taka016.memora.offline.debug` |

### 端末カレンダー連携

- Androidオンライン版のカレンダー画面で「端末カレンダー連携」を開き、読み取りを許可してアカウントごとの表示対象を選ぶ。
- Google等の予定は端末側の同期を有効にする。表示は同期済みの範囲のみで、編集・他メンバーへの共有は不可。
- 選択した予定はホーム画面のカレンダーウィジェットにも表示し、更新時に端末から再取得する。
- 権限を取り消した場合は、Androidの設定から再度許可する。

### ヘッドレスAndroidエミュレータ

- ホストはx86_64 Linux。Dockerから`/dev/kvm`へアクセスできること（WSL2もDocker Engine側で確認）。
- 外部通信・Googleサービスは利用不可。オフライン版の確認に使う。
- 開発コンテナで実行し、実機の誤操作を避けるため端末IDを指定する。

```bash
just emulator-up
emulator_serial=localfilesystem:/root/.android/memora-adb/adbd.sock
adb connect "$emulator_serial"
just run offline -d "$emulator_serial"
adb -s "$emulator_serial" exec-out screencap -p > /tmp/memora-screen.png
```

実行終了後に切断・停止します。端末データは次回起動時も保持されます。

```bash
adb disconnect "$emulator_serial"
just emulator-stop
```

### 紹介ページ・ポリシーの公開

公開対象は`docs/`のみ。運営者名・問い合わせ先・情報の取扱いを確認してから公開してください。

1. ページの変更を`main`へ反映する。
2. [Pages設定](https://github.com/taka-016/memora/settings/pages)を「Deploy from a branch」・`main`・`/docs`にする。
3. 公開後に以下のページが開けることを確認する。

- [ホームページ](https://taka-016.github.io/memora/)
- [プライバシーポリシー](https://taka-016.github.io/memora/privacy.html)
- [利用規約](https://taka-016.github.io/memora/terms.html)

## ライセンス

[GNU Affero General Public License v3.0（AGPL-3.0）](./LICENSE)
