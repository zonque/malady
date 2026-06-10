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

ActiveRecord::Schema[8.1].define(version: 2026_06_10_223600) do
  create_table "data_points", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "metric_id", null: false
    t.text "note"
    t.datetime "recorded_at"
    t.datetime "updated_at", null: false
    t.boolean "value_boolean"
    t.decimal "value_decimal", precision: 20, scale: 6
    t.text "value_text"
    t.index ["metric_id", "recorded_at"], name: "index_data_points_on_metric_id_and_recorded_at"
    t.index ["metric_id"], name: "index_data_points_on_metric_id"
  end

  create_table "metrics", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "color"
    t.datetime "created_at", null: false
    t.string "data_type"
    t.text "description"
    t.text "enum_options", default: "[]", null: false
    t.boolean "ignore_time", default: false, null: false
    t.string "name"
    t.integer "position", default: 0, null: false
    t.string "slug"
    t.string "unit"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "position"], name: "index_metrics_on_user_id_and_position"
    t.index ["user_id", "slug"], name: "index_metrics_on_user_id_and_slug", unique: true
    t.index ["user_id"], name: "index_metrics_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.string "api_token", null: false
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.string "locale", default: "en", null: false
    t.datetime "locked_at"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "time_zone", default: "UTC", null: false
    t.string "unconfirmed_email"
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.index ["api_token"], name: "index_users_on_api_token", unique: true
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "data_points", "metrics"
  add_foreign_key "metrics", "users"
end
