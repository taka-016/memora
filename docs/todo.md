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

- [ ] `lib/presentation/app/top_page.dart` は `domain/value_objects/auth_state.dart` を直接参照している
  - [ ] 認証状態を `application/dtos` の表示用DTOへ置き換える
  - [ ] 画面は認証ユースケース経由の状態のみを参照する
- [ ] `lib/presentation/features/auth/auth_guard.dart` は `domain/value_objects/auth_state.dart` と `infrastructure/factories/auth_service_factory.dart` を直接参照している
  - [ ] `application/usecases` に認証状態取得・監視ユースケースを追加する
  - [ ] AuthGuardからFactory依存を削除しユースケース経由に統一する
- [ ] `lib/presentation/features/auth/login_page.dart` は `domain/value_objects/auth_state.dart` を直接参照している
  - [ ] ログイン画面の状態分岐を認証状態DTOで扱う
- [ ] `lib/presentation/features/auth/signup_page.dart` は `domain/value_objects/auth_state.dart` を直接参照している
  - [ ] サインアップ画面の状態判定を認証状態DTO経由に変更する
- [ ] `lib/presentation/features/group/group_edit_modal.dart` は `domain/entities/group/group.dart` を直接参照している
  - [ ] 画面入出力を `application/dtos/group/group_dto.dart` に統一する
  - [ ] ドメインエンティティへの変換責務をユースケース側へ移動する
- [ ] `lib/presentation/features/member/member_edit_modal.dart` は `domain/entities/member/member.dart` を直接参照している
  - [ ] 画面入出力を `application/dtos/member/member_dto.dart` に統一する
- [ ] `lib/presentation/features/trip/route_info_view.dart` は `domain/value_objects/route_segment_detail.dart` を直接参照している
  - [ ] 経路表示用DTOを `application/dtos` に追加する
  - [ ] 表示データをユースケースからDTOで受け取る構成へ変更する
- [ ] `lib/presentation/features/trip/route_memo_edit_bottom_sheet.dart` は `domain/value_objects/route_segment_detail.dart` を直接参照している
  - [ ] ボトムシートの入力モデルを経路表示DTOに置き換える
- [ ] `lib/presentation/features/trip/select_visit_location_view.dart` は `domain/value_objects/location.dart` を直接参照している
  - [ ] 位置候補の受け渡しを位置DTOに置き換える
- [ ] `lib/presentation/features/trip/trip_edit_modal.dart` は `domain/entities/trip/trip_entry.dart` `domain/exceptions/validation_exception.dart` `domain/value_objects/location.dart` を直接参照している
  - [ ] 編集対象データをTrip系DTOに置き換える
  - [ ] 入力検証エラーはアプリケーション層の戻り値で扱う
  - [ ] 画面でのドメイン例外の直接ハンドリングを廃止する
- [ ] `lib/presentation/features/trip/trip_management.dart` は `domain/entities/trip/trip_entry.dart` と `domain/value_objects/order_by.dart` を直接参照している
  - [ ] 一覧表示データを `application/dtos/trip` へ置き換える
  - [ ] 並び順指定をユースケースAPIで抽象化する
- [ ] `lib/presentation/notifiers/auth_notifier.dart` は `domain/value_objects/auth_state.dart` `domain/entities/account/user.dart` `infrastructure/factories/auth_service_factory.dart` を直接参照している
  - [ ] 認証Notifierの入出力を認証DTOへ統一する
  - [ ] Factory生成責務をアプリケーション層へ移譲する
- [ ] `lib/presentation/notifiers/current_member_notifier.dart` は `domain/value_objects/auth_state.dart` を直接参照している
  - [ ] 認証状態連携を認証状態DTO経由に変更する
- [ ] `lib/presentation/notifiers/location_notifier.dart` は `domain/value_objects/location.dart` `domain/value_objects/location_state.dart` `domain/services/current_location_service.dart` `infrastructure/services/geolocator_current_location_service.dart` を直接参照している
  - [ ] 現在地取得を `application/usecases` に委譲する
  - [ ] Notifierが扱う状態を位置DTOと画面状態DTOに限定する
- [ ] `lib/presentation/shared/inputs/custom_search_bar.dart` は `domain/services/location_search_service.dart` と `domain/value_objects/location_candidate.dart` を直接参照している
  - [ ] 場所検索ユースケースを介して検索を実行する
  - [ ] 候補データを検索結果DTOで受け取る
- [ ] `lib/presentation/shared/map_views/google_map_view_builder.dart` は `domain/value_objects/location.dart` を直接参照している
  - [ ] ビュー生成引数を位置DTOへ置き換える
- [ ] `lib/presentation/shared/map_views/google_map_view.dart` は `domain/value_objects/location.dart` と `infrastructure/services/google_places_api_location_search_service.dart` を直接参照している
  - [ ] マップ表示の入出力を位置DTOへ統一する
  - [ ] 検索処理を場所検索ユースケース経由に変更する
- [ ] `lib/presentation/shared/map_views/map_view_builder.dart` は `domain/value_objects/location.dart` を直接参照している
  - [ ] 抽象インターフェースの型を位置DTOへ置換する
- [ ] `lib/presentation/shared/map_views/placeholder_map_view_builder.dart` は `domain/value_objects/location.dart` を直接参照している
  - [ ] プレースホルダービューの引数型を位置DTOへ置換する
- [ ] `lib/presentation/shared/sheets/pin_detail_bottom_sheet.dart` は `domain/services/nearby_location_service.dart` `domain/value_objects/location.dart` `infrastructure/services/google_places_api_nearby_location_service.dart` を直接参照している
  - [ ] 周辺検索処理をユースケース化して画面から分離する
  - [ ] ボトムシートが扱うデータを周辺候補DTOへ置き換える

## 不具合修正
