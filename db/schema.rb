# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2024_11_06_024702) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "last_wanikani_sync"
    t.datetime "updated_at", null: false
    t.string "wanikani_api_key"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "wani_study_materials", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "created_at_wanikani"
    t.integer "external_id", null: false
    t.boolean "hidden", default: false
    t.text "meaning_note"
    t.jsonb "meaning_synonyms", default: []
    t.text "reading_note"
    t.integer "subject_id", null: false
    t.string "subject_type", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "wani_subject_id", null: false
    t.index ["subject_id"], name: "index_wani_study_materials_on_subject_id"
    t.index ["user_id", "external_id"], name: "index_wani_study_materials_on_user_id_and_external_id", unique: true
    t.index ["user_id"], name: "index_wani_study_materials_on_user_id"
    t.index ["wani_subject_id"], name: "index_wani_study_materials_on_wani_subject_id"
  end

  create_table "wani_subjects", force: :cascade do |t|
    t.jsonb "auxiliary_meanings", default: []
    t.string "characters"
    t.jsonb "component_subject_ids", default: []
    t.datetime "created_at", null: false
    t.datetime "created_at_wanikani"
    t.string "document_url"
    t.integer "external_id", null: false
    t.datetime "hidden_at"
    t.integer "lesson_position"
    t.integer "level"
    t.text "meaning_mnemonic"
    t.jsonb "meanings", default: []
    t.text "reading_mnemonic"
    t.jsonb "readings", default: []
    t.string "slug"
    t.string "subject_type", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["level"], name: "index_wani_subjects_on_level"
    t.index ["subject_type"], name: "index_wani_subjects_on_subject_type"
    t.index ["user_id", "external_id"], name: "index_wani_subjects_on_user_id_and_external_id", unique: true
    t.index ["user_id"], name: "index_wani_subjects_on_user_id"
  end

  add_foreign_key "wani_study_materials", "users"
  add_foreign_key "wani_study_materials", "wani_subjects"
  add_foreign_key "wani_subjects", "users"
end
