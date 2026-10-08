# ER図

```mermaid
erDiagram
    trip_entries {
        string id PK
        string groupId FK "NOT NULL"
        string name
        number year "NOT NULL"
        timestamp startDate
        timestamp endDate
        string memo
    }
    locations {
        string id PK
        string tripId FK
        string groupId FK
        string name
        number latitude "NOT NULL"
        number longitude "NOT NULL"
    }
    tasks {
        string id PK
        string tripId FK "NOT NULL"
        number orderIndex "NOT NULL"
        string parentTaskId FK
        string name "NOT NULL"
        boolean isCompleted "NOT NULL"
        timestamp dueDate
        string memo
        string assignedMemberId FK
    }
    itinerary_items {
        string id PK
        string tripId FK "NOT NULL"
        string name "NOT NULL"
        timestamp startDateTime
        timestamp endDateTime
        string memo
        string locationId FK
    }
    groups {
        string id PK
        string ownerId FK "NOT NULL"
        string name "NOT NULL"
        string memo
    }
    group_members {
        string id PK
        string groupId FK "NOT NULL"
        string memberId FK "NOT NULL"
        boolean isAdministrator "NOT NULL"
        number orderIndex "NOT NULL"
    }
    group_events {
        string id PK
        string groupId FK "NOT NULL"
        number year "NOT NULL"
        string memo "NOT NULL"
    }
    members {
        string id PK
        string accountId
        string ownerId FK
        string hiraganaFirstName
        string hiraganaLastName
        string kanjiFirstName
        string kanjiLastName
        string firstName
        string lastName
        string displayName "NOT NULL"
        string type
        timestamp birthday
        string gender
        string email
        string phoneNumber
    }
    member_events {
        string id PK
        string memberId FK "NOT NULL"
        number year "NOT NULL"
        string memo "NOT NULL"
    }
    member_invitations {
        string id PK
        string inviteeId FK "NOT NULL"
        string inviterId FK "NOT NULL"
        string invitationCode "NOT NULL"
    }
    dvc_point_contracts {
        string id PK
        string groupId FK "NOT NULL"
        string contractName "NOT NULL"
        timestamp contractStartYearMonth "NOT NULL"
        timestamp contractEndYearMonth "NOT NULL"
        number useYearStartMonth "NOT NULL"
        number annualPoint "NOT NULL"
    }
    dvc_limited_points {
        string id PK
        string groupId FK "NOT NULL"
        timestamp startYearMonth "NOT NULL"
        timestamp endYearMonth "NOT NULL"
        number point "NOT NULL"
        string memo
    }
    dvc_point_usages {
        string id PK
        string groupId FK "NOT NULL"
        timestamp usageYearMonth "NOT NULL"
        number usedPoint "NOT NULL"
        string memo
    }
    calendar_events {
        string id PK
        string groupId FK "NOT NULL"
        string labelId FK "NOT NULL"
        string title "NOT NULL"
        timestamp startDateTime "NOT NULL"
        timestamp endDateTime "NOT NULL"
        boolean isAllDay "NOT NULL"
        string recurrenceRule
        string timeZone
    }
    calendar_event_overrides {
        string id PK
        string eventId FK "NOT NULL"
        timestamp originalStartDateTime "NOT NULL"
        boolean isCancelled "NOT NULL"
        string title
        timestamp startDateTime
        timestamp endDateTime
        boolean isAllDay
        string labelId FK
    }
    calendar_labels {
        string id PK
        string groupId FK "NOT NULL"
        string name "NOT NULL"
        string color "NOT NULL、#RRGGBB"
        string textColor "NOT NULL、#RRGGBB"
        integer sortOrder "NOT NULL、0以上"
    }
    google_calendar_connections {
        string memberId PK, FK
        string googleAccountId "NOT NULL"
    }
    google_calendar_selections {
        string memberId PK, FK
        string calendarId PK
    }

    trip_entries ||--o{ locations : "id → tripId"
    trip_entries ||--o{ tasks : "id → tripId"
    trip_entries ||--o{ itinerary_items : "id → tripId"
    tasks ||--o{ tasks : "id → parentTaskId"
    tasks ||--|| members : "assignedMemberId → id"
    locations |o--o{ itinerary_items : "id → locationId"
    groups ||--o{ group_members : "id → groupId"
    groups ||--o{ group_events : "id → groupId"
    groups ||--o{ trip_entries : "id → groupId"
    groups ||--o{ locations : "id → groupId"
    group_members ||--|| members : "memberId → id"
    members ||--o{ member_events : "id → memberId"
    members ||--o{ members : "id → ownerId"
    members ||--o{ groups : "id → ownerId"
    members ||--o{ member_invitations : "id → inviteeId"
    members ||--o{ member_invitations : "id → inviterId"
    groups ||--o{ dvc_point_contracts : "id → groupId"
    groups ||--o{ dvc_limited_points : "id → groupId"
    groups ||--o{ dvc_point_usages : "id → groupId"
    groups ||--o{ calendar_events : "id → groupId"
    groups ||--o{ calendar_labels : "id → groupId"
    calendar_labels ||--o{ calendar_events : "id → labelId"
    calendar_events ||--o{ calendar_event_overrides : "id → eventId"
    calendar_labels |o--o{ calendar_event_overrides : "id → labelId"
    members ||--o| google_calendar_connections : "id → memberId"
    google_calendar_connections ||--o{ google_calendar_selections : "memberId → memberId"
    externally_managed_accounts ||--|| members : "id → accountId"
```

## 図の補足

- 図は共通の業務モデルを示す。SQLiteの物理定義・制約・インデックスは[`offline_schema.drift`](../lib/infrastructure/database/offline_schema.drift)を参照。
- 繰り返し予定は`calendar_events`の`recurrenceRule`（RRULE形式）で表し、各回は保存しない。`calendar_event_overrides`は個別回の変更・取消しを表し、`eventId`と`originalStartDateTime`で対象の回を識別する。取消しの場合、変更内容の各フィールドは空になる。
- Firestoreでは個別回の変更・取消しを独立した`calendar_event_overrides`コレクションへ保存する。`eventId`・`groupId`・`originalStartDateTime`・`isCancelled`と変更内容を持ち、ドキュメントIDは親予定IDと正規化した元の開始日時（マイクロ秒）の組で一意にする。終日の元日時・変更後の期間はUTCの年月日として保存する。
- Firestoreの親予定は`overrideIds`（個別回のドキュメントID一覧）と`referencedLabelIds`（親と個別回が参照する色ラベルID一覧）を持つ。系列の分割・変更・削除は、親予定・対象の個別回・色ラベルの参照数を同じトランザクションで保存し、競合照合では個別回もトランザクション内で読み取る。グループ削除も予定ごとの削除処理を経由して個別回を削除する。一覧取得では候補の親IDをグループで絞り、予定ごとの読取トランザクションで親と個別回を取得する。取得中に削除された親は一覧から除外する。
- 既存のFirestoreの埋め込み形式（`overrides`・`cancelledOccurrences`）は`overrideIds`を持たない親予定から読み取る。次回の系列更新・分割時に個別回を独立コレクションへ移し、親の埋め込みフィールドを同じトランザクションで削除する。
