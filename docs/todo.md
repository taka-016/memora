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

- Timeline内のグループイベント編集モーダルを独立させ、`group`配下から再利用可能にする
  - `timeline.dart`内の`_GroupEventEditDialog`と起動処理を分離し、`lib/presentation/features/group/`直下に単独ソースを作成する
  - 呼び出し側は`selectedYear`、`initialMemo`、`onSave`を渡すだけのAPIにし、Timeline固有の状態や依存を持ち込まない
  - 既存の表示文言、保存・キャンセル動作、保存失敗時のフィードバック、`Key`は原則維持する
  - Timeline側は新しいモーダル起動関数を呼ぶだけにし、画面本体からグループイベント編集UIの詳細実装を除去する
- Timeline内のDVCポイント利用詳細モーダルを独立させ、`dvc`配下から再利用可能にする
  - `timeline.dart`内のDVCポイント利用詳細`AlertDialog`を`lib/presentation/features/dvc/`直下の単独ソースへ移す
  - 起動APIは`selectedYear`と対象`usages`を受け取り、年表以外の画面からも呼び出せる形にする
  - 既存の表示内容（利用年月、利用ポイント、メモ）と`Key`を原則維持し、空データ時の扱いも呼び出し側と実装側で責務を整理する
  - `dvc_*_modal.dart`群と命名・公開形式を揃え、Timeline側は空判定と起動処理に責務を絞る
- Timelineのレイアウト定数を設定オブジェクトへ集約し、Controllerへまとめて渡せるようにする
  - 年表示範囲、行高さ、列幅、リサイズ制約、余白などの定数を用途ごとに整理する
  - `useTimelineController`の引数を個別値の列挙から設定オブジェクト受け取りへ変更する
  - `timeline.dart`内の定数参照とController内部の寸法計算の参照元を統一する
  - 今後レイアウト定数が増えても、WidgetとControllerの双方に引数を追加し続けなくてよい構成にする
- `TimelineDisplaySettings`に表示設定定義を持たせ、設定UIを定義ベースで自動生成できるようにする
  - 各表示項目について、保存キー、表示名、現在値の参照、更新方法を表現できる構造を追加する
  - `timeline.dart`の`SwitchListTile`ベタ書きを廃止し、設定定義の一覧から表示項目を生成する
  - 既存のSharedPreferencesキーと既定値は維持しつつ、項目追加時にUI実装と保存処理の修正箇所が増えにくい形にする
  - 既存テスト観点（設定読み込み、トグル操作、保存反映）が定義ベース実装でも維持されるようにする

## 不具合修正
