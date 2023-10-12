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

ActiveRecord::Schema.define(version: 2023_09_27_072418) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "emerchantpay_payments", force: :cascade do |t|
    t.string "transaction_id", null: false
    t.string "unique_id", limit: 512
    t.string "reference_id", limit: 512
    t.string "payment_method", limit: 128, null: false
    t.string "terminal_token", null: false
    t.string "status", limit: 64
    t.string "order_id", limit: 128
    t.string "payment_id", limit: 128
    t.string "transaction_type"
    t.integer "amount", null: false
    t.string "currency", null: false
    t.string "mode", null: false
    t.string "message", limit: 512
    t.string "technical_message", limit: 2048
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.json "request"
    t.json "response"
    t.index ["order_id", "payment_id"], name: "idx_order_payment_id"
    t.index ["transaction_id", "transaction_type"], name: "idx_unique_transaction_type", unique: true
    t.index ["unique_id"], name: "idx_unique_id"
  end

end
