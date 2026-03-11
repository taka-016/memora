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


## 地図画面


## マップピンボトムシート


## 招待機能

- 招待コードで紐づけたmemberを更新した後、使用済み招待コードのレコードは削除する
- 作成から24時間経過した招待コードは無効とする

## グループイベント

- グループ年表のグループイベント行にgroup_eventsのデータを表示する
- 年表セルのタップでフリー入力メモのダイアログを開き、グループイベントを編集できるようにする
- グループイベントの仕様に合わせて設計および実装を更新する
  - ER図のgroup_events定義をフリー入力のみとする仕様に合わせて見直す
  - ER図の修正に合わせてエンティティやリポジトリ等を改修する

## DVCポイント計算画面

## デザイン


## 全体


## リファクタリング

- `lib/presentation/features/trip/select_visit_location_view.dart:3` で `domain/value_objects/location.dart` を直接参照している
  - 緯度・経度などプリミティブで受け渡し、locationの生成・検証はユースケースで行う
- `lib/presentation/features/trip/trip_edit_modal.dart:9` で `domain/exceptions/validation_exception.dart` を直接参照している
  - 検証失敗はアプリケーション層のエラー型へ変換して扱い、画面でdomain例外を直接扱わない
- `lib/presentation/features/trip/trip_edit_modal.dart:10` で `domain/value_objects/location.dart` を直接参照している
  - 緯度・経度などプリミティブで受け渡し、locationの生成・検証はユースケースで行う
- `lib/presentation/features/trip/trip_management.dart:13` で `application/queries/order_by.dart` を直接参照している
  - 並び順指定はユースケース入力の列挙・フラグで表現し、プレゼンテーション層でクエリオブジェクトを組み立てない
- `lib/presentation/notifiers/auth_notifier.dart:5` で `application/services/auth_service.dart` を直接参照している
  - 認証状態判定と認証操作はユースケース経由に統一し、プレゼンテーション層で認証サービスを直接扱わない
- `lib/presentation/notifiers/auth_notifier.dart:6` で `infrastructure/factories/auth_service_factory.dart` を直接参照している
  - Factory直接参照を削除し、認証ユースケース経由の呼び出しに統一する
- `lib/presentation/notifiers/location_notifier.dart:2` で `domain/value_objects/location.dart` を直接参照している
  - 緯度・経度などプリミティブで受け渡し、locationの生成・検証はユースケースで行う
- `lib/presentation/notifiers/location_state.dart:2` で `domain/value_objects/location.dart` を直接参照している
  - 位置状態はプレゼン用state（プリミティブ中心）へ置換し、domainの値オブジェクト参照を排除する
- `lib/presentation/notifiers/location_notifier.dart:4` で `domain/services/current_location_service.dart` を直接参照している
  - 現在地取得はユースケース経由に統一し、domainサービスを画面から直接参照しない
- `lib/presentation/notifiers/location_notifier.dart:5` で `infrastructure/services/geolocator_current_location_service.dart` を直接参照している
  - インフラサービス直接参照を削除し、現在地ユースケース経由の呼び出しに統一する
- `lib/presentation/shared/inputs/custom_search_bar.dart:3` で `application/services/location_search_service.dart` を直接参照している
  - 場所検索はユースケース経由に統一し、プレゼンテーション層からサービス依存を外す
- `lib/presentation/shared/map_views/google_map_view_builder.dart:4` で `domain/value_objects/location.dart` を直接参照している
  - 緯度・経度などプリミティブで受け渡し、locationの生成・検証はユースケースで行う
- `lib/presentation/shared/map_views/google_map_view.dart:5` で `domain/value_objects/location.dart` を直接参照している
  - 緯度・経度などプリミティブで受け渡し、locationの生成・検証はユースケースで行う
- `lib/presentation/shared/map_views/google_map_view.dart:10` で `infrastructure/services/google_places_api_location_search_service.dart` を直接参照している
  - インフラサービス直接参照を削除し、場所検索ユースケース経由の呼び出しに統一する
- `lib/presentation/shared/map_views/map_view_builder.dart:3` で `domain/value_objects/location.dart` を直接参照している
  - 緯度・経度などプリミティブで受け渡し、locationの生成・検証はユースケースで行う
- `lib/presentation/shared/map_views/placeholder_map_view_builder.dart:4` で `domain/value_objects/location.dart` を直接参照している
  - 緯度・経度などプリミティブで受け渡し、locationの生成・検証はユースケースで行う
- `lib/presentation/shared/sheets/pin_detail_bottom_sheet.dart:4` で `domain/services/nearby_location_service.dart` を直接参照している
  - 周辺検索はユースケース経由に統一し、domainサービスを画面から直接参照しない
- `lib/presentation/shared/sheets/pin_detail_bottom_sheet.dart:5` で `infrastructure/services/google_places_api_nearby_location_service.dart` を直接参照している
  - インフラサービス直接参照を削除し、周辺検索ユースケース経由の呼び出しに統一する

## 不具合修正
