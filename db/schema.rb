# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20151112141206) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "configs", force: :cascade do |t|
    t.integer  "tracker_project_id"
    t.string   "jira_login"
    t.string   "jira_host"
    t.string   "jira_uri_scheme"
    t.string   "jira_project"
    t.integer  "jira_port"
    t.integer  "jira_filter"
    t.integer  "script_first_start"
    t.string   "script_repeat_time"
    t.integer  "project_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.string   "name"
    t.integer  "retry_count"
    t.string   "jira_password"
    t.string   "tracker_token"
  end

  create_table "jira_accounts", force: :cascade do |t|
    t.string   "password"
    t.integer  "jira_filter"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "name"
  end

  create_table "jira_custom_fields", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "value"
    t.integer  "project_id"
  end

  create_table "jira_issue_types", force: :cascade do |t|
    t.string   "name"
    t.integer  "jira_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "project_id"
  end

  create_table "logs", force: :cascade do |t|
    t.string "name"
  end

  create_table "pivotal_accounts", force: :cascade do |t|
    t.string   "name"
    t.string   "tracker_token"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "pivotal_accounts", ["tracker_token"], name: "index_pivotal_accounts_on_tracker_token", unique: true, using: :btree

  create_table "projects", force: :cascade do |t|
    t.string   "name"
    t.integer  "pid"
    t.boolean  "online",                       default: false
    t.datetime "last_update"
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
    t.boolean  "active",                       default: false
    t.string   "last_synchronization_status"
    t.string   "last_synchronization_message"
    t.string   "current_job_id"
    t.integer  "pivotal_account_id"
    t.integer  "jira_account_id"
    t.string   "jira_project"
    t.integer  "tracker_project_id"
  end

end
