# CLAUDE.md

## プロジェクト概要

**このアプリ（memora）について**
- ユーザーが家族などのグループ内での過去と未来のイベントを記録・共有できるアプリケーション
- メイン機能は以下の情報を年表形式で俯瞰する画面
    - グループのイベント・旅行
    - 個人のイベント
- メンバーの管理画面があり、メンバーの追加・削除・情報更新ができる
- メンバーとグループという概念があり、グループに1人以上のメンバーが所属する
- メンバーは所属するグループを設定するが、必須ではない
- メンバーは複数のグループに所属することが可能
- メンバーに紐づけて登録できるデータは以下
    - イベント（member_event）
- グループに紐づいて登録できるデータは以下
    - 旅行情報（trip_entry）
    - イベント（group_event）
- 旅行情報（trip_entry）には位置情報（pin）が紐づく
- 位置情報（pin）はGoogle Maps上にピン留めして作成することができ、訪問日やメモを追加することができる
- 旅行の参加者（trip_participant）はグループ外のメンバーも含めることができる

**設計資料**
- ER図: doc/er_diagram.md
- ユースケース図: doc/usecase_diagram.md
- todo: doc/todo.md

**主要コマンド**
- `flutter run` - アプリケーションを実行
- `flutter test` - 全テストを実行（コミット前に必須）
- `flutter analyze` - 静的コード解析（コミット前に必須）
- `flutter pub get` - 依存関係をインストール
- `flutter pub run build_runner build --delete-conflicting-outputs` - モックやコード生成を実行

**テストファイル**
- `flutter test test/unit/` - ユニットテストのみ実行
- `flutter test test/integration/` - インテグレーションテストを実行
- 目標は80%以上のテストカバレッジ

## アーキテクチャ

このプロジェクトは**クリーンアーキテクチャ**を参考に、3つの主要レイヤーで構成しています。

### ドメインレイヤー (`lib/domain/`)
- **エンティティ:** コアビジネスオブジェクト
- **リポジトリ:** データアクセス用の抽象インターフェース
- **サービス:** 外部サービス用の抽象インターフェース

### アプリケーションレイヤー (`lib/application/`)
- **ユースケース:** ビジネスロジック実装
- **マネージャー:** アプリケーション状態管理

### インフラストラクチャレイヤー (`lib/infrastructure/`)
- **リポジトリ:** Firebaseを使用した具体的実装
- **サービス:** 外部サービス実装
- **マッパー:** レイヤー間のデータ変換

### プレゼンテーションレイヤー (`lib/presentation/`)
- UIウィジェットと画面

## 作業の進め方
- 常に日本語で会話すること
- 作業内容を説明しながら進めること
- コンテキストが不明瞭な時は、ユーザーに確認を行うこと
- 作業は段階的に進め、各ステップで結果を確認すること
- 必ず全体の構成を把握してから作業に入ること
- 変更点は最小限に留め、必要な部分のみを修正すること
- 既存のコードを尊重し、変更が必要な場合はその理由を明確にすること
- コードを追加/変更する場合は原則としてTDDで進めること
- 2回以上連続でテストを失敗した時は、作業を一時中断し、ユーザーに判断を仰ぐこと
- 作業の前に、必ず`doc/todo_list.md`を確認し、ToDoリストに沿って進めること。
- `doc/todo_list.md`はユーザーが管理するため、変更しないこと。
- コマンド実行は1つずつ行い、結果を確認しながら進めること
- 作業の最後に必ず`flutter analyze`と`flutter test`を実行すること
- コミット前に`flutter analyze`と`flutter test`を必ず実行すること

## スタイルガイドライン
- インデントは2スペース
- 文字列は原則としてシングルクォーテーション使用
- constを積極的に使用する
- 不要なprintはコミット前に削除
- ファイル名・ディレクトリ名はsnake_case
- クラス名はUpperCamelCase
- 変数名・関数名はlowerCamelCase
- 定数はSCREAMING_SNAKE_CASE
- コメントは最小限にし、コードを見ればわかることはコメントしないこと

## TDDワークフロー
1. **Red:** まずテストケースを書き、失敗することを確認する
2. **Green:** 必要最小限の実装でテストを通す
3. **Refactor:** コードを整理し、リファクタリングする。テストが引き続き通ることを確認する

## コミット形式
- `[feat]` 新機能の概要
- `[fix]` 修正内容の概要
- `[refactor]` リファクタ内容の概要
- `[docs]` ドキュメントの更新内容
- `[test]` テストの追加・修正内容
- `[chore]` その他の変更

## Lint設定
- flutter_lintsパッケージを使用
- analysis_options.yamlでprefer_const_constructors常に有効化、avoid_printエラー扱い

## その他
- 非同期処理にはasync/awaitを使用し、thenチェーンは避ける

## 主要技術

- **Flutter 3.32.2** with Dart SDK ^3.8.0
- **Firebase:** データ永続化用のCloud Firestore
- **Google Maps Flutter** マップ機能用
- **Geolocator** 位置情報サービス用
- **Google Places API** 位置検索用
- **Mockito** テスト用

## 環境設定

`.env`の環境変数:
- `GOOGLE_PLACES_API_KEY` - 位置検索機能に必要

環境変数の変更後は`flutter pub run build_runner build --delete-conflicting-outputs`を実行してください。

## Firebase設定

アプリはFirestoreを使用してデータを永続化します。設定ファイル:
- `firebase_options.dart` - 生成されたFirebase設定
- `firebase.json` - Firebaseプロジェクト設定

## テスト方針
- ユニットテスト: test/に配置
- ディレクトリ構成はlib/と同じにする
- テスト命名はxxx_test.dartとする
- 外部依存関係にはMockitoを使用したモックを使用する
- カバレッジ目標: 80%以上
- flutter analyzeを通過することを必須とする