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

- [アプリケーション仕様](./docs/app_spec.md) - 機能要件と画面構成
- [ユーザーストーリー](./docs/user_stories.md) - 利用シナリオと受け入れ条件
- [ER図](./docs/er_diagram.md) - データベース設計
- [ユースケース図](./docs/usecase_diagram.md) - システム利用シナリオ
- [TODO一覧](./docs/todo.md) - 開発進捗

## 開発環境

### Google Cloud Platform API設定

Google Cloud Consoleで以下のAPIを有効化し、対応するAPIキーを設定してください。

- **Maps SDK for Android**: Androidで地図機能を利用するために必要。`android/local.properties`に`MAPS_API_KEY`として設定
- **Places API**: 地名検索機能で必要。`.env`に`GOOGLE_PLACES_API_KEY`として設定

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

   # Google Maps APIキー
   MAPS_API_KEY=your_maps_api_key_here
   ```

### Firebase設定

本アプリはデータ永続化にFirebase/Firestore、認証にFirebase Authenticationを使用します。Firebase Consoleで以下のAPIを有効化してください。

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

   スクリプトが実施する内容:
   - Firebase CLIとFlutterFire CLIのインストール（未導入時）
   - Firebaseログイン手順の案内
   - Flutter向けFirebase設定（`flutterfire configure`）
   - `firebase.json`へのFirestoreインデックス設定追加
   - Firebaseプロジェクトエイリアス設定
   - 必要なFirestoreインデックスのデプロイ

## ライセンス

このプロジェクトはGNU Affero General Public License v3.0（AGPL-3.0）の下で公開されています。  
詳細は[LICENSE](./LICENSE)を参照してください。
