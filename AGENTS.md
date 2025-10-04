# AGENTS.md

## 設計資料

- アプリケーション仕様： docs/app_spec.md
- ユーザーストーリー: docs/user_stories.md
- ユースケース図: docs/usecase_diagram.md
- ER図: docs/er_diagram.md
- todo: docs/todo.md

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

## コーディングの進め方

### 基本ルール

- 常に日本語で会話すること
- コメントやテスト名は日本語で記載すること
- コメントはコードを見ても意図が読み取れない場合にのみ記載すること
- `CLAUDE.md`の**TDDワークフロー定義**に従って進めること
- `CLAUDE.md`の**MCP使用ルール**に従い、必要に応じてMCPを活用すること
- 作業中に仕様の判断が必要な場合、作業を中断してユーザーに確認すること

### 作業準備手順

1. ユーザーからの指示に該当する作業が`docs/todo.md`に存在しない場合は、**必ず作業を中断**してユーザーに確認する
2. 現在がmainブランチの場合、新しく作業用のブランチを切る（`CLAUDE.md`の**ブランチ名**に従う）
3. `tree lib test`でディレクトリ構造を確認する
4. `CLAUDE.md`の**設計資料**を確認し、アプリケーション仕様を理解する

### 作業完了手順

1. `./check.sh`を実行し、エラーが残っていないことが確認してから完了作業を進める
2. 作業に対応する`docs/todo.md`の項目に`[x]`チェックを入れる
3. 作業に関連するファイルを`git add <対象ファイル>`でステージングに追加する（`git add .`は禁止）
4. `CLAUDE.md`の**コミット形式**に従ってコミット&プッシュ&プルリクエストを作成する
5. プルリクエストの説明は、作業に対応する`docs/todo.md`の項目を記載する

## MCP使用ルール

### GitHub MCP使用ルール

- プルリクエスト作成時: `mcp__github__create_pull_request`を使用してプルリクエストを作成する（`gh pr create`は使用禁止）
- GitHub関連の操作: `mcp__github__*`で始まるMCPコマンドを使用する（`gh` CLIは使用禁止）

### Context7 MCP使用ルール

- 新しいライブラリ・パッケージ使用時: 必ず`mcp__context7__resolve-library-id`と`mcp__context7__get-library-docs`で最新ドキュメントを取得する
- Flutter/Dartパッケージ調査時: Context7で公式ドキュメントを確認してから実装する
- `pubspec.yaml`に依存関係追加前: Context7で該当ライブラリの最新情報と使用方法を確認する
- API使用方法が不明な場合: Context7でドキュメントを取得してから実装する

## アーキテクチャ

Robert C.Martinが提唱した**クリーンアーキテクチャの原則**に従います。

### クリーンアーキテクチャの原則

- **依存関係逆転の原則**: 外側の層が内側の層に依存し、内側の層は外側の層を知らない
- **関心の分離**: 各層は明確に分離された責任を持つ
- **テスタビリティ**: フレームワークやデータベースに依存しない設計
- **独立性**: ビジネスルールは外部要因から独立している

## TDDワークフロー定義

Kent Beckの原著『Test-Driven Development: By Example』とその翻訳者であるt-wadaの解釈に従います。

### Red - Green - Refactor サイクル

#### 1. **Red（失敗するテストを書く）**

- **新しい機能のための小さなテストを書く**
- テストを実行し、失敗することを確認する（Red）
- 実装コードは一切書かない
- 失敗理由が期待通りであることを確認する

#### 2. **Green（テストを通すコードを書く）**

- **テストを通すための最小限のコードを書く**
- テストを実行し、成功することを確認する（Green）
- 「最小限」を徹底し、テストを通すだけの実装に留める
- 美しさや設計の良さは一旦無視する

#### 3. **Refactor（重複を排除する）**

- **重複を排除し、設計を改善する**
- テストコードと実装コードの両方をリファクタリング対象とする
- リファクタリング後もすべてのテストが通ることを確認する
- 機能追加は行わず、既存コードの改善に専念する

### TDDの三原則（Kent Beck）

1. **失敗するユニットテストを書くまでは、実装コードを書いてはならない**
2. **コンパイルが通らず失敗するユニットテストを書く以上に、ユニットテストを書いてはならない**
3. **現在失敗しているテストを通す以上に、実装コードを書いてはならない**

### TDDで重要な考え方

- **小さなステップ**: 大きな問題を小さく分割して進める
- **仮実装**: まずは定数を返すなど、最小限の実装から始める
- **三角測量**: 複数のテストケースから一般化を行う
- **明白な実装**: 実装が自明な場合は直接書く

## リファクタリング定義

Martin Fowlerの著書『Refactoring: Improving the Design of Existing Code』に従います。

### 基本原則

- **外部振る舞いの保持**: 機能を変更せず、内部構造のみ改善
- **小さなステップ**: 一度に大きな変更をせず、小さな変更を積み重ね
- **テストによる安全性確保**: リファクタリング前後でテストが通ることを確認

### 実行条件

- **包括的なテストスイート**: リファクタリングの安全性を保証するテストが存在すること
- **機能追加との分離**: 機能追加とリファクタリングは同時に行わない

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

- **type**: コミットの種類（必須）
- **subject**: コミットの概要（必須、50文字以内）

### オプションフィールド

- **scope**: 変更の範囲（オプション）
- **body**: 詳細な説明（オプション）
- **footer**: 破壊的変更やIssue参照（オプション）

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

## その他

- 非同期処理にはasync/awaitを使用し、thenチェーンは避ける

## 環境設定

`.env`の環境変数:

- `GOOGLE_PLACES_API_KEY` - 位置検索機能に必要

環境変数の変更後は`dart run build_runner build --delete-conflicting-outputs`を実行してください。

## Firebase設定

アプリはFirestoreを使用してデータを永続化する。

- 設定ファイル:
  - `firebase_options.dart` - 生成されたFirebase設定
  - `firebase.json` - Firebaseプロジェクト設定

## テスト方針

- ユニットテストのディレクトリ構成はlib/と同じにする
- テスト命名はxxx_test.dartとする
- 外部依存関係にはMockitoを使用したモックを使用する
- カバレッジ目標: 80%以上

### テストファイル

- ユニットテスト: `test/unit/`
- インテグレーションテスト: `test/integration/`

### テストベストプラクティス

- **テストでの例外発生**: テストで例外を発生させる場合は、必ず`test/helpers/test_exception.dart`の`TestException`を使用すること。`TestException`はログ出力を抑制するため、テスト実行時のノイズを減らすことができる

  ```dart
  // ❌ 避けるべき方法
  when(mockUseCase.execute()).thenThrow(Exception('エラーメッセージ'));

  // ✅ 推奨する方法
  import '../../../helpers/test_exception.dart';

  when(mockUseCase.execute()).thenThrow(TestException('エラーメッセージ'));
  ```

- **非同期テストの制御**: `Future.delayed`を使った待機は避ける。環境によって不安定になるため、`Completer`を使用してテストコードが非同期処理のタイミングを制御する

  ```dart
  // ❌ 避けるべき方法
  when(mockUseCase.execute()).thenAnswer((_) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return result;
  });

  // ✅ 推奨する方法
  final completer = Completer<Result>();
  when(mockUseCase.execute()).thenAnswer((_) => completer.future);
  // テストコードで完了タイミングを制御
  completer.complete(result);
  ```
