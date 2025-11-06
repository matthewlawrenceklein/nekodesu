# Database Schema

## Overview

The Nekodesu database schema is designed to sync and store WaniKani study materials and subject data for generating personalized Japanese learning dialogues.

## Tables

### users
Stores user accounts and API credentials.

| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| email | string | User email (unique, required) |
| wanikani_api_key | string | WaniKani API token |
| last_wanikani_sync | datetime | Last successful sync timestamp |
| created_at | datetime | Record creation timestamp |
| updated_at | datetime | Record update timestamp |

**Indexes:**
- `index_users_on_email` (unique)

---

### wani_subjects
Stores WaniKani subject data (radicals, kanji, vocabulary, kana_vocabulary).

| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| user_id | bigint | Foreign key to users |
| external_id | integer | WaniKani subject ID |
| subject_type | string | Type: radical, kanji, vocabulary, kana_vocabulary |
| characters | string | UTF-8 characters (kanji/kana) |
| slug | string | URL-friendly identifier |
| level | integer | WaniKani level (1-60) |
| lesson_position | integer | Position in lessons |
| meaning_mnemonic | text | Mnemonic for meaning |
| reading_mnemonic | text | Mnemonic for reading |
| document_url | string | WaniKani documentation URL |
| meanings | jsonb | Array of meaning objects |
| auxiliary_meanings | jsonb | Array of auxiliary meaning objects |
| readings | jsonb | Array of reading objects |
| component_subject_ids | jsonb | Array of component subject IDs |
| hidden_at | datetime | When subject was hidden |
| created_at_wanikani | datetime | Creation time on WaniKani |
| created_at | datetime | Record creation timestamp |
| updated_at | datetime | Record update timestamp |

**Indexes:**
- `index_wani_subjects_on_user_id_and_external_id` (unique)
- `index_wani_subjects_on_subject_type`
- `index_wani_subjects_on_level`

**JSONB Structure Examples:**

```ruby
# meanings
[
  { "meaning" => "One", "primary" => true, "accepted_answer" => true },
  { "meaning" => "Single", "primary" => false, "accepted_answer" => true }
]

# readings
[
  { "reading" => "いち", "primary" => true, "accepted_answer" => true, "type" => "onyomi" },
  { "reading" => "ひと", "primary" => false, "accepted_answer" => false, "type" => "kunyomi" }
]

# auxiliary_meanings
[
  { "meaning" => "one", "type" => "blacklist" },
  { "meaning" => "flat", "type" => "whitelist" }
]
```

---

### wani_study_materials
Stores user-specific study materials (notes and synonyms) from WaniKani.

| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| user_id | bigint | Foreign key to users |
| wani_subject_id | bigint | Foreign key to wani_subjects |
| external_id | integer | WaniKani study material ID |
| subject_id | integer | WaniKani subject ID reference |
| subject_type | string | Type of subject |
| meaning_note | text | User's custom meaning note |
| reading_note | text | User's custom reading note |
| meaning_synonyms | jsonb | Array of user-added synonyms |
| hidden | boolean | Whether study material is hidden |
| created_at_wanikani | datetime | Creation time on WaniKani |
| created_at | datetime | Record creation timestamp |
| updated_at | datetime | Record update timestamp |

**Indexes:**
- `index_wani_study_materials_on_user_id_and_external_id` (unique)
- `index_wani_study_materials_on_subject_id`

**JSONB Structure Example:**

```ruby
# meaning_synonyms
["burn", "sizzle", "flame"]
```

---

## Relationships

```
User
├── has_many :wani_subjects
└── has_many :wani_study_materials

WaniSubject
├── belongs_to :user
└── has_many :wani_study_materials

WaniStudyMaterial
├── belongs_to :user
└── belongs_to :wani_subject
```

---

## Future Tables

The following tables will be added in subsequent migrations:

- **dialogues** - AI-generated learning content
- **comprehension_questions** - Multiple choice questions for dialogues
- **user_responses** - User answers and learning progress tracking
