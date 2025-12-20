# ER図

```mermaid
erDiagram
    trip_entries {
        string id PK
        string groupId FK "NOT NULL"
        string tripName
        number tripYear "NOT NULL"
        timestamp tripStartDate
        timestamp tripEndDate
        string tripMemo
    }
    pins {
        string id PK
        string pinId UK "NOT NULL"
        string tripId FK
        string groupId FK
        number latitude "NOT NULL"
        number longitude "NOT NULL"
        string locationName
        timestamp visitStartDate
        timestamp visitEndDate
        string visitMemo
    }
    routes {
        string id PK
        string tripId FK "NOT NULL"
        number orderIndex "NOT NULL"
        string departurePinId FK "NOT NULL"
        string arrivalPinId FK "NOT NULL"
        string travelMode "NOT NULL"
        number distanceMeters
        number durationSeconds
        string instructions
        string polyline
    }
    pin_details {
        string id PK
        string pinId FK "NOT NULL"
        string name
        timestamp startDate
        timestamp endDate
        string memo
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
    }
    group_events {
        string id PK
        string groupId FK "NOT NULL"
        string type "NOT NULL"
        string name
        timestamp startDate "NOT NULL"
        timestamp endDate "NOT NULL"
        string memo
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
        string passportNumber
        string passportExpiration
    }
    member_events {
        string id PK
        string memberId FK "NOT NULL"
        string type "NOT NULL"
        string name
        timestamp startDate "NOT NULL"
        timestamp endDate "NOT NULL"
        string memo
    }
    member_invitations {
        string id PK
        string inviteeId FK "NOT NULL"
        string inviterId FK "NOT NULL"
        string invitationCode "NOT NULL"
    }

    trip_entries ||--o{ pins : "id → tripId"
    trip_entries ||--o{ routes : "id → tripId"
    pins ||--o{ pin_details : "pinId → pinId"
    pins ||--o{ routes : "id → departurePinId"
    pins ||--o{ routes : "id → arrivalPinId"
    groups ||--o{ group_members : "id → groupId"
    groups ||--o{ group_events : "id → groupId"
    groups ||--o{ trip_entries : "id → groupId"
    groups ||--o{ pins : "id → groupId"
    group_members ||--|| members : "memberId → id"
    members ||--o{ member_events : "id → memberId"
    members ||--o{ members : "id → ownerId"
    members ||--o{ groups : "id → ownerId"
    members ||--o{ member_invitations : "id → inviteeId"
    members ||--o{ member_invitations : "id → inviterId"
    externally_managed_accounts ||--|| members : "id → accountId"
```

- `trip_entries.tripStartDate`と`trip_entries.tripEndDate`は任意項目であり、年での集計や関連付けは`tripYear`を基準に行う。
