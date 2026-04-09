# ToDo List

## DB設計・リポジトリ・ユースケース・DTO・マッパー関連

- FirestoreのMapperは新規作成用と更新用で出し分ける方針に統一する
  - 新規作成時は`createdAt`と`updatedAt`の両方に`FieldValue.serverTimestamp()`を設定する
  - 更新時は`createdAt`を更新データに含めず、`updatedAt`のみ更新する
- FirestoreのRepositoryは既存ドキュメント更新時に全置換の`set`を使わず、`update`で差分更新する方針に統一する
  - 新規作成時のみ`add`または新規`doc`への`set`を使用する
  - 既存フィールドを保持したいが`update`を使えないケースがある場合のみ、理由を明記したうえで`set(..., SetOptions(merge: true))`を許容する

## マップの表示


## トップ画面


## アカウント管理


## グループ管理


## メンバー管理画面

## グループ管理画面


## グループ年表画面

## 旅行管理画面

## 地図画面

## マップピンボトムシート


## 招待機能

- 招待コードで紐づけたmemberを更新した後、使用済み招待コードのレコードは削除する
- 作成から24時間経過した招待コードは無効とする

## グループイベント

## DVCポイント計算画面

## デザイン

## 全体

## リファクタリング

- Timelineの各行を差し替え可能な行定義インタフェースへ分離し、設定に応じて表示行と順番を組み替えられる構成にする
  - `lib/presentation/features/timeline/rows/`配下を新設し、少なくとも`timeline_row_definition.dart`、`timeline_row_context.dart`、行定義の組み立て処理を置くファイルを追加する
  - 行定義インタフェースには少なくとも`rowId`、固定列表示、年セル描画、セルタップ処理、背景色、初期高さ、表示可否判定を持たせ、`timeline.dart`内の`rowIndex == 0/1/2`分岐を置き換える
  - `Timeline`本体は「ヘッダー描画」「行リストの共通レイアウト」「横スクロール同期」「行リサイズUI」だけを担当し、使用する行と順番は1つの行定義リストを差し替えるだけで変更できる構造にする
  - 旅行行、イベント行、DVC行はそれぞれ専用の行定義クラスへ切り出し、既存の`TripCell`、`GroupEventCell`、`DvcCell`と既存モーダル起動処理を再利用する
  - メンバー行は`GroupDto.members`から1人1行の行インスタンスを生成するファクトリ経由に変更し、固定3行と同じ描画経路・並び替え経路で扱う
  - `TimelineController`は行ごとの表示に必要な取得済みデータと操作を`TimelineRowContext`などの読み取り専用APIで公開し、各行実装がController内部状態やWidgetのローカル関数へ直接依存しないようにする
  - `TimelineViewState.rowHeights`は配列ではなく`rowId`をキーにした保持方法へ変更し、行順変更や表示ON/OFF後も別の行へ高さ設定がずれないようにする
  - 行の表示設定と並び順設定は端末ローカルではなくグループ単位で共有するため、`TimelineDisplaySettings`や`SharedPreferences`には追加しない
  - 行の表示設定と並び順設定は、Firestore上のグループに紐づく設定として保存できるデータ構造を新設し、未保存時の既定値は現行どおり`旅行 → イベント → DVC → メンバー行群`とする
  - グループ共有の行設定は`domain`、`application`、`infrastructure`の各層に必要なEntity、DTO、Repository、QueryService、Usecase、Mapperを追加し、Presentation層がFirestoreやRepositoryを直接参照しない構成にする
  - `timeline_display_settings.dart`は年齢・学年・厄年など端末ローカルでよい表示補助設定に限定し、グループ共有の行表示・並び順設定とは責務を混在させない
  - 既存の`Key`、タップ操作、モーダル起動、表示文言、配色は原則維持し、この対応ではUI仕様変更を入れない

## 不具合修正
