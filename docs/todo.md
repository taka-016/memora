# ToDo List

## DB設計・リポジトリ・ユースケース・DTO・マッパー関連

- ER図のユーザーイベント設計（`member_events` / メンバー別イベント）に合わせて、永続化契約を `memberId` / `year` / `memo` ベースへ統一し、`id` は Firestore のドキュメントIDとして扱う
  - `MemberEvent` / `MemberEventDto` / `MemberEventMapper` / `FirestoreMemberEventMapper` から旧設計の `type` / `name` / `startDate` / `endDate` を除去し、ER図どおりの項目だけを扱うようにする。また、業務上の一意性は `memberId` + `year` で担保する前提で責務を整理する
  - `MemberEventRepository` / `FirestoreMemberEventRepository` の保存処理を年表セル前提に見直し、同一 `memberId`・同一年の既存レコードがあれば更新、メモが空なら削除、存在しなければ新規作成に整理する
  - ユーザーイベント（`member_events` / メンバー別イベント）用のクエリ処理をER図準拠で見直し、年表表示に必要な単位で取得できる `QueryService` / Firestore実装 / factory配線を追加または改修する
  - ユーザーイベント（`member_events` / メンバー別イベント）の取得・保存ユースケースを、上記のリポジトリ契約とクエリ契約に合わせて整理し、Presentation層へ旧フィールド前提を漏らさない構成にする

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

## 不具合修正
