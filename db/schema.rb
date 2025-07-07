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

ActiveRecord::Schema[8.0].define(version: 2024_08_17_171455) do
  create_table "api_tokens", force: :cascade do |t|
    t.string "token"
    t.integer "user_id", null: false
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_api_tokens_on_token"
    t.index ["user_id"], name: "index_api_tokens_on_user_id"
  end

  create_table "dns_records", force: :cascade do |t|
    t.string "record_type"
    t.string "name"
    t.string "data"
    t.integer "ttl"
    t.integer "dns_zone_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dns_zone_id"], name: "index_dns_records_on_dns_zone_id"
  end

  create_table "dns_zones", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "redis_host"
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "name"
    t.string "alias_name"
    t.string "email"
    t.string "profile_photopath"
    t.string "auth_provider"
    t.boolean "admin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uid"
  end

  add_foreign_key "api_tokens", "users"
  add_foreign_key "dns_records", "dns_zones"
end
