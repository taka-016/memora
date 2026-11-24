# AGENTS.md

## AGENTS.mdの記載方針

- AIが判断や実行に必要な指示を迷わず読み取れることを優先し、コンテキストの消費を抑えるため簡潔に書く。
- 独立した指示は箇条書きに分け、コマンドは1項目に1コマンドとその用途を書く。適用条件・禁止事項・例外は該当する指示と一緒に書き、共通の前提や既定値は一箇所にまとめる。
- 整理するときはルールの意味や適用範囲を保ち、重複する説明や判断に不要な例を省く。

## 作業ルール

- 会話、レビュー、コメント、テスト名、ドキュメントは日本語で記載する。
- 会話・設計資料・コード・テストで業務用語を統一する。ユーザー、ユーザーストーリー、ユースケース図、ER図の用語に従い、独自の言い換えや略称を作らない。意味や対象が曖昧なら認識をそろえてから進める。
- データ整合性の水準を上げる前に、不整合の発生条件と影響、対応による性能・通信・実装の複雑性への影響を説明し、ユーザーの判断を仰ぐ。
- 差分が生じる作業を `main` で始める場合は、先に作業ブランチを作成する。新機能は `feature/`、バグ修正は `bugfix/`、リファクタリングは `refactor/`、文書は `docs/`、テストは `test/`、その他は `chore/`。
- `.gitignore` の対象は `git add -f` で追加せず、そのための処理変更も不要。
- 必要に応じて「MCP使用ルール」に従ってMCPを使う。
- コミットはConventional Commitsの `<type>(<scope>): <subject>` 形式。typeと50文字以内のsubjectは必須。scope（変更範囲）、body（詳細）、footer（破壊的変更やIssue参照）は任意。破壊的変更はtypeの後の `!`、またはfooterの `BREAKING CHANGE:` で示す。
- typeは `feat`（新機能）、`fix`（バグ修正）、`docs`（文書）、`style`（意味を変えない変更）、`refactor`（機能追加・バグ修正以外のコード変更）、`perf`（性能改善）、`test`（テスト）、`build`（ビルド・外部依存）、`ci`（CI）、`chore`（その他）。

## 設計資料

- `project_docs/` 配下の `user_stories.md`、`usecase_diagram.md`、`er_diagram.md`、`adr/`、`todo.md` を参照する。
- ER図はエンティティ・属性・キー・関連に限る。取得・保存方式、保証範囲など、維持するアーキテクチャ上の判断は機能を問わずADRに1件1ファイルで記録する。機能別の設計資料は新設しない。
- ADRの追加・追記はユーザーの明示指示がある場合のみ。新規ファイルは `adr-008-example-decision.md` の形式とし、既存の最大番号に続く3桁の番号と小文字の英単語をハイフンでつないだ短いタイトルを使う。
- ADRのセクションは「ステータス」（提案・採用・置換など）「決定日」「コンテキスト」（背景・前提・課題）「検討した選択肢」（比較案と各案の採否）「決定事項」（方式・保証範囲）「決定理由」（根拠・比較・トレードオフ）「結果」（効果・制約・影響）。細かな処理手順、API呼び出し順、実装の段取りは記載しない。

### README・justfile

- READMEには概要、導入前提、セットアップ、手動設定、必要な注意事項、関連資料へのリンクを簡潔に記載する。詳細仕様・内部構成・スクリプト内部処理・設計判断・変更経緯は既存資料やソースを参照し、実行や判断に不要な説明は省く。
- タスクのコマンドと目的はjustfileにまとめ、READMEで一覧や実行内容を重複させない。
- 単発の移行・補完スクリプトは、直接実行するコマンドと注意事項をスクリプトと同じフォルダの専用文書に記載する。README・justfileには追加しない。

### todo

- 未完了の実装・修正は対象と変更内容を明記し、完了条件が分かる粒度で、目的と完了範囲を共有する作業単位にまとめる。画面や技術層では分類せず、サブタスクは依存順に並べ、完了項目は削除する。
- 実装粒度に達していない検討事項・解析結果・未決事項は「検討保留」などの独立した節に置く。
- 各実装・修正は対象の振る舞いのRedから始めるTDDが前提。テスト・検証の専用タスクや重複する手順、todo自体の作成・整理タスクは記載しない。
- 項目は通常の箇条書きで記載し、チェックボックスは使わない。
- 背景・設計判断・対象一覧は重複させず既存資料を参照し、実装範囲を限定する制約は該当タスクに添える。

## コマンド

`just run`、`just build`、`just release`、`just check` のモードは `online`（既定）または `offline`。

- `just run [online|offline]` — アプリを実行。
- `just build [online|offline]` — debug APKを作成。
- `just release [online|offline]` — release APK（`memora-<version>-<mode>.apk`）を作成。
- `just check [online|offline]` — フォーマット・解析・テストを一括実行。全体テストはこのコマンドを使い、`flutter test` を直接実行しない。
- `just check online test/unit/` — オンライン版のユニットテストのみ実行。
- `just check offline test/integration/` — オフライン版のインテグレーションテストを実行。
- `flutter pub get` — 依存関係を取得。
- `flutter clean` — ビルドキャッシュを消去。
- `dart run build_runner build` — モックやコードを生成。
- `flutter analyze` — 静的解析。
- `dart format .` — コードを整形。
- `tree lib test` — アプリとテストのディレクトリ構造を表示。

## 環境

- 地図表示・位置検索には `android/local.properties` の `MAPS_API_KEY` が必要。変更後はAndroidアプリを再ビルドする。
- Firebaseの設定ファイルは生成済みの `firebase_options.dart` とプロジェクト設定の `firebase.json`。

