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

- [ユーザーストーリー](./docs/user_stories.md) - 利用シナリオと受け入れ条件
- [ER図](./docs/er_diagram.md) - データベース設計
- [ユースケース図](./docs/usecase_diagram.md) - 主要な利用目的とアプリモードごとの利用可否
- [ADR](./docs/adr/) - 今後も維持するアーキテクチャ上の判断
- [TODO一覧](./docs/todo.md) - 開発進捗

## 開発環境

### Docker ComposeとSSH

開発環境はDocker Composeで起動します。ホストにDocker Engine・Compose・Git・SSHクライアントを用意し、`~/.gitconfig`を設定してください。WSL2でも利用できます。

ホストのリポジトリルートで起動します。

```bash
./dev_up.sh
```

コンテナへ渡す環境変数は、初回起動時に作成される`docker/.env`に設定します。アプリのコード生成用の`.env`とは別です。初回のビルド・セットアップにはインターネット接続が必要です。

コンテナへ入る方法は、Docker経由またはSSHを選べます。

```bash
docker compose exec dev bash
ssh -i ssh_keys/memora_ed25519 -p 2222 root@localhost
```

作業ディレクトリは`/workspaces/memora`です。SSH接続後はこのディレクトリへ移動してください。VS CodeではRemote-SSHを使用できます。

停止・再起動はホストで実行します。

```bash
docker compose stop dev
./dev_up.sh
```

開発環境の動作確認は、ホストから`bash docker/test_dev.sh`を実行します。

### ヘッドレスAndroidエミュレータ

必要なときだけ起動します。ホストはx86_64のLinux環境とし、Dockerから`/dev/kvm`へアクセスできるようにしてください。WSL2でもDocker Engineを動かす環境で`ls -l /dev/kvm`を確認します。

外部通信とGoogleサービスは利用できないため、オフライン版の確認に使用します。初回ビルドにはインターネット接続が必要です。

開発コンテナのリポジトリルートで実行します。実機の誤操作を避けるため、端末IDを指定してください。

```bash
docker compose up -d --wait emulator
emulator_serial=localfilesystem:/root/.android/memora-adb/adbd.sock
adb connect "$emulator_serial"
./run.sh offline -d "$emulator_serial"
adb -s "$emulator_serial" exec-out screencap -p > /tmp/memora-screen.png
```

`run.sh`を終了してから、エミュレータを切断・停止します。端末内のデータは次回起動時も残ります。

```bash
adb disconnect "$emulator_serial"
docker compose stop emulator
```

エミュレータ環境の動作確認は、`bash docker/test_emulator.sh`を実行します。終了時にエミュレータは停止します。

### Google Cloud Platform API設定

Google Cloud Consoleで以下のAPIを有効化し、対応するAPIキーを設定してください。

- **Maps SDK for Android**: Androidで地図機能を利用するために必要。`android/local.properties`に`MAPS_API_KEY`として設定
- **Places API (New)**: 地名検索・ピン位置の場所名取得で必要。`android/local.properties`の`MAPS_API_KEY`を使用

#### 環境構築手順

1. 環境変数ファイルを作成

   ```bash
   cp .env.example .env
   # .envに必要な環境変数を設定
   ```

2. 依存関係をインストール

   ```bash
   flutter pub get
   ```

3. 環境変数から設定コードを生成

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. `.env`ファイルを削除（機密情報を含むため）

   ```bash
   rm .env
   ```

5. Androidの`local.properties`を設定

   ```bash
   # android/local.propertiesの例
   sdk.dir=/path/to/your/android/sdk
   flutter.sdk=/path/to/your/flutter/sdk
   flutter.buildMode=debug
   flutter.versionName=1.0.0
   flutter.versionCode=1

   # Google Maps / Places SDK for Android APIキー
   MAPS_API_KEY=your_maps_api_key_here
   ```

### アプリモード指定

実行、debug APKビルド、release APKビルド、テストは、各スクリプトの第1引数に`online`または`offline`を指定します。省略時は`online`です。両方を同じ端末にインストールできますが、データは共有されません。機能の違いは[ユースケース図](./docs/usecase_diagram.md)を参照してください。

テストはフォーマット・コード生成・解析も行う`check.sh`から実行します。

```bash
./run.sh
./run.sh offline
./build.sh
./build.sh offline
./release.sh
./release.sh offline
./check.sh
./check.sh offline
```

テスト対象や追加オプションを指定する場合は、`check.sh`のモードの後ろへ指定します。

```bash
./check.sh offline test/unit/
```

成果物は次のパスへ出力されます。

- オンライン版: `build/app/outputs/flutter-apk/memora-<version>-online.apk`
- オフライン版: `build/app/outputs/flutter-apk/memora-<version>-offline.apk`

同一端末へ両方をインストールする場合は、生成したバージョンに合わせて次のように実行します。

```bash
adb install -r build/app/outputs/flutter-apk/memora-1.0.0-online.apk
adb install -r build/app/outputs/flutter-apk/memora-1.0.0-offline.apk
```

初期化またはアンインストールする場合は、対象のapplication IDを指定します。対象アプリのデータは削除されます。

```bash
adb shell pm clear com.example.memora
adb shell pm clear com.example.memora.offline
adb uninstall com.example.memora
adb uninstall com.example.memora.offline
```

### Firebase設定

オンラインモードはデータ永続化にFirebase/Firestore、認証にFirebase Authenticationを使用します。Firebase Consoleで以下のAPIを有効化してください。

- **Identity Toolkit API**: Firebase Authenticationに必要
- **Token Service API**: セキュアなトークン管理に必要

#### 必要な設定ファイル

- `firebase_options.dart` - 生成されたFirebase設定ファイル
- `firebase.json` - Firebaseプロジェクト設定ファイル

#### Firebaseセットアップ手順

1. Firebaseプロジェクトを作成
   - [Firebase Console](https://console.firebase.google.com/)にアクセス
   - 新規プロジェクトを作成、または既存プロジェクトを選択
   - AuthenticationとFirestore Databaseを有効化

2. 必要なサービスを有効化
   - Authentication（Google/メールアドレス・パスワード）を有効化
   - Firestore Databaseを本番モードで有効化
   - 必要に応じてFirestoreセキュリティルールを設定

3. Firebaseセットアップスクリプトを実行

   ```bash
   ./setup_firebase.sh
   ```

   画面の案内に従ってログインし、対象のFirebaseプロジェクトを選択してください。この操作でFirestoreインデックスもデプロイされます。

## ライセンス

このプロジェクトはGNU Affero General Public License v3.0（AGPL-3.0）の下で公開されています。  
詳細は[LICENSE](./LICENSE)を参照してください。
