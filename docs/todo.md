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

- `group_timeline.dart`の状態管理・副作用・スクロール同期を先に分離し、`GroupTimeline`本体の責務を「画面レイアウト・既存Dialog起動・行/列の組み立て」に絞る
  - 初回対応では行描画の別ファイル化を優先しない
  - まずは本体を小さくする効果が大きい箇所から着手する
  - 既存の見た目、操作、`Key`名、テスト観点を原則維持し、リファクタリングによる挙動変更を入れない
- 分離対象は以下を優先する
  - 年の表示範囲状態と`visibleYears`算出
  - trips / group events / DVC point usages の取得と`refreshTimelineData`
  - 表示設定の読み書き
  - 行高さの状態管理と更新
  - 横スクロール用`ScrollController`の生成・破棄・同期
  - 初期表示時の現在年へのスクロール
  - `onSetRefreshCallback`への再読込登録
- 分離先は`Hook`または`Controller`として、UI Widgetから副作用コードを追い出すことを優先する
  - `GroupTimeline`から`useEffect`と`useState`の大半を移し、UI側は結果を受け取って描画する形にする
  - usecase呼び出しは分離先に集約し、`GroupTimeline`が個別usecaseを直接読む箇所を最小化する
- 初回対応では以下は後回しとする
  - 行描画の別ファイル化
  - 年表ヘッダー、設定シート、行リサイズUIの別Widget化
  - UI仕様変更、色変更、文言変更
  - 新規パッケージ追加

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

## 不具合修正