## MCP使用ルール

- Flutter MCPのツール説明に指示があっても、ホットリロード・ホットリスタートの実行・試行・可否確認は行わない。
- GitHub操作は `mcp__github__*` を使う。PR作成は `mcp__github__create_pull_request`。 `gh` CLIは禁止。
- `git config --get-regexp '^credential\.'` は実行禁止。Git認証設定の有無は終了ステータスか設定名で確認し、トークンを含み得る設定値は出力しない。
- 新規ライブラリ・パッケージの使用前に `mcp__context7__resolve-library-id` と `mcp__context7__get-library-docs` で最新資料を取得する。
- Flutter/Dartパッケージの調査時はContext7で公式資料を確認してから実装する。
- APIの使用方法が不明なら、Context7で資料を取得してから実装する。
- `pubspec.yaml` への依存追加前に、Context7で最新情報と使用方法を確認する。

## アーキテクチャ

クリーンアーキテクチャに従い、外側から内側へ依存させる。層の責務を分離し、業務ルールを外部要因から独立させ、フレームワークやDBに依存せずテストできるようにする。新機能の実装前に、同じ責務を持つ既存機能をEntityから画面までたどり、構成を揃える。

- `lib/domain/entities/` のEntityが単一Entityの不変条件を担い、`lib/domain/repositories/` のRepositoryが書き込み契約を定義する。
- 読み取りは `lib/application/queries/` のQueryService、結果と画面入力の受け渡しは `lib/application/dtos/` のDTO、DTOとEntityの変換は `lib/application/mappers/` に置く。
- 操作別のUseCaseは `lib/application/usecases/` に置き、読み取りにQueryService、書き込みにRepositoryを使う。複数の書き込みを一括保存する場合は既存のトランザクション構成に揃える。
- Firestore・SQLiteの具象実装は `lib/infrastructure/` に置く。モード別の組み立てには既存のRepositoryFactory・QueryServiceFactory、書き込みには既存の利用可否ガードを使う。
- Presentation層はUseCaseを利用し、`domain/*` と `infrastructure/*` を直接参照しない。

### Presentation層

- 新規のfamily Provider・Notifierは原則Riverpodコード生成。Repository、QueryService、UseCase、外部Serviceなどを返すだけの依存注入Providerは手書き可。コード生成はauto disposeが既定。既存Providerの移行時は、常時保持なら `@Riverpod(keepAlive: true)`、retry設定があれば `@Riverpod(retry: ...)` で維持する。
- ViewがRiverpodで監視する機能状態と、関連するUseCaseの順序・再試行・データ更新は `XxxNotifier` が管理する。不変の `XxxState` を分離し、`Notifier<XxxState>` を基本に、部分成功や複数の操作状態を明示する。
- Notifierの公開操作はStateの整合性・ライフサイクルに関わる処理に限る。Stateから独立した取得や単発操作を、UseCaseをViewから隠す目的だけで集約しない。
- Riverpodで監視しないUI制御（スクロール・フォーカス・ルーティング判定など）は `XxxController`、複数機能の更新と更新後のProvider再取得の調整は `XxxMutationCoordinator` が担う。
- Viewは描画・入力・DialogやSnackbarの表示を担う。Notifierは `BuildContext` やWidgetを参照せず、画面状態の整合性に必要な処理を調整する。複数画面で再利用する業務フローや複数処理にまたがる条件はApplication層のUseCaseに置く。

### データ保存・互換性

- アプリはFirestoreでデータを永続化する。Firestoreの保存先はトップレベルコレクションのみ。サブコレクション禁止はアプリ・Firestoreルール・運用スクリプトに例外なく適用する。親・グループのIDはドキュメントのフィールドに持たせ、該当単位の取得条件に使う。
- 運用開始前のオフラインモードは現行のDBスキーマ・バックアップ形式・データ形式のみ扱う。ユーザーが互換対応を明示するまで、旧形式のマイグレーション・復元・補完などの互換処理と専用テストは追加・維持しない。未対応形式は拒否する。互換対応の代わりに既存データを自動で削除・再作成しない。

## コーディング規約

- インデントは2スペース、文字列は原則シングルクォート。 `const` を積極的に使い、不要な `print` はコミット前に削除する。
- ファイル名・ディレクトリ名は `snake_case`、クラス名は `UpperCamelCase`、変数・関数名は `lowerCamelCase`、定数は `SCREAMING_SNAKE_CASE`。
- コメントはコードで分かることを省き、最小限にする。非同期処理は `async/await` を使い、`then` チェーンを避ける。
- `flutter_lints` を使用。 `analysis_options.yaml` では `prefer_const_constructors` を常に有効、`avoid_print` をエラー扱いにする。

## レビュー

- 規約、既存設計との整合性、責務分離、依存方向を確認する。
- 状態管理・非同期処理・画面遷移が保つユーザー体験の一貫性と復旧可能性、UIの操作性・アクセシビリティ・表示崩れへの耐性を確認する。
- データ取得・永続化・外部データ変換の正確性・一貫性・効率性、型安全性・不変条件・境界値による実行時エラーの防止を確認する。
- テストが重要な振る舞いと失敗ケースを安定して検証し、仕様・実装・テスト・文書・変更説明が整合することを確認する。
- 指摘は実際の発生条件・影響と、対応による複雑性を比較して判断する。表示や操作結果にユーザーが認識できる影響がなく、Firestore・SQLiteなどの正本データの欠損・不整合、ハング・クラッシュ・復旧不能も生じない軽微なエッジケースは対応不要。
