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

- 経路検索機能を廃止する
  - `RouteInfoView`、`RouteMap`、経路検索ボタン、経路検索結果表示、経路検索結果保存処理を削除する
  - `FetchRouteInfoUsecase`、`RouteInfoService`、`GoogleRoutesApiRouteInfoService`、関連factory/config/providerを削除する
  - Routes API呼び出し、Routes API用テスト、経路検索用DTO・画面テストを整理する
  - 旅行の訪問場所・タスク管理は維持し、経路検索廃止後も既存の旅行編集フローが成立するようにする
  - 仕様書・done/todo内の経路検索に関する記述を廃止方針に合わせて整理する

## 地図画面

- Places API呼び出しを`googleapis`の`places_v1`経由に移行し、URL直接呼び出しを廃止する
  - `googleapis`を依存関係に追加し、最新の利用方法を確認してから実装する
  - 地名検索はPlaces API NewのText Searchへ寄せ、`PlacesApi.places.searchText`から`LocationCandidateDto`へ変換する
  - ピン位置からの場所名取得は`PlacesApi.places.searchNearby`へ寄せ、`NearbyLocationService`の外部契約を維持する
  - `http`による`maps.googleapis.com`・`places.googleapis.com`へのPlaces API直接呼び出しを削除する
  - FieldMask、言語指定、空結果、エラー時の扱いを既存仕様に合わせてテストで確認する

## マップピンボトムシート


## 招待機能

- 招待コードで紐づけたmemberを更新した後、使用済み招待コードのレコードは削除する
- 作成から24時間経過した招待コードは無効とする

## グループイベント

## メンバーイベント

- グループイベントと同等の仕様で、年表のメンバー行セルからメンバーイベントを表示・編集できるようにする
  - リポジトリ関連は既存の`member_events`を使用し、データは`memberId`・`year`・`memo`で扱う
  - 選択中グループに所属するメンバー行の対象年セルに、同じ`memberId`・`year`のメモを表示する
  - 年齢・学年・厄年などの固定表示がある場合は、その下にメンバーイベントのメモを表示する
  - メンバー行の年セルをタップすると、対象メンバー・対象年のメモ編集ダイアログを開く
  - 保存・削除後は年表セルを再表示し、失敗時はSnackBarで保存失敗を通知する
  - Presentation層から`domain/*`や`infrastructure/*`を直接参照せず、Application層のユースケース経由で実装する

## DVCポイント計算画面

## デザイン

## 全体

## リファクタリング

## 不具合修正
