# ER図

```mermaid
erDiagram
    trip_entries {
        string id PK
        string groupId FK "NOT NULL"
        string tripName
        timestamp tripStartDate "NOT NULL"
        timestamp tripEndDate "NOT NULL"
        string tripMemo
    }
    trip_participants {
        string id PK
        string tripId FK "NOT NULL"
        string memberId FK "NOT NULL"
    }
    pins {
        string id PK
        string pinId "NOT NULL"
        string tripId FK
        string groupId FK
        number latitude "NOT NULL"
        number longitude "NOT NULL"
        string locationName
        timestamp visitStartDate
        timestamp visitEndDate
        string visitMemo
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
        string invitationKey "NOT NULL"
    }

    trip_entries ||--o{ trip_participants : "id → tripId"
    trip_participants ||--|| members : "memberId → id"
    members ||--o{ member_events : "id → memberId"
    trip_entries ||--o{ pins : "id → tripId"
    groups ||--o{ group_members : "id → groupId"
    group_members ||--|| members : "memberId → id"
    groups ||--o{ group_events : "id → groupId"
    groups ||--o{ trip_entries : "id → groupId"
    groups ||--o{ pins : "id → groupId"
    externally_managed_accounts ||--|| members : "id → accountId"
    members ||--o{ members : "id → ownerId"
    members ||--o{ groups : "id → ownerId"
    members ||--o{ member_invitations : "id → inviteeId"
    members ||--o{ member_invitations : "id → inviterId"
```
