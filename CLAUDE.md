# CLAUDE.md

## 設計資料

- アプリケーション仕様： docs/app_spec.md
- ユーザーストーリー: docs/user_stories.md
- ユースケース図: docs/usecase_diagram.md
- ER図: docs/er_diagram.md
- todo: docs/todo.md
- done: docs/done.md

## 主要コマンド

- `flutter run` - アプリケーションを実行
- `flutter pub get` - 依存関係をインストール
- `flutter clean` - ビルドキャッシュをクリア
- `dart run build_runner build --delete-conflicting-outputs` - モックやコード生成を実行
- `./check.sh` - フォーマット・解析・テストを一括実行
- `flutter analyze` - 静的コード解析
- `dart format .` - コードフォーマット
- `dart pub global run very_good_cli:very_good test` - 全テストを高速に実行
- `flutter test test/unit/` - ユニットテストのみ実行
- `flutter test test/integration/` - インテグレーションテストを実行
- `tree lib test` - アプリケーションとテストのディレクトリ構造を表示

## 基本ルール

- 常に日本語で会話すること
- コメントやテスト名は日本語で記載すること
- 差分が発生する作業を行う場合、現在がmainブランチなら`CLAUDE.md`の「ブランチ名」に従って新しく作業用ブランチを切り、必ずその上で進めること
- `CLAUDE.md`の「MCP使用ルール」に従い、必要に応じてMCPを活用すること
- `docs/todo.md`の項目はチェックボックス形式である必要はない（通常の箇条書きでも可）
- `todo`を作成・整理する作業自体を表す`todo`項目は作成しないこと
- `.gitignore`で除外されているファイルを`git add -f`で強制的に追跡させる行為は絶対に禁止
- 詳細なコーディング手順とテスト方針は`.codex/skills/coding-preparation`、`.codex/skills/coding`、`.codex/skills/coding-completion`、`.codex/skills/test-coding`を参照すること

## MCP使用ルール

### Serena MCP使用ルール

Serena MCPは、コードベースの理解と効率的なコード探索を支援するツール。以下の状況で積極的に活用すること:

- コード探索時: ファイル全体を読み込む前に、シンボル(クラス、メソッド、関数など)単位で効率的にコードを把握できる
- ファイル構造の把握: 大きなファイルの全体像を把握したい場合、まずファイルの構造(シンボルの一覧)を確認してから必要な部分のみ読むことで、トークン消費を削減できる
- 影響範囲の調査: コードを変更する前に、その変更が他のどの部分に影響を与えるか(参照関係)を調査できる
- 柔軟な検索: 正規表現を使った柔軟なパターン検索により、具体的なシンボル名が不明な場合でもコードを探索できる

### GitHub MCP使用ルール

- プルリクエスト作成時: `mcp__github__create_pull_request`を使用してプルリクエストを作成する（`gh pr create`は使用禁止）
- GitHub関連の操作: `mcp__github__*`で始まるMCPコマンドを使用する（`gh` CLIは使用禁止）

### Context7 MCP使用ルール

- 新しいライブラリ・パッケージ使用時: 必ず`mcp__context7__resolve-library-id`と`mcp__context7__get-library-docs`で最新ドキュメントを取得する
- Flutter/Dartパッケージ調査時: Context7で公式ドキュメントを確認してから実装する
- `pubspec.yaml`に依存関係追加前: Context7で該当ライブラリの最新情報と使用方法を確認する
- API使用方法が不明な場合: Context7でドキュメントを取得してから実装する

## アーキテクチャ

Robert C.Martinが提唱した『クリーンアーキテクチャの原則』に従います。

### クリーンアーキテクチャの原則

- 依存関係逆転の原則: 外側の層が内側の層に依存し、内側の層は外側の層を知らない
- 関心の分離: 各層は明確に分離された責任を持つ
- テスタビリティ: フレームワークやデータベースに依存しない設計
- 独立性: ビジネスルールは外部要因から独立している

## コーディング規約

- インデントは2スペース
- 文字列は原則としてシングルクォーテーション使用
- constを積極的に使用する
- 不要なprintはコミット前に削除
- ファイル名・ディレクトリ名はsnake_case
- クラス名はUpperCamelCase
- 変数名・関数名はlowerCamelCase
- 定数はSCREAMING_SNAKE_CASE
- コメントは最小限にし、コードを見ればわかることはコメントしないこと

## ブランチ名

- `feature/` プレフィックスを付けて新機能のブランチ名を作成
- `bugfix/` プレフィックスを付けてバグ修正のブランチ名を作成
- `refactor/` プレフィックスを付けてリファクタリングのブランチ名を作成
- `docs/` プレフィックスを付けてドキュメントの更新ブランチ名を作成
- `test/` プレフィックスを付けてテストの追加・修正
- `chore/` プレフィックスを付けてその他の変更ブランチ名を作成

## コミット形式

Conventional Commits仕様に従います。

### 基本形式

```text
<type>(<scope>): <subject>

<body>

<footer>
```

### 必須フィールド

- type: コミットの種類（必須）
- subject: コミットの概要（必須、50文字以内）

### オプションフィールド

- scope: 変更の範囲（オプション）
- body: 詳細な説明（オプション）
- footer: 破壊的変更やIssue参照（オプション）

### typeの種類

- `feat`: 新機能の追加
- `fix`: バグ修正
- `docs`: ドキュメントの変更
- `style`: コードの意味に影響しない変更（フォーマット、セミコロン等）
- `refactor`: バグ修正や新機能追加以外のコード変更
- `perf`: パフォーマンス改善
- `test`: テストの追加・修正
- `build`: ビルドシステムや外部依存関係の変更
- `ci`: CI設定ファイルやスクリプトの変更
- `chore`: その他の変更（設定ファイル、依存関係等）

### scopeの例

- `auth`: 認証関連
- `ui`: UI関連
- `api`: API関連
- `db`: データベース関連
- `config`: 設定関連

### 例

```text
feat(auth): ログイン機能を追加

Google認証とメール認証に対応
セッション管理機能も含む

Closes #123
```

```text
fix(ui): ボタンの表示位置を修正
```

```text
docs: READMEの更新

インストール手順を追加
```

### 破壊的変更

破壊的変更がある場合は、typeの後に`!`を付けるか、footerに`BREAKING CHANGE:`を記載：

```text
feat!: APIエンドポイントを変更

BREAKING CHANGE: /api/v1/users を /api/v2/users に変更
```

## Lint設定

- flutter_lintsパッケージを使用
- analysis_options.yamlでprefer_const_constructors常に有効化、avoid_printエラー扱い

## 環境設定

`.env`の環境変数:

- `GOOGLE_PLACES_API_KEY` - 位置検索機能に必要

環境変数の変更後は`dart run build_runner build --delete-conflicting-outputs`を実行してください。

## Firebase設定

アプリはFirestoreを使用してデータを永続化する。

- 設定ファイル:
  - `firebase_options.dart` - 生成されたFirebase設定
  - `firebase.json` - Firebaseプロジェクト設定
