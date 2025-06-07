# 開発ルール
## 応答
- 応答は日本語で行うこと。
- 作業内容を説明しながら進めること。

## 作業の進め方
- 作業は段階的に進め、各ステップで結果を確認すること。
- 必ず全体の構成を把握してから作業に入ること。
- 変更点は最小限に留め、必要な部分のみを修正すること。
- 既存のコードを尊重し、変更が必要な場合はその理由を明確にすること。
- テストが2回以上連続で発生した場合、一度作業を戻してコード全体を見直すこと。
- 作業の前に、必ず`doc/todo_list.md`を確認し、ToDoリストに沿って進めること。
- `doc/todo_list.md`はユーザーが管理するため、Copilotは直接編集しないこと。
- 作業の最後に必ず`flutter analyze`と`flutter test`を実行すること。
- TDDサイクルを遵守して開発を進めること。

## コマンド実行
- コマンド実行は1つずつ行い、結果を確認しながら進めること。

## プロジェクト構成
- `lib/` 以下は以下のディレクトリ構成とする:
    - `application/`: ユースケースロジック
    - `domain/`: エンティティ、モデル
    - `infrastructure/`: 外部依存（DB、API）
    - `presentation/`: UI層（Widget、ページ）
    - `main.dart`: エントリーポイント

## TDDサイクル遵守
- `doc/todo_list.md` にToDoリストに対して、TDDサイクルで開発を進める。
1. Red:
    - まずテストケースを書く。
    - 失敗することを確認する。
2. Green:
    - 必要最小限の実装でテストを通す。
3. Refactor:
    - コードを整理し、リファクタリングする。
    - テストが引き続き通ることを確認する。

## 命名規則
- ファイル名・ディレクトリ名: snake_case
- クラス名: UpperCamelCase
- 変数・関数名: lowerCamelCase
- 定数: SCREAMING_SNAKE_CASE

## コードスタイル
- インデントは2スペース
- 行の最大長は120文字
- 文字列は基本的にシングルクォーテーション
- constを積極的に使用する
- 不要なprintはコミット前に削除

## Lint 設定
- flutter_lintsパッケージを使用
- analysis_options.yamlで以下を設定:
    - prefer_const_constructors: 常に有効化
    - avoid_print: エラー扱い

## テスト方針
- ユニットテスト: test/に配置
- ディレクトリ構成はlib/と同じにする
- テスト命名はxxx_test.dartとする
- カバレッジ目標: 80%以上
- flutter analyzeを通過することを必須とする

## コミットルール
- コミット前にflutter analyzeとflutter testを必ず実行
- コミットメッセージは以下形式:
    - [feat] 新機能の概要
    - [fix] 修正内容の概要
    - [refactor] リファクタ内容の概要
    - [docs] ドキュメントの更新内容
    - [test] テストの追加・修正内容
    - [chore] その他の変更

## その他
- 非同期処理にはasync/awaitを使用し、thenチェーンは避ける
