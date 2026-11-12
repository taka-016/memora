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

オンライン版の採番と利用停止設定の操作には、[Google Cloud CLI](https://cloud.google.com/sdk/docs/install)を用意し、`gcloud auth login`で対象プロジェクトのFirestore読み書き権限（`roles/datastore.user`など）を持つ管理用アカウントへログインしてください。Firebase CLIとは別の認証です。コマンド実行時にアクセストークンを自動取得します。CI等では、有効なOAuthアクセストークンを環境変数`FIRESTORE_ACCESS_TOKEN`に設定する方法も使用できます。接続先は`.firebaserc`の`projects.default`です。

最初にリポジトリのFirestoreルールをデプロイしてください。採番カウンターと利用停止設定はコマンドから自動作成されるため、Consoleでの文書作成は不要です。既に配布したオンライン版がある場合は、初回の採番前に`pubspec.yaml`のビルド番号を過去に配布した最大値へ合わせてください。採番後にビルドが失敗した番号は欠番になります。

更新必須化は新版の配布後に実行してください。最低対応ビルド番号を0にすると更新必須化を解除できます。メンテナンス終了では最低対応ビルド番号を変更しないため、更新必須化も解除したい場合は別途変更してください。設定の取得に失敗すると、オンライン版ではアプリ内で再確認が必要です。

### 端末カレンダー連携

Androidのオンライン版では、カレンダー画面の「端末カレンダー連携」から読み取りを許可し、アカウントごとに表示対象を選びます。Google等の予定は、あらかじめ端末のカレンダー同期を有効にしてください。端末に同期された範囲だけを表示し、予定の編集や他メンバーへの共有は行いません。選択した予定はホーム画面のカレンダーウィジェットにも表示し、ウィジェットの更新時に端末から読み直します。

Androidのカレンダー権限を取り消した場合は、端末の設定から再度許可してください。

### アプリモードと成果物

`run`・`build`・`release`・`check`の第1引数は`online`または`offline`で、省略時は`online`です。両モードは同じ端末にインストールできますが、データは共有しません。機能の違いは[ユースケース図](./project_docs/usecase_diagram.md)を参照してください。

テスト対象や追加オプションはモードの後ろへ指定します（例: `just check offline test/unit/`）。

表示用のバージョン名は`pubspec.yaml`で管理します。オンライン版のビルド番号はリリースごとに自動採番し、デバッグ実行・ビルドでは現在の採番値を使用します。オフライン版はFirestoreに接続せず、`pubspec.yaml`のビルド番号を使用します。オンライン版への`--build-number`の指定はできません。

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
