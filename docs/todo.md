# ToDo List

## DB設計・リポジトリ・ユースケース・DTO・マッパー関連

## マップの表示


## トップ画面


## アカウント管理


## グループ管理


## メンバー管理画面

## グループ管理画面


## グループ年表画面

## 旅行管理画面

## マップピンボトムシート

## 招待機能

## グループイベント

## メンバーイベント

## DVCポイント計算画面
- DVCの年月選択に`showDatePicker`を直接使用しているため、共通処理へ置き換える

## デザイン

## 全体

## リファクタリング
- DBのフィールド名更新し、移行スクリプト作成およびfirestore.indexes.jsonの更新
  - pinsのフィールド名を変更し、エンティティ含め関連箇所を修正
    - visitStartDate→visitStartDateTime
    - visitEndDate→visitEndDateTime
    - visitMemo→memo

## 不具合修正
