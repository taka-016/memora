# CLAUDE.md

## 設計資料

- アプリケーション仕様： doc/app_spec.md
- ユーザーストーリー: doc/user_stories.md
- ユースケース図: doc/usecase_diagram.md
- ER図: doc/er_diagram.md
- todo: doc/todo.md

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

## 実装作業の進め方

### 基本ルール

- 常に日本語で会話し、コメントやテスト名は日本語で記載すること

### 作業準備手順

1. ユーザーからの指示に該当する作業が`doc/todo.md`に存在しない場合は、必ず作業を中断してユーザーに確認する
2. 現在がmainブランチの場合、新しく作業用のブランチを切る（[ブランチ名](#ブランチ名)に従う）
3. `tree lib test`でディレクトリ構造を確認する
4. [設計資料](#設計資料)を確認し、アプリケーション仕様を理解する

### 作業実施手順

1. t-wadaが提唱するTDDの定義に従って進めること
2. 作業中に仕様の判断が必要な場合、作業を中断してユーザーに確認すること
3. リファクタリングを行うときは、Martin Fowlerのリファクタリング定義に従うこと

### 作業完了手順

1. `./check.sh`を実行し、エラーが残っていないことが確認してから完了作業を進める
2. 作業に対応する`doc/todo.md`の項目に`[x]`チェックを入れる
3. 作業に関連するファイルを`git add <対象ファイル>`でステージングに追加する（`git add .`は禁止）
4. Conventional Commits仕様に従い、Commit & Push & Pull Requestを作成する
5. Pull Requestの説明は、作業に対応する`doc/todo.md`の項目を記載する

## アーキテクチャ

※Robert C.Martinが提唱した**クリーンアーキテクチャ**を参考にしています。

### クリーンアーキテクチャの原則

- 依存関係逆転の原則: 外側の層が内側の層に依存し、内側の層は外側の層を知らない
- 関心の分離: 各層は明確に分離された責任を持つ
- テスタビリティ: フレームワークやデータベースに依存しない設計
- 独立性: ビジネスルールは外部要因から独立している

### 4つのレイヤー構成

#### 1. エンティティ層 (`lib/domain/entities/`)

- エンタープライズビジネスルールを含む
- アプリケーション全体で最も重要なビジネスルール
- 外部の変更による影響を最も受けにくい
- データ構造とそれに関連する基本的なビジネスルールを定義

#### 2. ユースケース層 (`lib/application/usecases/`)

- アプリケーション固有のビジネスルールを含む
- システムのすべてのユースケースをカプセル化・実装
- エンティティとの間でデータの流れを調整
- データベースやUIの変更に影響されない

#### 3. インターフェースアダプター層 (`lib/infrastructure/`)

- データ変換を担当
- ユースケースやエンティティに便利な形式と、データベースやWebなどの外部機関に便利な形式の間でデータを変換
- repositories: データアクセス抽象化の具体実装
- services: 外部サービスの具体実装
- mappers: レイヤー間のデータ変換

#### 4. フレームワーク・ドライバー層 (`lib/presentation/`)

- 外部とのインターフェースを担当
- UI、データベース、Webフレームワークなど
- widgets: 再利用可能なUIコンポーネント
- auth: 認証関連のUI
- top_page.dart: トップページのUI（常にトップページを表示し、メニュー選択に応じてwidgetsを切り替える）

### 抽象化レイヤー (`lib/domain/repositories/`, `lib/domain/services/`)

- インターフェースアダプター層の具体実装に対する抽象インターフェース
- 依存関係逆転の原則を実現するための境界

### 状態管理 (`lib/application/managers/`)

- アプリケーション状態を管理
- ユースケース層との橋渡し役

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

- `feature/` 新機能のブランチ名を作成
- `bugfix/` バグ修正のブランチ名を作成
- `refactor/` リファクタリングのブランチ名を作成
- `docs/` ドキュメントの更新ブランチ名を作成
- `test/` テストの追加・修正
- `chore/` その他の変更ブランチ名を作成

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

- 非同期テストの制御: `Future.delayed`を使った待機は避ける。環境によって不安定になるため、`Completer`を使用してテストコードが非同期処理のタイミングを制御する

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
