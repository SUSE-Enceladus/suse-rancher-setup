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

ActiveRecord::Schema[7.0].define(version: 2023_02_07_192140) do
  create_table "key_values", force: :cascade do |t|
    t.string "key", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_key_values_on_key", unique: true
  end

  create_table "pre_flight_checks", force: :cascade do |t|
    t.string "name"
    t.boolean "passed"
    t.string "job"
    t.datetime "job_submitted_at"
    t.datetime "job_completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "view_data"
  end

  create_table "resources", id: :string, force: :cascade do |t|
    t.string "type"
    t.text "creation_attributes"
    t.text "framework_raw_response"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "steps", force: :cascade do |t|
    t.integer "rank"
    t.string "action"
    t.string "resource_id"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "duration", default: 1
    t.boolean "cleanup_resource", default: true
    t.index ["rank"], name: "index_steps_on_rank", unique: true
  end

end
