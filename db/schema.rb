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

ActiveRecord::Schema[7.2].define(version: 2025_04_07_110834) do
  create_table "addresses", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "table_name", limit: 40, null: false
    t.integer "table_id"
    t.string "active", limit: 10
    t.string "name", limit: 40
    t.string "company", limit: 40
    t.string "address1", limit: 100
    t.string "address2", limit: 100
    t.string "city", limit: 40
    t.string "state", limit: 2
    t.string "zipcode", limit: 10
    t.integer "country_id"
    t.string "phone", limit: 15
    t.float "latitude", limit: 53
    t.float "longitude", limit: 53
    t.string "mobile_phone", limit: 15
  end

  create_table "arrivy_task_customer_rating", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "order_id", null: false
    t.bigint "arrivy_task_id", null: false
    t.bigint "arrivy_customer_id"
    t.decimal "rating", precision: 4, scale: 2
    t.text "comments"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "attributes", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "attribute", limit: 30, null: false
    t.string "token", limit: 50
    t.string "attribute_type", limit: 30, null: false
    t.string "active", limit: 10, default: "Active", null: false
    t.index ["attribute_type"], name: "type"
    t.index ["token"], name: "token"
  end

  create_table "banner", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "path", limit: 30, null: false
    t.date "from_date", null: false
    t.date "to_date", null: false
  end

  create_table "barcodes", primary_key: "product_piece_id", id: :integer, default: nil, charset: "utf8mb3", force: :cascade do |t|
    t.integer "product_id"
    t.boolean "show_on_frontend", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "site_id", null: false, unsigned: true
    t.integer "bin_id", unsigned: true
    t.integer "last_order_id"
    t.index ["bin_id"], name: "index_barcodes_bin"
    t.index ["product_id"], name: "index_barcodes_product_id"
    t.index ["product_piece_id"], name: "index_barcodes_product_piece_id"
    t.index ["site_id"], name: "index_barcodes_site"
  end

  create_table "barcodes_back_20241010", id: false, charset: "latin1", force: :cascade do |t|
    t.integer "product_piece_id", null: false
    t.integer "product_id"
    t.boolean "show_on_frontend", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "site_id", null: false, unsigned: true
    t.integer "bin_id", unsigned: true
    t.integer "last_order_id"
  end

  create_table "benefits", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "sequence", null: false
    t.string "benefit", limit: 250, null: false
    t.text "benefit_description", null: false
  end

  create_table "carts", id: { type: :integer, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "address_id"
    t.integer "tax_authority_id"
    t.text "items"
    t.decimal "subtotal", precision: 10, scale: 2, default: "0.0"
    t.decimal "total", precision: 10, scale: 2, default: "0.0"
    t.text "checkout"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id", null: false, unsigned: true
  end

  create_table "catalog_fees", primary_key: ["id", "user_id"], charset: "utf8mb3", force: :cascade do |t|
    t.integer "id", null: false, unsigned: true, auto_increment: true
    t.integer "user_id", null: false, unsigned: true
    t.integer "site_id", null: false, unsigned: true
    t.float "amount", null: false, unsigned: true
    t.date "date", null: false
    t.text "products", null: false
  end

  create_table "categories", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "category", limit: 30, null: false
    t.string "token", limit: 50
    t.integer "type_id", null: false
    t.string "active", limit: 10, null: false
    t.index ["token"], name: "token"
  end

  create_table "category_counts", id: { type: :integer, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "count", default: 0
    t.datetime "updated_at", precision: nil
    t.integer "category_id", null: false, unsigned: true
    t.index ["category_id"], name: "index_category_counts_category"
  end

  create_table "charge_account_charges", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "charge_account_id", null: false
    t.string "type", limit: 20, null: false
    t.string "status", limit: 10, null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "table_name", limit: 50, null: false
    t.integer "table_id", null: false
    t.datetime "created", precision: nil, null: false
    t.string "created_by", limit: 40, null: false
    t.string "created_with", limit: 50, null: false
    t.datetime "edited", precision: nil, null: false
    t.string "edited_by", limit: 40, null: false
    t.string "edited_with", limit: 50, null: false
    t.index ["charge_account_id", "status"], name: "charge_account_id"
  end

  create_table "charge_accounts", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "account_number", limit: 20, null: false
    t.string "active", limit: 10, null: false
    t.datetime "created", precision: nil, null: false
    t.string "created_by", limit: 40, null: false
    t.string "created_with", limit: 50, null: false
    t.datetime "edited", precision: nil, null: false
    t.string "edited_by", limit: 40, null: false
    t.string "edited_with", limit: 50, null: false
    t.integer "original_id"
    t.index ["account_number"], name: "account_number", unique: true
    t.index ["user_id"], name: "user_id"
  end

  create_table "charge_accounts_restore", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "account_number", limit: 20, null: false
    t.string "active", limit: 10, null: false
    t.datetime "created", precision: nil, null: false
    t.string "created_by", limit: 40, null: false
    t.string "created_with", limit: 50, null: false
    t.datetime "edited", precision: nil, null: false
    t.string "edited_by", limit: 40, null: false
    t.string "edited_with", limit: 50, null: false
    t.integer "original_id"
    t.index ["account_number"], name: "account_number"
    t.index ["user_id"], name: "user_id"
  end

  create_table "cities", id: { type: :integer, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "states_id", null: false, unsigned: true
    t.string "name", limit: 64, null: false
    t.integer "tax_authority", null: false, unsigned: true
    t.integer "location_code", limit: 2, null: false, unsigned: true
    t.index ["location_code"], name: "location_code", unique: true
    t.index ["states_id"], name: "states_id"
  end

  create_table "cms", id: :integer, charset: "latin1", force: :cascade do |t|
    t.string "page"
    t.string "title"
    t.text "description"
    t.string "column_type"
    t.string "file_url", limit: 500
    t.timestamp "CREATED_AT", default: -> { "CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil
  end

  create_table "commission", id: { type: :integer, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "customer_id", null: false, unsigned: true
    t.integer "product_id", null: false, unsigned: true
    t.float "base_price", null: false, unsigned: true
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.integer "days", limit: 1, null: false, unsigned: true
    t.float "commission", null: false, unsigned: true
    t.integer "location_id", limit: 1, null: false, unsigned: true
    t.date "cycle", null: false
    t.integer "payment_id", null: false, unsigned: true
    t.column "type", "enum('RENT','SALE','IHS')", default: "RENT", null: false
    t.timestamp "timestamp", default: -> { "CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP" }, null: false
    t.index ["customer_id"], name: "customer_id"
    t.index ["type"], name: "type"
  end

  create_table "company", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "company", limit: 50, null: false
    t.string "email", limit: 50, null: false
    t.string "notification_email", limit: 100
    t.string "office", limit: 20, null: false
    t.string "fax", limit: 20, null: false
    t.integer "address_id", null: false
    t.integer "tax_authority_id", null: false
    t.integer "next_pick_order", null: false
    t.integer "next_purchase_order", null: false
    t.integer "next_transfer_order", null: false
    t.integer "next_production_order", null: false
    t.integer "next_adjustment_order", null: false
    t.integer "next_service_order", null: false
    t.integer "next_task_batch", null: false
    t.index ["address_id"], name: "address_id"
  end

  create_table "company_correspondence", id: :integer, charset: "latin1", force: :cascade do |t|
    t.integer "company_id"
    t.string "type", limit: 30
    t.string "action"
    t.text "html_markup"
    t.string "edited"
    t.string "edited_by", limit: 40
    t.datetime "created", precision: nil
    t.string "created_by", limit: 40
    t.timestamp "createdAt"
  end

  create_table "concierge_quotes", id: { type: :integer, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.string "slug", limit: 8, null: false
    t.integer "user_id"
    t.string "homeowner_name", limit: 50
    t.string "homeowner_email", limit: 50
    t.decimal "listing_price", precision: 10, scale: 3
    t.text "data"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.datetime "emailed_at", precision: nil
    t.string "homeowner_phone", limit: 50
    t.string "listing_address", limit: 200
    t.index ["slug"], name: "unique_concierge_quotes_slug", unique: true
    t.index ["user_id"], name: "index_concierge_quotes_user_id"
  end

  create_table "content_managements", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.text "text", size: :long, null: false
    t.string "identifier", limit: 50, null: false
    t.string "descriptor", limit: 50, null: false
  end

  create_table "countries", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "country", limit: 40, null: false
  end

  create_table "credit_cards", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "info_key", limit: 20, null: false
    t.string "customer_key", limit: 20
    t.string "type", limit: 20, null: false
    t.string "last_four", limit: 4, null: false
    t.string "month", limit: 2, null: false
    t.string "year", limit: 4, null: false
    t.datetime "created", precision: nil, null: false
    t.string "created_by", limit: 40, null: false
    t.string "created_with", limit: 50, null: false
    t.datetime "edited", precision: nil
    t.string "edited_by", limit: 40
    t.string "edited_with", limit: 50
    t.string "label", limit: 50
    t.boolean "visible", default: true
    t.integer "address_id"
    t.integer "ccv"
  end

  create_table "cycle_count_bins", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "cycle_counts_id", null: false
    t.integer "site_bins_id"
    t.date "scheduledAt", null: false
    t.timestamp "createdAt", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["cycle_counts_id", "site_bins_id"], name: "cycle_counts_id", unique: true
  end

  create_table "cycle_count_bins_product_pieces", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "cycle_count_bins_id", null: false
    t.integer "product_piece_id", null: false
    t.timestamp "createdAt", default: -> { "CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP" }, null: false
    t.index ["cycle_count_bins_id", "product_piece_id"], name: "cycle_count_bins_id_2", unique: true
    t.index ["cycle_count_bins_id"], name: "cycle_count_bins_id"
    t.index ["product_piece_id"], name: "product_piece_id"
  end

  create_table "cycle_count_bins_scan_product_pieces", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "cycle_count_bins_id", null: false
    t.integer "product_piece_id", null: false
    t.integer "user_id", null: false
    t.timestamp "createdAt", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["cycle_count_bins_id", "product_piece_id"], name: "cycle_count_bins_id_product_piece_id", unique: true
    t.index ["cycle_count_bins_id"], name: "cycle_count_bins_id"
    t.index ["product_piece_id"], name: "product_piece_id"
    t.index ["user_id"], name: "user_id"
  end

  create_table "cycle_counts", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "sites_id", null: false
    t.date "startAt", null: false
    t.date "endAt", null: false
    t.timestamp "createdAt", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["sites_id"], name: "sites_id"
  end

  create_table "deliveries", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "orders_id", null: false
    t.integer "trucks_id", null: false
    t.text "observation"
    t.integer "users_id", null: false
    t.datetime "due_at", precision: nil, null: false
    t.timestamp "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: nil
    t.index ["orders_id"], name: "orders_id"
    t.index ["trucks_id"], name: "trucks_id"
    t.index ["users_id"], name: "users_id"
  end

  create_table "deliveries_history", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "orders_id", null: false
    t.integer "trucks_id", null: false
    t.text "observation"
    t.integer "users_id", null: false
    t.datetime "due_at", precision: nil, null: false
    t.timestamp "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["orders_id"], name: "orders_id"
    t.index ["trucks_id"], name: "trucks_id"
    t.index ["users_id"], name: "users_id"
  end

  create_table "delivery_appointments", id: :integer, charset: "latin1", force: :cascade do |t|
    t.timestamp "created_at", default: -> { "CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP" }, null: false
    t.timestamp "updated_at", null: false
    t.integer "user_id", null: false
    t.text "special_instructions"
    t.string "schedule_date"
    t.boolean "status", default: false, null: false
    t.string "project_name"
    t.string "client_name"
    t.string "contact_info"
    t.string "delivery"
    t.string "approx_budget"
  end

  create_table "edit_log", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "table_name", limit: 40
    t.integer "table_id"
    t.string "type", limit: 40, null: false
    t.text "reference", null: false
    t.integer "user_id", null: false
    t.timestamp "date", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "php_class_name", limit: 40, null: false
    t.index ["reference"], name: "reference", length: 40
    t.index ["table_name", "type", "table_id"], name: "table_name-table_id-type"
  end

  create_table "email_log", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "type", limit: 40
    t.string "email_from", limit: 50
    t.string "email_to", limit: 200
    t.string "subject", limit: 200
    t.text "rich_text"
    t.datetime "created", precision: nil
    t.string "created_by", limit: 40, null: false
  end

  create_table "extra_charges_list", id: :integer, charset: "utf8mb3", comment: "Holds the names and prices for adding additional charges", force: :cascade do |t|
    t.string "description", limit: 32, null: false
    t.decimal "amount", precision: 8, scale: 2, null: false
    t.integer "sort", limit: 2, null: false, unsigned: true
    t.column "active", "enum('Active','Inactive')", default: "Active"
  end

  create_table "extra_fees", id: { type: :integer, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "order_id", null: false, unsigned: true
    t.string "type", limit: 32, null: false
    t.text "description", null: false
    t.float "tax", default: 0.0, null: false, unsigned: true
    t.integer "order_line_id", null: false, unsigned: true
    t.integer "charged_by", null: false, unsigned: true
    t.integer "charged_id", unsigned: true
    t.timestamp "timestamp", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["order_id", "type", "order_line_id"], name: "order_id"
  end

  create_table "extra_shipping_charges_list", id: :integer, charset: "utf8mb3", comment: "Holds the names and prices for adding additional shipping charges", force: :cascade do |t|
    t.string "description", limit: 32, null: false
    t.decimal "amount", precision: 8, scale: 2, null: false
    t.string "quantity_prompt_text", limit: 50
    t.integer "sort", limit: 2, null: false, unsigned: true
    t.column "active", "enum('Active','Inactive')", default: "Active"
  end

  create_table "fees", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "fee", limit: 30, null: false
    t.string "recurring", limit: 10, null: false
    t.string "type", limit: 1, null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "period", limit: 10, null: false
  end

  create_table "floors", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "name", limit: 64, null: false
    t.index ["name"], name: "name", unique: true
  end

  create_table "fucks", id: false, charset: "utf8mb3", force: :cascade do |t|
    t.integer "fucks", null: false
    t.boolean "given", default: true, null: false
    t.string "by", limit: 10, default: "your mom", null: false
  end

  create_table "full_sessions", id: { type: :integer, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.string "session_id", limit: 50
    t.text "data", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["created_at"], name: "index_full_sessions_created_at"
    t.index ["session_id"], name: "unique_full_sessions_session_id", unique: true
    t.index ["updated_at"], name: "index_full_sessions_updated_at"
  end

  create_table "handle_stripe", id: :integer, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "action", null: false
    t.integer "order_id", null: false
    t.integer "invoice_id", null: false
    t.string "stripe_invoice_id", null: false
    t.integer "added_by"
    t.integer "product_id", null: false
    t.timestamp "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "ihs_orders", id: { type: :integer, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "rental_order_id", null: false, unsigned: true
    t.integer "tax_authority_id"
    t.integer "transaction_id"
    t.integer "payment_id"
    t.text "lines"
    t.text "billing_details"
    t.text "delivery_details"
    t.decimal "subtotal", precision: 13, scale: 4, null: false
    t.decimal "tax_total", precision: 13, scale: 4, null: false
    t.decimal "delivery_total", precision: 13, scale: 4, null: false
    t.decimal "total", precision: 13, scale: 4, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["rental_order_id"], name: "index_ihs_orders_rental_order"
  end

  create_table "ihs_orders_catalogs", id: { type: :integer, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.boolean "inhome_flyer", default: false
    t.string "partner_type", limit: 50
    t.string "partner_name", limit: 50
    t.string "partner_email", limit: 50
    t.string "partner_telephone", limit: 50
    t.integer "partner_user_id"
    t.datetime "email_sent_for_sale", precision: nil
    t.datetime "email_sent_destage", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "order_id", null: false, unsigned: true
    t.string "qrcode_filename", limit: 50
    t.index ["order_id"], name: "index_ihs_order_catalogs_order"
  end

  create_table "ihs_orders_catalogs2", id: { type: :integer, unsigned: true }, charset: "latin1", force: :cascade do |t|
    t.integer "order_id", unsigned: true
    t.string "partner_name", limit: 40, collation: "utf8mb3_general_ci"
    t.string "partner_email", limit: 50, collation: "utf8mb3_general_ci"
    t.string "partner_telephone", limit: 20, collation: "utf8mb3_general_ci"
    t.integer "partner_id", unsigned: true
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "ihs_orders_pseudo_rows", primary_key: "row", id: { type: :integer, unsigned: true, default: nil }, charset: "utf8mb3", force: :cascade do |t|
  end

  create_table "image_library", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "image", limit: 250, null: false
    t.integer "width", default: 0, null: false
    t.integer "height", default: 0, null: false
    t.string "cached_url"
    t.datetime "cached_at", precision: nil
    t.string "neosis_urls", limit: 250
    t.boolean "default_image", default: false
    t.index ["user_id"], name: "user_id"
  end

  create_table "intuit_accounts", id: :integer, charset: "latin1", force: :cascade do |t|
    t.string "oauth2_access_token", limit: 1150
    t.datetime "oauth2_access_token_expires_at", precision: nil
    t.string "oauth2_refresh_token"
    t.datetime "oauth2_refresh_token_expires_at", precision: nil
    t.string "realm_id"
  end

  create_table "invoice_line_items", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "invoice_line_id", null: false
    t.integer "product_id", null: false
    t.integer "order_id"
    t.datetime "from_date", precision: nil, null: false
    t.datetime "to_date", precision: nil, null: false
    t.decimal "amount", precision: 20, scale: 8, null: false
    t.decimal "commission", precision: 20, scale: 8
    t.decimal "tax", precision: 20, scale: 8
    t.integer "owner_id", null: false
    t.string "reference", limit: 20
  end

  create_table "invoice_lines", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "invoice_id", null: false
    t.integer "site_id"
    t.integer "tax_authority_id"
    t.string "fee", limit: 40, null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.decimal "commission", precision: 10, scale: 2
    t.decimal "tax", precision: 10, scale: 2
    t.datetime "to_date", precision: nil
    t.boolean "has_lines", null: false
    t.datetime "created", precision: nil, null: false
    t.string "created_by", limit: 40, null: false
    t.string "created_with", limit: 50, null: false
    t.datetime "edited", precision: nil, null: false
    t.string "edited_by", limit: 40, null: false
    t.string "edited_with", limit: 50, null: false
    t.index ["invoice_id"], name: "invoice_id"
  end

  create_table "invoices", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "status", limit: 20, null: false
    t.datetime "from_date", precision: nil, null: false
    t.datetime "to_date", precision: nil, null: false
    t.datetime "post_date", precision: nil
    t.string "check_number", limit: 20
    t.datetime "check_date", precision: nil
    t.string "check_note", limit: 250
    t.decimal "late_fee", precision: 10, scale: 2
    t.datetime "created", precision: nil, null: false
    t.string "created_by", limit: 40, null: false
    t.string "created_with", limit: 50, null: false
    t.datetime "edited", precision: nil, null: false
    t.string "edited_by", limit: 40, null: false
    t.string "edited_with", limit: 50, null: false
    t.integer "order_id", default: 0, null: false
    t.float "invoice_total", default: 0.0
    t.string "qbo_invoice_id"
    t.float "prorated_invoice_total", default: 0.0
    t.string "qbo_doc_number"
    t.string "stripe_invoice_id"
    t.string "stripe_doc_number"
    t.index ["user_id"], name: "user_id"
  end

  create_table "invoices_qbo", id: :integer, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "order_id", null: false
    t.integer "invoice_id", null: false
    t.string "qbo_invoice_id", null: false
    t.integer "added_by"
    t.timestamp "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "location_request", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "first_name", limit: 32, null: false
    t.string "last_name", limit: 32, null: false
    t.string "email", limit: 64, null: false
    t.string "office", limit: 32, null: false
    t.string "requested_state", limit: 2, null: false
    t.string "requested_city", limit: 32, null: false
  end

  create_table "locations", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "location", limit: 30, null: false
    t.integer "warehouse_id", default: 1, null: false
    t.string "active", limit: 15, default: "Active", null: false
  end

  create_table "login_slides", id: :integer, charset: "latin1", force: :cascade do |t|
    t.string "slide", limit: 200, null: false
    t.boolean "active", null: false
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP" }, null: false
    t.integer "updated_by_user_id", null: false
    t.index ["active"], name: "active"
  end

  create_table "lunchandlearn", id: { type: :integer, unsigned: true }, charset: "latin1", force: :cascade do |t|
    t.string "first_name", limit: 32, null: false, collation: "utf8mb3_general_ci"
    t.string "last_name", limit: 32, null: false, collation: "utf8mb3_general_ci"
    t.string "email", limit: 80, null: false, collation: "utf8mb3_general_ci"
    t.string "telephone", limit: 10, null: false, collation: "utf8mb3_general_ci"
    t.string "address", limit: 64, null: false, collation: "utf8mb3_general_ci"
    t.string "food", limit: 16, null: false, collation: "utf8mb3_general_ci"
    t.string "zip", limit: 6, null: false, collation: "utf8mb3_general_ci"
    t.string "cc", limit: 4, null: false, collation: "utf8mb3_general_ci"
    t.string "cardName", limit: 80, null: false, collation: "utf8mb3_general_ci"
    t.string "cardType", limit: 10, null: false, collation: "utf8mb3_general_ci"
    t.float "price", null: false
    t.string "Auth", limit: 32, null: false, collation: "utf8mb3_general_ci"
    t.string "PNRef", limit: 32, null: false, collation: "utf8mb3_general_ci"
  end

  create_table "manual_payments", id: { type: :integer, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "customer", null: false
    t.float "amount", null: false
    t.float "tax"
    t.float "value", null: false
    t.text "note", null: false
    t.integer "cc"
    t.integer "created_by", null: false
    t.timestamp "transaction_date", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "Auth", limit: 32
    t.string "PNRef", limit: 32
    t.column "status", "set('OK','FAILED')"
    t.string "payment_type", limit: 50, null: false
    t.string "payment_type_description", limit: 50
    t.string "check_no", limit: 32
    t.string "reason", limit: 32, null: false
    t.string "reason_description", limit: 250
    t.decimal "tax_rate", precision: 10, scale: 3
    t.integer "order_id"
    t.integer "payment_log_id"
    t.string "payment_type_id", limit: 50, null: false
  end

  create_table "membership_level_benefits", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "membership_level_id", null: false
    t.integer "benefit_id", null: false
    t.boolean "selected", null: false
    t.index ["membership_level_id", "benefit_id"], name: "membership_id"
  end

  create_table "membership_level_commissions", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "membership_level_id", null: false, unsigned: true
    t.decimal "base_commission", precision: 5, scale: 3
    t.decimal "promo_commission", precision: 5, scale: 3
    t.integer "promo_days_active"
    t.integer "created_by"
    t.integer "updated_by"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "membership_level_commissions_history", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "membership_level_id", null: false, unsigned: true
    t.decimal "base_commission", precision: 5, scale: 3
    t.decimal "promo_commission", precision: 5, scale: 3
    t.integer "promo_days_active"
    t.integer "created_by"
    t.integer "updated_by"
    t.datetime "active_from", precision: nil
    t.datetime "active_to", precision: nil
  end

  create_table "membership_level_terms", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "membership_level_id", null: false
    t.string "active", limit: 10, null: false
    t.integer "term_length", null: false
    t.string "term", limit: 100, null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.string "description", limit: 250
    t.index ["membership_level_id"], name: "membership_level_id"
  end

  create_table "membership_levels", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "level", limit: 40, null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.string "active", limit: 10, null: false
    t.string "color", limit: 7, null: false
    t.integer "usage_level", null: false
    t.string "free_storage", limit: 3, default: "No", null: false
    t.string "display", limit: 3, default: "Yes", null: false
    t.string "subtitle", limit: 250
    t.string "default_term_text", limit: 50
    t.integer "sequence", default: 1, null: false
    t.integer "discount_percent"
    t.index ["level", "active"], name: "level"
  end

  create_table "menu_sections", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "title", limit: 40, null: false
    t.string "section", limit: 30, null: false
    t.string "token", limit: 30
    t.integer "width", default: 300, null: false
    t.string "picture", limit: 30
    t.boolean "is_sub_menu", null: false
    t.integer "item_of"
  end

  create_table "modules", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "module", limit: 40, null: false
    t.boolean "is_sub_menu", null: false
    t.integer "item_of"
    t.string "section_id", limit: 50
    t.integer "position", null: false
    t.string "warehouse_name", default: "warehouse1", null: false
  end

  create_table "notes", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "table_name", limit: 30, null: false
    t.integer "table_id", null: false
    t.string "note", null: false
    t.boolean "popup", null: false
    t.string "file", limit: 250
    t.datetime "created", precision: nil, null: false
    t.string "created_by", limit: 50, null: false
    t.string "created_with", limit: 30
    t.datetime "edited", precision: nil, null: false
    t.string "edited_by", limit: 50, null: false
    t.string "edited_with", limit: 30
  end

  create_table "notify", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "email", limit: 128, null: false
    t.timestamp "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["email"], name: "email", unique: true
  end

  create_table "order_deposits", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "type", limit: 10, null: false
    t.integer "order_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.integer "released_id"
    t.datetime "release_date", precision: nil
    t.datetime "created", precision: nil, null: false
    t.string "created_by", limit: 40, null: false
    t.string "created_with", limit: 50, null: false
    t.datetime "edited", precision: nil, null: false
    t.string "edited_by", limit: 40, null: false
    t.string "edited_with", limit: 50, null: false
    t.index ["order_id"], name: "order_id"
  end

  create_table "order_edit_log", id: { type: :integer, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "order_id", null: false
    t.integer "user_id", null: false
    t.string "action", limit: 50, null: false
    t.string "old_value"
    t.string "new_value", null: false
    t.datetime "created_at", precision: nil
  end

  create_table "order_fees", id: { type: :integer, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "order_id", null: false, unsigned: true
    t.integer "user_id", null: false, unsigned: true
    t.float "charges", null: false, unsigned: true
    t.float "destage", null: false, unsigned: true
    t.float "shipping", null: false, unsigned: true
    t.float "waiver", null: false, unsigned: true
    t.float "tax", null: false, unsigned: true
    t.timestamp "date", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.float "amount", null: false, unsigned: true
    t.text "products", null: false
    t.integer "payment_id", null: false, unsigned: true
    t.index ["order_id"], name: "order_id"
    t.index ["payment_id"], name: "payment_id"
  end

  create_table "order_line_barcodes", primary_key: ["order_line_id", "barcode_id"], charset: "latin1", force: :cascade do |t|
    t.integer "order_line_id", null: false
    t.integer "barcode_id", null: false
    t.datetime "added_date", precision: nil
    t.datetime "picked_date", precision: nil
    t.datetime "shipped_date", precision: nil
    t.datetime "returned_date", precision: nil
  end

  create_table "order_lines", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "order_id", null: false
    t.integer "product_id"
    t.decimal "price", precision: 10, scale: 4
    t.decimal "base_price", precision: 10, scale: 4
    t.text "description"
    t.string "reference", limit: 10
    t.string "self_rental_pre_credited", limit: 5, default: "No"
    t.string "void", limit: 3, default: "no", null: false
    t.string "change_confirmed", limit: 5
    t.datetime "voided_date", precision: nil
    t.string "voided_by", limit: 40
    t.string "refunded", limit: 10, default: "No"
    t.integer "refunded_by"
    t.integer "room_id", default: 20, null: false
    t.integer "floor_id", default: 1, null: false
    t.integer "quantity", default: 1, null: false
    t.string "type"
    t.index ["floor_id"], name: "floor_id"
    t.index ["order_id", "product_id"], name: "order_id&product_id"
    t.index ["order_id"], name: "order_id"
    t.index ["product_id"], name: "product_id"
    t.index ["reference"], name: "reference"
    t.index ["refunded"], name: "refunded"
    t.index ["room_id"], name: "room_id"
  end

  create_table "order_lines_detail", primary_key: "order_lines_id", id: :integer, charset: "latin1", force: :cascade do |t|
    t.datetime "ordered", precision: nil
    t.datetime "shipped", precision: nil
    t.datetime "returned", precision: nil
  end

  create_table "order_logs", id: :integer, charset: "latin1", force: :cascade do |t|
    t.integer "order_id", null: false
    t.text "product_pieces"
    t.timestamp "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "order_promo_codes", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "order_table", limit: 20, default: "orders"
    t.integer "order_id", null: false
    t.integer "promo_code_id", null: false
    t.decimal "value", precision: 10, scale: 2, null: false
    t.index ["order_id", "promo_code_id"], name: "order_id"
  end

  create_table "order_queries", id: :integer, charset: "latin1", force: :cascade do |t|
    t.integer "order_id"
    t.integer "user_id"
    t.text "message"
    t.boolean "is_employee"
    t.boolean "is_customer"
    t.string "image_url"
    t.text "docs"
    t.boolean "is_read_by_admin", default: false
    t.boolean "is_read", default: false
    t.integer "recipient_id"
  end

  create_table "order_shipping_charges", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "order_table", limit: 20, default: "orders"
    t.integer "order_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.integer "shipping_approval_code_id"
    t.string "note", limit: 250
    t.datetime "created", precision: nil, null: false
    t.string "created_by", limit: 40, null: false
    t.string "created_with", limit: 50, null: false
  end

  create_table "order_status_signatures", id: { type: :bigint, unsigned: true }, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "signature_url", null: false
    t.string "order_status", limit: 50, null: false
    t.timestamp "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "notes"
    t.integer "order_id", null: false
    t.integer "updated_by", default: 0
    t.index ["order_id"], name: "fk_order"
  end

  create_table "orders", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "site_id", default: 0, null: false
    t.integer "tax_authority_id"
    t.string "order_type", limit: 20, null: false
    t.string "service", limit: 20
    t.integer "service_confirmed", limit: 1, default: 0, null: false
    t.string "status", limit: 20, null: false
    t.string "is_changed", limit: 5, default: "no", null: false
    t.string "project_name", limit: 40
    t.integer "address_id"
    t.integer "bill_to_address_id"
    t.string "first_name", limit: 20
    t.string "last_name", limit: 20
    t.string "company", limit: 40
    t.string "address1", limit: 100
    t.string "address2", limit: 40
    t.string "city", limit: 40
    t.string "state", limit: 2
    t.string "zip", limit: 10
    t.string "country", limit: 20
    t.string "phone", limit: 15
    t.string "bill_to_first_name", limit: 20
    t.string "bill_to_last_name", limit: 20
    t.string "bill_to_company", limit: 40
    t.string "bill_to_address1", limit: 50
    t.string "bill_to_address2", limit: 50
    t.string "bill_to_city", limit: 20
    t.string "bill_to_state", limit: 2
    t.string "bill_to_zip", limit: 10
    t.string "bill_to_country", limit: 20
    t.string "bill_to_phone", limit: 15
    t.datetime "ordered_date", precision: nil
    t.datetime "due_date", precision: nil
    t.datetime "complete_date", precision: nil
    t.string "reference", limit: 40
    t.string "show_in_orders", limit: 5, default: "Yes", null: false
    t.datetime "delivery_date", precision: nil
    t.datetime "delivery_start_date", precision: nil
    t.datetime "delivery_stop_date", precision: nil
    t.datetime "destage_date", precision: nil
    t.datetime "destage_start_date", precision: nil
    t.datetime "destage_stop_date", precision: nil
    t.datetime "shipping_date", precision: nil
    t.text "note"
    t.string "finalized", limit: 5, default: "No"
    t.string "tax_location_id", limit: 10
    t.integer "credit_card_id"
    t.boolean "rush_order", default: false
    t.string "dwelling"
    t.string "parking"
    t.string "levels"
    t.text "delivery_special_considerations"
    t.string "due_date_change_reason"
    t.integer "due_date_changed_by"
    t.index ["id", "order_type"], name: "id_type", unique: true
    t.index ["order_type"], name: "type"
    t.index ["user_id", "order_type"], name: "user_id"
  end

  create_table "orders_on_hold", id: { type: :integer, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "order_id", null: false
    t.column "on_hold", "enum('HOLD','CHARGE')", default: "HOLD", null: false
    t.integer "created_by", null: false, unsigned: true
    t.integer "updated_by", null: false, unsigned: true
    t.timestamp "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.timestamp "updated_at", default: -> { "CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP" }, null: false
    t.index ["order_id"], name: "order_id", unique: true
  end

  create_table "page_menu_sections", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "section_id", null: false
    t.integer "page_type_id", null: false
    t.string "color", limit: 10, null: false
    t.integer "order", null: false
  end

  create_table "pages", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "page", limit: 30, null: false
    t.string "token", limit: 50
    t.integer "page_type_id", null: false
  end

  create_table "payleap", id: false, charset: "utf8mb3", force: :cascade do |t|
    t.integer "TRX_HD_Key", null: false, unsigned: true
    t.integer "Invoice_ID", null: false, unsigned: true
    t.datetime "Date_DT", precision: nil, null: false
    t.integer "Merchant_Key", null: false
    t.integer "Reseller_Key", null: false
    t.string "TUser_Name_VC", limit: 32, null: false
    t.string "Processor_ID", limit: 32, null: false
    t.string "TRX_Settle_Key", limit: 16, null: false
    t.float "Tip_Amt_MN", null: false
    t.string "Approval_Code_CH", limit: 16, null: false
    t.float "Auth_Amt_MN", null: false
    t.string "IP_VC", limit: 16, null: false
    t.string "Account_Type_CH", limit: 16, null: false
    t.string "Last_Update_DT", limit: 16, null: false
    t.string "Orig_TRX_HD_Key", limit: 16, null: false
    t.string "Settle_Date_DT", limit: 32, null: false
    t.string "Settle_Flag_CH", limit: 16, null: false
    t.string "Trans_Type_ID", limit: 16, null: false
    t.string "Void_Flag_CH", limit: 8, null: false
    t.integer "CustomerID", null: false
    t.string "AVS_Resp_CH", limit: 2, null: false
    t.string "CV_Resp_CH", limit: 2, null: false
    t.string "Host_Ref_Num_CH", limit: 16, null: false
    t.string "Zip_CH", limit: 8, null: false
    t.integer "Acct_Num_CH", null: false
    t.float "Total_Amt_MN", null: false
    t.string "Exp_CH", limit: 4, null: false
    t.string "Name_on_Card_VC", limit: 32, null: false
    t.string "Type_CH", limit: 16, null: false
    t.float "Cash_Back_Amt_MN", null: false
    t.string "Result_CH", limit: 16, null: false
    t.string "Result_Txt_VC", limit: 32, null: false
    t.string "Trans_Status", limit: 32, null: false
    t.integer "PO_Num", null: false
    t.index ["TRX_HD_Key"], name: "TRX_HD_Key", unique: true
  end

  create_table "payleap_log", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "action", limit: 20, null: false
    t.text "response", null: false
    t.datetime "created", precision: nil, null: false
    t.string "created_by", limit: 40
  end

  create_table "payleap_request_log", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.text "request"
    t.timestamp "created", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "payment_gateway", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "gateway", limit: 20, null: false
    t.string "username", limit: 20, null: false
    t.string "password", limit: 20, null: false
    t.string "transaction_key", limit: 20, null: false
    t.integer "vendor", null: false
    t.string "gateway_mode", limit: 10, default: "dev", null: false
  end

  create_table "payment_log", id: false, charset: "utf8mb3", force: :cascade do |t|
    t.integer "id", null: false, unsigned: true, auto_increment: true
    t.integer "user_id", null: false, unsigned: true
    t.integer "action", limit: 2, null: false, unsigned: true
    t.integer "stored_card", null: false, unsigned: true
    t.string "cc", limit: 4, null: false
    t.string "card_name", limit: 80, null: false
    t.string "card_type", limit: 10, null: false
    t.string "cc_month", limit: 2, null: false
    t.string "cc_year", limit: 4, null: false
    t.float "price", null: false
    t.string "auth_code", limit: 32, null: false
    t.string "PNRef", limit: 32, null: false
    t.timestamp "created", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "created_by", null: false, unsigned: true
    t.index ["id"], name: "id", unique: true
  end

  create_table "payment_methods", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "method", limit: 20, null: false
  end

  create_table "payment_type", id: { type: :integer, limit: 2, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.string "type", limit: 32, null: false
    t.string "description", limit: 96, null: false
    t.index ["id"], name: "id"
  end

  create_table "php_classes", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "class", limit: 40, null: false
    t.index ["class"], name: "class", unique: true
  end

  create_table "print_label_log", id: { type: :integer, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "user_id", null: false, unsigned: true
    t.integer "product_id", null: false, unsigned: true
    t.timestamp "timestamp", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "print_order_processes", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "status", limit: 10, null: false
  end

  create_table "product_attributes", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "product_id", null: false
    t.integer "attribute_id"
    t.index ["attribute_id"], name: "attribute_id"
    t.index ["product_id"], name: "product_id"
  end

  create_table "product_attributes_backup_20241010", id: false, charset: "latin1", force: :cascade do |t|
    t.integer "id", default: 0, null: false
    t.integer "product_id", null: false
    t.integer "attribute_id"
  end

  create_table "product_collections", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "collection_id", null: false
    t.integer "product_id", null: false
  end

  create_table "product_edit_log", id: { type: :integer, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "product_id", null: false
    t.integer "user_id", null: false
    t.string "action", limit: 50, null: false
    t.string "old_value"
    t.string "new_value", null: false
    t.datetime "created_at", precision: nil
  end

  create_table "product_history", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "product_id", null: false, unsigned: true
    t.datetime "date", precision: nil, null: false
  end

  create_table "product_images", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "product_id", null: false
    t.integer "image_id", null: false
    t.integer "image_order", null: false
    t.boolean "default_image", default: false
    t.index ["product_id"], name: "product_id"
  end

  create_table "product_images_20241010", id: false, charset: "latin1", force: :cascade do |t|
    t.integer "id", default: 0, null: false
    t.integer "product_id", null: false
    t.integer "image_id", null: false
    t.integer "image_order", null: false
  end

  create_table "product_nontransient_dates", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "type", limit: 10, default: "Reserved", null: false
    t.integer "product_id", null: false
    t.datetime "start_date", precision: nil, null: false
    t.datetime "end_date", precision: nil
    t.decimal "cost", precision: 10, scale: 2, null: false
    t.index ["product_id", "type"], name: "product_id&type"
    t.index ["start_date", "end_date"], name: "dates"
  end

  create_table "product_piece_locations", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "product_piece_id", null: false
    t.column "log_status", "enum('Pending','Posted')", null: false
    t.column "log_type", "enum('OnOrder','Received','Available','Picked','Transfer','Shipped','Returned','InTransit','Pulled')", null: false
    t.column "table_name", "enum('bins','orders')", null: false
    t.integer "table_id", null: false
    t.datetime "created", precision: nil, null: false
    t.string "created_by", limit: 30, null: false
    t.column "void", "enum('yes','no')", default: "no", null: false
    t.datetime "voided_date", precision: nil
    t.string "voided_by", limit: 40
    t.string "pick_up_sdn", limit: 45
    t.integer "order_line_id"
    t.index ["id", "table_name", "void", "product_piece_id"], name: "table_name_void_id", unique: true
    t.index ["product_piece_id", "log_status", "log_type", "table_name", "void"], name: "product_piece_id_2"
    t.index ["product_piece_id", "table_name", "table_id", "id"], name: "id_table_name_table_id_product_piece_id", unique: true
    t.index ["product_piece_id"], name: "product_piece_id"
    t.index ["table_id", "table_name"], name: "table_id_table_name"
    t.index ["table_name", "table_id", "product_piece_id"], name: "table_name_table_id_product_piece_id"
    t.index ["table_name", "table_id", "void", "product_piece_id", "id"], name: "table_name_table_id_product_piece_id_void_id", unique: true
  end

  create_table "product_piece_locations_history", id: :integer, charset: "utf8mb3", options: "ENGINE=InnoDB AVG_ROW_LENGTH=57", force: :cascade do |t|
    t.integer "product_piece_id", null: false
    t.column "log_status", "enum('Pending','Posted')", null: false
    t.column "log_type", "enum('OnOrder','Received','Available','Picked','Transfer','Shipped','Returned','InTransit','Pulled')", null: false
    t.column "table_name", "enum('bins','orders')", null: false
    t.integer "table_id", null: false
    t.datetime "created", precision: nil, null: false
    t.string "created_by", limit: 30, null: false
    t.column "void", "enum('yes','no')", default: "no", null: false
    t.datetime "voided_date", precision: nil
    t.string "voided_by", limit: 40
    t.string "pick_up_sdn", limit: 45
    t.integer "order_line_id"
    t.index ["id", "table_name", "void", "product_piece_id"], name: "table_name_void_id", unique: true
    t.index ["product_piece_id", "table_name", "table_id", "id"], name: "id_table_name_table_id_product_piece_id", unique: true
    t.index ["table_name", "table_id", "void", "product_piece_id", "id"], name: "table_name_table_id_product_piece_id_void_id", unique: true
  end

  create_table "product_pieces", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "product_id", null: false
    t.integer "order_line_id"
    t.string "epc_code"
    t.string "product_epc_id"
    t.string "status", limit: 20, default: "Available", null: false
    t.integer "bin_id"
    t.integer "site_id"
    t.index ["id", "order_line_id"], name: "order_line_id_id", unique: true
    t.index ["id", "product_id"], name: "product_id_id", unique: true
    t.index ["order_line_id"], name: "order_line_id"
    t.index ["product_id"], name: "product_id"
  end

  create_table "product_pieces_logs", id: :integer, charset: "latin1", force: :cascade do |t|
    t.integer "product_id"
    t.integer "order_line_id"
    t.integer "previous_order_line_id"
    t.string "epc_code"
    t.integer "product_epc_id"
    t.string "previous_status", limit: 50
    t.string "status", limit: 50
    t.timestamp "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.timestamp "updated_at", default: -> { "CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP" }, null: false
    t.integer "added_by"
    t.boolean "confirm", default: false
    t.integer "confirmed_by"
    t.datetime "confirmed_at", precision: nil
    t.integer "order_id"
  end

  create_table "product_prices_backup_20241010", id: false, charset: "latin1", force: :cascade do |t|
    t.integer "id", default: 0, null: false
    t.integer "product_id", null: false
    t.integer "order_line_id"
    t.string "epc_code", collation: "utf8mb3_general_ci"
    t.string "product_epc_id", collation: "utf8mb3_general_ci"
    t.string "status", limit: 20, default: "Available", null: false, collation: "utf8mb3_general_ci"
  end

  create_table "product_related_items", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "product_id", null: false
    t.integer "related_product_id", null: false
    t.integer "sequence", null: false
    t.index ["product_id"], name: "product_id"
  end

  create_table "product_reservations", id: { type: :integer, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "product_id"
    t.integer "user_id"
    t.datetime "created_at", precision: nil
  end

  create_table "product_subattributes", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "product_id", null: false
    t.integer "subattribute_id", null: false
    t.index ["product_id"], name: "product_id"
    t.index ["subattribute_id"], name: "subattribute_id"
  end

  create_table "products", charset: "utf8mb3", force: :cascade do |t|
    t.string "product_type", limit: 20, default: "Rental&Resale", null: false
    t.column "active", "enum('Active','Damaged','Does Not Exist','Donated','Inactive','Missing','OBNH','On Hold','Rebarcoded','Returned to Owner','Shrink','Sold','Transfer')", default: "Active", null: false
    t.string "upc", limit: 50
    t.string "serial", limit: 30
    t.string "product"
    t.boolean "for_sale", default: true, null: false
    t.boolean "for_rent", default: true, null: false
    t.string "description", limit: 500
    t.text "long_description"
    t.text "product_restrictions"
    t.boolean "smoking", default: false, null: false
    t.boolean "pets", default: false, null: false
    t.boolean "owner_occupied", default: false, null: false
    t.boolean "children", default: false, null: false
    t.integer "main_image_id"
    t.integer "quantity", default: 1, null: false
    t.date "available", null: false
    t.boolean "reserved", default: false, null: false
    t.boolean "box", default: false, null: false
    t.string "stored", limit: 30, default: "Warehouse", null: false
    t.string "status", limit: 30, default: "Available", null: false
    t.decimal "storage_price", precision: 12, scale: 2, default: "0.25"
    t.decimal "catalog_price", precision: 10, scale: 2
    t.decimal "sdn_cost", precision: 10, scale: 2, default: "0.0", null: false, unsigned: true
    t.decimal "income", precision: 12, scale: 2
    t.bigint "category_id"
    t.integer "store_category_id"
    t.integer "store_sub_category_id"
    t.integer "customer_id"
    t.integer "supplier_id"
    t.decimal "depth", precision: 10, scale: 2, default: "0.0"
    t.decimal "width", precision: 10, scale: 2, default: "0.0"
    t.decimal "height", precision: 10, scale: 2, default: "0.0"
    t.decimal "length", precision: 10, scale: 2, default: "0.0"
    t.decimal "weight", precision: 10, scale: 2
    t.decimal "rent_per_day", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "rent_per_month", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "sale_price", precision: 12, scale: 2
    t.decimal "rental_value", precision: 10, scale: 2
    t.decimal "preferred_price", precision: 10, scale: 2
    t.decimal "executive_price", precision: 10, scale: 2
    t.decimal "list_price", precision: 10, scale: 2
    t.string "warranty_file", limit: 150
    t.string "return_policy_file", limit: 250
    t.string "estimated_ship_date", limit: 250
    t.string "freight_ship_time", limit: 100
    t.string "delivery_method", limit: 100
    t.decimal "delivery_surcharge", precision: 10, scale: 2
    t.integer "action_required", limit: 1
    t.string "action_required_reason", limit: 250
    t.datetime "added_to_cart", precision: nil
    t.string "meta_title", limit: 200
    t.string "meta_keywords", limit: 500
    t.string "meta_description", limit: 1000
    t.datetime "created", precision: nil, null: false
    t.string "created_by", limit: 20
    t.text "delete_reason"
    t.string "manufacture_name", limit: 32, default: "", null: false
    t.string "manufacture_number", limit: 32, default: "", null: false
    t.decimal "deacq_price", precision: 10, scale: 2, default: "0.0", null: false, unsigned: true
    t.string "initials", limit: 8, default: "", null: false
    t.date "deacq_date"
    t.text "reserve_reason", null: false
    t.integer "bin_id"
    t.integer "site_id"
    t.string "SKU"
    t.integer "offer_id"
    t.boolean "landscape", default: false
    t.boolean "portrait", default: false
    t.float "quality_rating", default: 3.0
    t.index ["category_id"], name: "category_id"
    t.index ["created"], name: "created"
    t.index ["customer_id"], name: "customer_id"
    t.index ["product"], name: "product"
  end

  create_table "products_copy", id: false, charset: "latin1", force: :cascade do |t|
    t.bigint "id", default: 0, null: false
    t.string "type", limit: 20, default: "Rental&Resale", null: false, collation: "utf8mb3_general_ci"
    t.column "active", "enum('Active','Damaged','Does Not Exist','Donated','Inactive','Missing','OBNH','On Hold','Rebarcoded','Returned to Owner','Shrink','Sold','Transfer')", default: "Active", null: false, collation: "utf8mb3_general_ci"
    t.string "upc", limit: 50, collation: "utf8mb3_general_ci"
    t.string "serial", limit: 30, collation: "utf8mb3_general_ci"
    t.string "product", collation: "utf8mb3_general_ci"
    t.boolean "for_sale", default: true, null: false
    t.boolean "for_rent", default: true, null: false
    t.string "description", limit: 500, collation: "utf8mb3_general_ci"
    t.string "long_description", limit: 500, null: false, collation: "utf8mb3_general_ci"
    t.text "product_restrictions", collation: "utf8mb3_general_ci"
    t.boolean "smoking", default: false, null: false
    t.boolean "pets", default: false, null: false
    t.boolean "owner_occupied", default: false, null: false
    t.boolean "children", default: false, null: false
    t.integer "main_image_id"
    t.integer "quantity", default: 1, null: false
    t.date "available", null: false
    t.boolean "reserved", default: false, null: false
    t.boolean "box", default: false, null: false
    t.string "stored", limit: 30, default: "Warehouse", null: false, collation: "utf8mb3_general_ci"
    t.string "status", limit: 30, default: "Available", null: false, collation: "utf8mb3_general_ci"
    t.decimal "storage_price", precision: 12, scale: 2, default: "0.25"
    t.decimal "catalog_price", precision: 10, scale: 2
    t.decimal "sdn_cost", precision: 10, scale: 2, default: "0.0", null: false, unsigned: true
    t.decimal "income", precision: 12, scale: 2
    t.bigint "category_id"
    t.integer "store_category_id"
    t.integer "store_sub_category_id"
    t.integer "customer_id"
    t.integer "supplier_id"
    t.decimal "depth", precision: 10, scale: 2, default: "0.0"
    t.decimal "width", precision: 10, scale: 2, default: "0.0"
    t.decimal "height", precision: 10, scale: 2, default: "0.0"
    t.decimal "weight", precision: 10, scale: 2
    t.decimal "rent_per_day", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "rent_per_month", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "sale_price", precision: 12, scale: 2
    t.decimal "rental_value", precision: 10, scale: 2
    t.decimal "preferred_price", precision: 10, scale: 2
    t.decimal "executive_price", precision: 10, scale: 2
    t.decimal "list_price", precision: 10, scale: 2
    t.string "warranty_file", limit: 150, collation: "utf8mb3_general_ci"
    t.string "return_policy_file", limit: 250, collation: "utf8mb3_general_ci"
    t.string "estimated_ship_date", limit: 250, collation: "utf8mb3_general_ci"
    t.string "freight_ship_time", limit: 100, collation: "utf8mb3_general_ci"
    t.string "delivery_method", limit: 100, collation: "utf8mb3_general_ci"
    t.decimal "delivery_surcharge", precision: 10, scale: 2
    t.integer "action_required", limit: 1
    t.string "action_required_reason", limit: 250, collation: "utf8mb3_general_ci"
    t.datetime "added_to_cart", precision: nil
    t.string "meta_title", limit: 200, collation: "utf8mb3_general_ci"
    t.string "meta_keywords", limit: 500, collation: "utf8mb3_general_ci"
    t.string "meta_description", limit: 1000, collation: "utf8mb3_general_ci"
    t.datetime "created", precision: nil, null: false
    t.string "created_by", limit: 20, collation: "utf8mb3_general_ci"
    t.text "delete_reason", collation: "utf8mb3_general_ci"
    t.string "manufacture_name", limit: 32, default: "", null: false, collation: "utf8mb3_general_ci"
    t.string "manufacture_number", limit: 32, default: "", null: false, collation: "utf8mb3_general_ci"
    t.decimal "deacq_price", precision: 10, scale: 2, default: "0.0", null: false, unsigned: true
    t.string "initials", limit: 8, default: "", null: false, collation: "utf8mb3_general_ci"
    t.date "deacq_date"
    t.text "reserve_reason", null: false, collation: "utf8mb3_general_ci"
    t.integer "bin_id"
    t.integer "site_id"
    t.string "SKU", collation: "utf8mb3_general_ci"
    t.integer "offer_id"
  end

  create_table "products_copy_20241010", id: false, charset: "latin1", force: :cascade do |t|
    t.bigint "id", default: 0, null: false
    t.string "type", limit: 20, default: "Rental&Resale", null: false, collation: "utf8mb3_general_ci"
    t.column "active", "enum('Active','Damaged','Does Not Exist','Donated','Inactive','Missing','OBNH','On Hold','Rebarcoded','Returned to Owner','Shrink','Sold','Transfer')", default: "Active", null: false, collation: "utf8mb3_general_ci"
    t.string "upc", limit: 50, collation: "utf8mb3_general_ci"
    t.string "serial", limit: 30, collation: "utf8mb3_general_ci"
    t.string "product", collation: "utf8mb3_general_ci"
    t.boolean "for_sale", default: true, null: false
    t.boolean "for_rent", default: true, null: false
    t.string "description", limit: 500, collation: "utf8mb3_general_ci"
    t.text "long_description", collation: "utf8mb3_general_ci"
    t.text "product_restrictions", collation: "utf8mb3_general_ci"
    t.boolean "smoking", default: false, null: false
    t.boolean "pets", default: false, null: false
    t.boolean "owner_occupied", default: false, null: false
    t.boolean "children", default: false, null: false
    t.integer "main_image_id"
    t.integer "quantity", default: 1, null: false
    t.date "available", null: false
    t.boolean "reserved", default: false, null: false
    t.boolean "box", default: false, null: false
    t.string "stored", limit: 30, default: "Warehouse", null: false, collation: "utf8mb3_general_ci"
    t.string "status", limit: 30, default: "Available", null: false, collation: "utf8mb3_general_ci"
    t.decimal "storage_price", precision: 12, scale: 2, default: "0.25"
    t.decimal "catalog_price", precision: 10, scale: 2
    t.decimal "sdn_cost", precision: 10, scale: 2, default: "0.0", null: false, unsigned: true
    t.decimal "income", precision: 12, scale: 2
    t.bigint "category_id"
    t.integer "store_category_id"
    t.integer "store_sub_category_id"
    t.integer "customer_id"
    t.integer "supplier_id"
    t.decimal "depth", precision: 10, scale: 2, default: "0.0"
    t.decimal "width", precision: 10, scale: 2, default: "0.0"
    t.decimal "height", precision: 10, scale: 2, default: "0.0"
    t.decimal "weight", precision: 10, scale: 2
    t.decimal "rent_per_day", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "rent_per_month", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "sale_price", precision: 12, scale: 2
    t.decimal "rental_value", precision: 10, scale: 2
    t.decimal "preferred_price", precision: 10, scale: 2
    t.decimal "executive_price", precision: 10, scale: 2
    t.decimal "list_price", precision: 10, scale: 2
    t.string "warranty_file", limit: 150, collation: "utf8mb3_general_ci"
    t.string "return_policy_file", limit: 250, collation: "utf8mb3_general_ci"
    t.string "estimated_ship_date", limit: 250, collation: "utf8mb3_general_ci"
    t.string "freight_ship_time", limit: 100, collation: "utf8mb3_general_ci"
    t.string "delivery_method", limit: 100, collation: "utf8mb3_general_ci"
    t.decimal "delivery_surcharge", precision: 10, scale: 2
    t.integer "action_required", limit: 1
    t.string "action_required_reason", limit: 250, collation: "utf8mb3_general_ci"
    t.datetime "added_to_cart", precision: nil
    t.string "meta_title", limit: 200, collation: "utf8mb3_general_ci"
    t.string "meta_keywords", limit: 500, collation: "utf8mb3_general_ci"
    t.string "meta_description", limit: 1000, collation: "utf8mb3_general_ci"
    t.datetime "created", precision: nil, null: false
    t.string "created_by", limit: 20, collation: "utf8mb3_general_ci"
    t.text "delete_reason", collation: "utf8mb3_general_ci"
    t.string "manufacture_name", limit: 32, default: "", null: false, collation: "utf8mb3_general_ci"
    t.string "manufacture_number", limit: 32, default: "", null: false, collation: "utf8mb3_general_ci"
    t.decimal "deacq_price", precision: 10, scale: 2, default: "0.0", null: false, unsigned: true
    t.string "initials", limit: 8, default: "", null: false, collation: "utf8mb3_general_ci"
    t.date "deacq_date"
    t.text "reserve_reason", null: false, collation: "utf8mb3_general_ci"
    t.integer "bin_id"
    t.integer "site_id"
    t.string "SKU", collation: "utf8mb3_general_ci"
    t.integer "offer_id"
  end

  create_table "project_walk_throughs", id: :integer, charset: "latin1", force: :cascade do |t|
    t.text "step1"
    t.text "step2"
    t.text "step3"
    t.text "step4"
    t.text "step5"
    t.text "step6"
    t.text "step7"
    t.text "step8"
    t.text "step9"
    t.text "step10"
    t.integer "order_id", null: false
    t.text "step11"
    t.text "step12"
    t.text "step13"
    t.text "step14"
    t.text "step15"
    t.text "step16"
    t.text "step17"
  end

  create_table "projects", id: :integer, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "order_id"
    t.integer "user_id"
    t.date "date"
    t.string "project_name"
    t.string "image_url"
    t.date "stage_date"
    t.date "destage_date"
    t.string "project_type"
    t.string "rss_contact"
    t.string "source"
    t.string "owner_name_surname"
    t.string "owner_phone_number", limit: 20
    t.string "owner_email"
    t.string "realtor_name"
    t.string "realtor_phone", limit: 20
    t.string "realtor_email"
    t.string "referal_code", limit: 100
    t.text "home_address"
    t.string "zip_code", limit: 20
    t.integer "sqft_of_home"
    t.string "rooms_to_stage"
    t.decimal "budget", precision: 10, scale: 2
    t.date "walkthrough_date"
    t.time "walkthrough_time"
    t.text "hear_about_us"
    t.text "comments"
    t.string "design_style"
    t.text "design_notes"
    t.text "furniture_amendments"
    t.text "access_info"
    t.string "billing_name"
    t.string "billing_surname"
    t.string "billing_email"
    t.time "pull_time"
    t.decimal "consult_fee", precision: 10, scale: 2
    t.decimal "design_fee", precision: 10, scale: 2
    t.decimal "rental_fee", precision: 10, scale: 2
    t.decimal "rental_tax", precision: 10, scale: 2
    t.decimal "total_billed", precision: 10, scale: 2
    t.text "payment_notes"
    t.string "rental_responsibility"
    t.decimal "consult_only_fee", precision: 10, scale: 2
    t.string "consult_name"
    t.string "consult_email"
    t.decimal "move_model_fee", precision: 10, scale: 2
    t.date "move_model_date"
    t.text "deny_reason"
    t.boolean "split_pandadoc_document", default: false
    t.boolean "design_paid", default: false
    t.boolean "rental_paid", default: false
    t.boolean "bid_denied", default: false
    t.boolean "houseamp", default: false
    t.boolean "redfin", default: false
    t.boolean "project_declined", default: false
    t.boolean "walkthrough_completed", default: false
    t.boolean "full_upfront_payment", default: false
    t.text "add_ons"
    t.datetime "created_at", precision: nil
  end

  create_table "promo_codes", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "active", limit: 10, null: false
    t.string "promo_code", limit: 50, null: false
    t.string "promo_type", limit: 15, null: false
    t.string "order_type", limit: 20, null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "discount_type", limit: 1, null: false
    t.string "uses", limit: 10, null: false
    t.decimal "minimum_order_value", precision: 10, scale: 2, null: false
    t.datetime "valid_from", precision: nil
    t.datetime "valid_to", precision: nil
    t.datetime "created", precision: nil, null: false
    t.string "created_by", limit: 40, null: false
    t.string "created_with", limit: 50, null: false
    t.datetime "edited", precision: nil, null: false
    t.string "edited_by", limit: 40, null: false
    t.string "edited_with", limit: 50, null: false
  end

  create_table "ratings", id: :integer, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "order_id"
    t.integer "user_id"
    t.integer "product_id"
    t.integer "review_star"
  end

  create_table "refund_log", id: { type: :integer, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "payment_id", null: false, unsigned: true
    t.integer "line_id", null: false, unsigned: true
    t.float "amount", null: false, unsigned: true
    t.column "type", "enum('Order','Membership','Fees','Others')", default: "Order", null: false
    t.integer "refunded_by", null: false, unsigned: true
    t.text "description", null: false
    t.column "status", "enum('OK','REJECTED')", default: "OK", null: false
    t.timestamp "timestamp", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "refund_payment_id"
    t.string "reason", limit: 100
    t.string "reason_description", limit: 300
    t.index ["line_id"], name: "line_id"
  end

  create_table "reseller_licenses", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "status", limit: 10, null: false
    t.string "file", limit: 200
    t.datetime "approved_date", precision: nil
    t.datetime "inactive_date", precision: nil
    t.datetime "created", precision: nil, null: false
    t.string "created_by", limit: 40, null: false
    t.string "created_with", limit: 50, null: false
    t.datetime "edited", precision: nil, null: false
    t.string "edited_by", limit: 40, null: false
    t.string "edited_with", limit: 50, null: false
    t.index ["user_id"], name: "user_id"
  end

  create_table "role_permissions", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "role_id", null: false
    t.integer "module_id", null: false
    t.boolean "can_open", null: false
    t.boolean "can_edit", null: false
    t.boolean "can_add", null: false
    t.boolean "can_delete", null: false
    t.index ["role_id", "module_id"], name: "security_group_id"
  end

  create_table "roles", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "role", limit: 30, null: false
  end

  create_table "roles_administered", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "role_id", null: false
    t.integer "role_administered_id", null: false
  end

  create_table "room", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "room", limit: 30, null: false
    t.integer "user_id", null: false
  end

  create_table "room_products", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "room_id", null: false
    t.integer "product_id", null: false
  end

  create_table "rooms", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "name", limit: 64, null: false
    t.column "zone", "enum('NULL','Bathroom','Bedroom','Dining Room','Extra Room','Kitchen','Living Room','Office','Outside')", null: false
    t.string "token", limit: 16, null: false
    t.integer "user_id", default: 0, null: false
    t.integer "position", default: 0
    t.index ["token"], name: "token"
    t.index ["zone"], name: "zone"
  end

  create_table "sdn_order_arrivy_task", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "order_id", null: false
    t.bigint "arrivy_task_id", null: false
    t.bigint "arrivy_customer_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.datetime "task_rescheduled_date", precision: nil
    t.datetime "start_datetime", precision: nil
    t.datetime "end_datetime", precision: nil
    t.bigint "arrivy_destage_task_id", unsigned: true
  end

  create_table "search_bar_type", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "page_id", null: false
    t.string "search_type", limit: 30, null: false
  end

  create_table "service_areas", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "service_id", null: false
    t.string "area", limit: 100, null: false
    t.integer "service_country_id"
    t.integer "service_country_state_id"
    t.integer "service_country_state_city_id"
  end

  create_table "service_awards", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "service_id", null: false
    t.string "award", limit: 100, null: false
  end

  create_table "service_categories", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "service_category", limit: 50, null: false
    t.string "active", limit: 10, default: "Active", null: false
    t.integer "suggested", default: 0
    t.integer "sequence", default: 2, null: false
  end

  create_table "service_countries", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "country", limit: 20, null: false
    t.string "active", limit: 10, null: false
  end

  create_table "service_country_state_cities", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "service_country_state_id", null: false
    t.string "city", limit: 40, null: false
    t.string "active", limit: 10, null: false
    t.index ["service_country_state_id"], name: "service_country_state_id"
  end

  create_table "service_country_states", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "service_country_id", null: false
    t.string "state", limit: 40, null: false
    t.string "active", limit: 10, null: false
    t.index ["service_country_id"], name: "service_country_id"
  end

  create_table "service_images", id: false, charset: "utf8mb3", force: :cascade do |t|
    t.integer "id", null: false, auto_increment: true
    t.integer "image_id", null: false
    t.integer "service_id", null: false
    t.boolean "main_image", default: false, null: false
    t.integer "image_order", null: false
    t.index ["id"], name: "id", unique: true
  end

  create_table "services", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "active", limit: 10, default: "Active", null: false
    t.string "status", limit: 40, default: "Open", null: false
    t.string "service", limit: 30
    t.string "first_name", limit: 30, null: false
    t.string "last_name", limit: 30, null: false
    t.string "logo_path", limit: 50
    t.integer "logo_width"
    t.integer "logo_height"
    t.text "description", null: false
    t.string "company_name", limit: 45, null: false
    t.string "office", limit: 20, null: false
    t.string "fax", limit: 20, null: false
    t.string "direct", limit: 20, null: false
    t.integer "experience", limit: 1, null: false
    t.integer "service_category_id", null: false
    t.string "mobile", limit: 20, null: false
    t.string "website", limit: 40, null: false
    t.string "email", limit: 40, null: false
    t.integer "address_id", null: false
    t.integer "years_experience", default: 1, null: false
    t.string "licensed", limit: 5, default: "No", null: false
    t.string "bonded", limit: 5, default: "No", null: false
    t.datetime "created", precision: nil, null: false
  end

  create_table "sessions", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "user_id", null: false
    t.text "cart"
    t.text "returns"
    t.text "terminations"
    t.datetime "modified", precision: nil, null: false
    t.index ["user_id", "modified"], name: "user_id"
  end

  create_table "shipping_approval_codes", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "site_id", null: false
    t.string "active", limit: 10, null: false
    t.string "code", limit: 20, null: false
    t.string "type", limit: 20, null: false
    t.decimal "service_charge", precision: 10, scale: 2, null: false
    t.decimal "unload_charge", precision: 10, scale: 2, null: false
    t.datetime "approved_date", precision: nil
    t.datetime "created", precision: nil, null: false
    t.integer "created_by", null: false
    t.string "created_with", limit: 50, null: false
    t.datetime "edited", precision: nil, null: false
    t.integer "edited_by", null: false
    t.string "edited_with", limit: 50, null: false
    t.index ["code"], name: "code", unique: true
  end

  create_table "signatures", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "order_id", null: false, unsigned: true
    t.text "signature", null: false
    t.column "status", "enum('ACTIVE','INACTIVE')", default: "ACTIVE", null: false
    t.timestamp "timestamp", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "destage_signature"
    t.column "destate_status", "enum('ACTIVE','INACTIVE')"
    t.timestamp "destage_timestamp", null: false
  end

  create_table "site_bins", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "site_id", null: false
    t.string "active", limit: 10, null: false
    t.string "bin", limit: 20, null: false
    t.integer "default_bin", limit: 1, default: 0, null: false
    t.boolean "show_on_frontend", default: true
    t.integer "default_pick_bin", limit: 1, default: 0, null: false
    t.integer "default_will_call_bin", limit: 1, default: 0, null: false
    t.index ["site_id"], name: "site_id"
  end

  create_table "site_zone_zipcodes", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "active", limit: 10, null: false
    t.integer "site_zone_id", null: false
    t.integer "zipcode", null: false
  end

  create_table "site_zones", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "site_id", null: false
    t.string "active", limit: 10, null: false
    t.string "zone", limit: 20, null: false
    t.decimal "service_charge", precision: 10, scale: 2, null: false
    t.decimal "unload_charge", precision: 10, scale: 2, null: false
  end

  create_table "sites", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "active", limit: 10
    t.string "site", limit: 20, null: false
    t.integer "location_id", default: 0, null: false
    t.integer "default_address_id"
    t.integer "default_contact_id"
    t.integer "receive_bin_id"
    t.integer "pick_bin_id"
    t.integer "will_call_bin_id"
    t.integer "tax_authority_id", null: false
    t.string "type", limit: 30, default: "Site", null: false
    t.string "email", limit: 100
    t.timestamp "created", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "created_by", limit: 50, null: false
    t.string "created_with", limit: 50, null: false
    t.datetime "edited", precision: nil, null: false
    t.string "edited_by", limit: 50, null: false
    t.string "edited_with", limit: 50, null: false
    t.string "market", limit: 3
    t.string "color"
    t.index ["tax_authority_id"], name: "tax_authority_id"
  end

  create_table "special_offers", id: :integer, charset: "latin1", force: :cascade do |t|
    t.string "offer_name", null: false
    t.column "active", "enum('active','inactive')", default: "active"
  end

  create_table "staging_insurance_proof", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "file", limit: 30, null: false
    t.string "status", limit: 30, default: "Requested", null: false
    t.datetime "expires_on", precision: nil
  end

  create_table "staging_insurance_requests", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "first_name", limit: 30, null: false
    t.string "last_name", limit: 30, null: false
    t.string "company_name", limit: 50, null: false
    t.string "status", limit: 15, default: "Requested", null: false
    t.integer "address_id"
    t.integer "user_id", null: false
    t.datetime "start_date", precision: nil
    t.datetime "end_date", precision: nil
    t.decimal "price", precision: 10, scale: 2
  end

  create_table "stat_customer", id: { type: :integer, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "customer_id", null: false, unsigned: true
    t.datetime "date", precision: nil, null: false
    t.date "period", null: false
    t.float "amount", null: false
    t.column "type", "enum('FEE','RENTAL','SALE','MEMBERSHIP')", null: false
    t.integer "location_id", limit: 2, null: false, unsigned: true
    t.index ["id"], name: "id"
  end

  create_table "states", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "abbreviation", limit: 2
    t.string "state", limit: 50
    t.index ["abbreviation"], name: "abbreviation"
  end

  create_table "storage_fee", id: { type: :integer, limit: 2, unsigned: true }, charset: "latin1", force: :cascade do |t|
    t.float "value", null: false
    t.timestamp "timestamp", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "sub_categories", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "category_id", null: false
    t.string "sub_category", limit: 30, null: false
    t.string "token", limit: 50
    t.string "active", limit: 10, null: false
    t.index ["token"], name: "token"
  end

  create_table "subattributes", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "attribute_id", null: false
    t.string "subattribute", limit: 30, null: false
    t.string "token", limit: 50
    t.decimal "storage_price", precision: 10, scale: 2, default: "0.25", null: false
    t.decimal "catalog_price", precision: 10, scale: 2
    t.string "active", limit: 10, null: false
    t.string "search_group", limit: 50
    t.index ["attribute_id"], name: "attribute_id"
    t.index ["search_group"], name: "search_group"
    t.index ["token"], name: "token"
  end

  create_table "subscriptions", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "first_name", limit: 20
    t.string "last_name", limit: 20
    t.string "email", limit: 50, null: false
    t.string "phone", limit: 20
    t.string "time_for_contact", limit: 50, null: false
    t.string "contact_method", limit: 50, null: false
    t.decimal "current_storage_costs", precision: 10, scale: 2
    t.decimal "current_delivery_costs", precision: 10, scale: 2
    t.string "table_name", limit: 40
    t.integer "table_id"
    t.datetime "subscription_date", precision: nil, null: false
  end

  create_table "tax_authorities", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "description", limit: 100, null: false
    t.string "active", limit: 10, null: false
    t.string "entry_mode", limit: 10, default: "Manual", null: false
    t.string "state_authority", limit: 40, null: false
    t.decimal "state_rate", precision: 10, scale: 7, null: false
    t.string "county_authority", limit: 40
    t.decimal "county_rate", precision: 10, scale: 7
    t.string "city_authority", limit: 40
    t.decimal "city_rate", precision: 10, scale: 7
    t.string "special_authority", limit: 40
    t.decimal "special_rate", precision: 10, scale: 7
    t.datetime "created", precision: nil, null: false
    t.string "created_by", limit: 40, null: false
    t.string "created_with", limit: 50, null: false
    t.datetime "edited", precision: nil, null: false
    t.string "edited_by", limit: 40, null: false
    t.string "edited_with", limit: 50, null: false
    t.string "transaction_id", limit: 15
    t.string "transaction_code", limit: 45
    t.decimal "total_rate", precision: 10, scale: 7
    t.string "tax_rate_source", limit: 25
    t.string "transaction_status", limit: 50
    t.index ["active"], name: "active"
  end

  create_table "tax_authorities_bak", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "description", limit: 100, null: false
    t.string "active", limit: 10, null: false
    t.string "entry_mode", limit: 10, default: "Manual", null: false
    t.string "state_authority", limit: 40, null: false
    t.decimal "state_rate", precision: 10, scale: 3, null: false
    t.string "county_authority", limit: 40
    t.decimal "county_rate", precision: 10, scale: 3
    t.string "city_authority", limit: 40
    t.decimal "city_rate", precision: 10, scale: 3
    t.string "special_authority", limit: 40
    t.decimal "special_rate", precision: 10, scale: 3
    t.datetime "created", precision: nil, null: false
    t.string "created_by", limit: 40, null: false
    t.string "created_with", limit: 50, null: false
    t.datetime "edited", precision: nil, null: false
    t.string "edited_by", limit: 40, null: false
    t.string "edited_with", limit: 50, null: false
    t.string "transaction_id", limit: 15
    t.string "transaction_code", limit: 45
    t.decimal "total_rate", precision: 10, scale: 3
    t.string "tax_rate_source", limit: 25
    t.string "transaction_status", limit: 50
    t.index ["active"], name: "active"
  end

  create_table "tbl_profiles", primary_key: "user_id", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "firstname", limit: 50, default: "", null: false
    t.string "lastname", limit: 50, default: "", null: false
    t.string "phone", limit: 100, null: false
    t.string "avatar_img", limit: 100
    t.integer "user_group", default: 0, null: false, comment: "1 for PLATINUM, 2 for GOLD, 3 for EMERALD"
    t.string "address", limit: 100, null: false
    t.string "city", limit: 50, null: false
    t.string "state", limit: 50, null: false
    t.integer "zip", null: false
  end

  create_table "tbl_users", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "login", limit: 30
    t.string "password", limit: 128, null: false
    t.string "email", limit: 128, null: false
    t.string "activkey", limit: 128, default: "", null: false
    t.datetime "create_at", precision: nil, null: false
    t.datetime "lastvisit_at", precision: nil, null: false
    t.boolean "status", default: false, null: false
    t.string "token"
    t.index ["email"], name: "email", unique: true
    t.index ["status"], name: "status"
  end

  create_table "transaction_details", id: { type: :integer, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.text "details"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "transaction_id", null: false, unsigned: true
    t.index ["transaction_id"], name: "index_transaction_details_transaction"
  end

  create_table "transactions", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "response", limit: 20, null: false
    t.string "failure_reason", limit: 200
    t.string "table_name", limit: 40, null: false
    t.integer "table_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.decimal "tax", precision: 10, scale: 2
    t.string "type", limit: 20, null: false
    t.string "check_number", limit: 20
    t.datetime "check_date", precision: nil
    t.string "check_note", limit: 250
    t.string "cc_last_four", limit: 4
    t.string "transaction_number", limit: 50
    t.string "authorization_code", limit: 20
    t.datetime "transaction_date", precision: nil, null: false
    t.string "processed_by", limit: 40, null: false
    t.string "processed_with", limit: 50, null: false
    t.integer "refunded_transaction_id"
    t.integer "stored_card_id"
    t.index ["authorization_code"], name: "authorization_code"
    t.index ["transaction_number"], name: "transaction_number"
  end

  create_table "trucks", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "name", limit: 45, null: false
    t.string "color", limit: 45, null: false
    t.index ["color"], name: "color_UNIQUE", unique: true
    t.index ["name"], name: "name_UNIQUE", unique: true
  end

  create_table "user_authentication", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "auth_code", limit: 40, null: false
    t.timestamp "created", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "logged_in_as", unsigned: true
  end

  create_table "user_credentials", id: { type: :integer, unsigned: true }, charset: "latin1", force: :cascade do |t|
    t.integer "user_id", null: false, unsigned: true
    t.column "credential_type", "enum('Business License','Resale License','Brochure','Business Card','Other')", null: false
    t.string "other", limit: 64, null: false
    t.string "busines_license_info", limit: 64, null: false
    t.string "ubi", limit: 64, null: false
    t.date "expiration_date", null: false
    t.string "state_incorp", limit: 2, null: false
    t.string "insured_name", limit: 64, null: false
    t.string "insurance_company", limit: 64, null: false
    t.string "policy_number", limit: 64, null: false
    t.date "poi_expiration_date", null: false
    t.string "certificate_number", limit: 64, null: false
    t.string "state", limit: 2, null: false
    t.date "soi_expiration_date", null: false
    t.index ["user_id"], name: "user_id", unique: true
  end

  create_table "user_groups", id: :integer, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "group_name", limit: 50, null: false
    t.decimal "discount_percentage", precision: 5, scale: 2, default: "0.0"
    t.text "description"
    t.string "active", limit: 10, default: "active"
    t.timestamp "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.timestamp "updated_at", default: -> { "CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP" }, null: false
  end

  create_table "user_impersonation_logs", id: { type: :integer, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "admin_id", null: false
    t.integer "user_id", null: false
    t.datetime "started_at", precision: nil
    t.datetime "ended_at", precision: nil
  end

  create_table "user_login_log", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "email", limit: 50, null: false
    t.string "password", null: false
    t.text "user_auth"
    t.datetime "login_date", precision: nil, null: false
  end

  create_table "user_membership_levels", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "membership_level_id", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.integer "term_length", default: 1, null: false
    t.datetime "start_date", precision: nil, null: false
    t.string "created_by", limit: 40, null: false
    t.string "created_with", limit: 50, null: false
    t.index ["membership_level_id"], name: "membership_level_id"
    t.index ["user_id"], name: "user_id"
  end

  create_table "user_membership_proofs", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "action", limit: 15, default: "Registration", null: false
    t.string "file", limit: 500, null: false
    t.string "status", limit: 10, null: false
    t.decimal "price", precision: 10, scale: 2, default: "39.99"
    t.integer "term_length", default: 1, null: false
    t.text "promo"
    t.datetime "approved_date", precision: nil
    t.datetime "inactive_date", precision: nil
    t.datetime "created", precision: nil, null: false
    t.string "created_by", limit: 40, null: false
    t.datetime "edited", precision: nil, null: false
    t.string "edited_by", limit: 40, null: false
    t.index ["user_id"], name: "user_id"
  end

  create_table "user_messages", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "from_user_id", limit: 11
    t.string "from_email", limit: 100
    t.integer "to_user_id", null: false
    t.string "title", limit: 50, null: false
    t.text "message", null: false
    t.datetime "sent_on", precision: nil, null: false
    t.integer "read_by_user", limit: 1, default: 0, null: false
    t.integer "replied", limit: 1, default: 0, null: false
  end

  create_table "user_permission_assignments", id: { type: :integer, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "user_permission_id", null: false
    t.integer "site_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id", "user_permission_id", "site_id"], name: "unique_user_permission_assignments_uniqueness", unique: true
  end

  create_table "user_permissions", id: { type: :integer, unsigned: true }, charset: "utf8mb3", force: :cascade do |t|
    t.string "name", limit: 50
    t.string "label", limit: 50
    t.string "description"
    t.integer "parent_id"
    t.index ["name"], name: "index_user_permissions_name"
    t.index ["name"], name: "unique_user_permissions_name", unique: true
  end

  create_table "user_roles", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "role_id", null: false
  end

  create_table "user_tasks", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "batch", null: false
    t.integer "role_id"
    t.integer "user_id", null: false
    t.integer "task_id", null: false
    t.date "due_date"
    t.date "handled_date"
    t.string "status", limit: 15
    t.text "note"
    t.index ["batch"], name: "batch"
    t.index ["role_id"], name: "role_id"
  end

  create_table "user_wishlist", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "product_id", null: false
    t.index ["user_id", "product_id"], name: "UK_user_wishlist_091921", unique: true
  end

  create_table "user_wishlist_old", id: :integer, charset: "utf8mb3", options: "ENGINE=InnoDB AVG_ROW_LENGTH=44", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "product_id", null: false
  end

  create_table "users", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.column "active", "enum('Active','Inactive')", null: false
    t.column "user_type", "enum('Customer','Employee','IDS','Concierge')", null: false
    t.string "original_role"
    t.integer "linked_to_id"
    t.string "email", limit: 50, null: false
    t.string "username", limit: 50
    t.string "password"
    t.text "user_auth"
    t.string "first_name", limit: 20
    t.string "last_name", limit: 20
    t.string "profile_name", limit: 30
    t.string "bio", limit: 140
    t.string "company_name", limit: 50
    t.string "membership_level", limit: 30, default: "Member", null: false
    t.integer "membership_level_id", default: 6
    t.integer "shipping_address_id"
    t.integer "billing_address_id"
    t.string "telephone", limit: 20
    t.string "mobile", limit: 20
    t.string "picture", limit: 50
    t.integer "credit_card_id"
    t.integer "service_id"
    t.string "email_task", limit: 5
    t.integer "agree_to_terms", limit: 1
    t.integer "pulled_credit", limit: 1, null: false
    t.datetime "join_date", precision: nil, null: false
    t.string "logo_path", limit: 250
    t.integer "logo_width"
    t.integer "logo_height"
    t.integer "site_id"
    t.string "hear_about", limit: 45
    t.string "hear_about_other", limit: 45
    t.string "mobile_username", limit: 45
    t.string "mobile_password", limit: 70
    t.string "location_rights", null: false
    t.integer "sales_rep", unsigned: true
    t.integer "designer", unsigned: true
    t.string "occupation", limit: 64
    t.string "source", limit: 30
    t.string "billing_email", limit: 50
    t.boolean "is_signup_complete", default: false, null: false
    t.bigint "arrivy_customer_id", unsigned: true
    t.bigint "arrivy_entity_id"
    t.string "stripe_customer_id"
    t.string "encrypted_password"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "group_id"
    t.integer "owner_id"
    t.index ["site_id"], name: "fk_sdn_users_sites"
  end

  create_table "utilization_report_data", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "product_id", null: false, unsigned: true
    t.integer "type_id", unsigned: true
    t.integer "subtype_id", unsigned: true
    t.integer "owner_id", unsigned: true
    t.integer "membership_type_id", unsigned: true
    t.integer "days_in_system"
    t.integer "days_rented"
    t.integer "days_on_reserve"
    t.string "manufacturer", limit: 50
    t.string "manufacturer_number", limit: 50
    t.datetime "date_updated", precision: nil, null: false
    t.datetime "first_date_in_system", precision: nil
    t.datetime "last_date_in_system", precision: nil
    t.decimal "utilization", precision: 10, scale: 5
  end

  create_table "yuxi_categories", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "name", limit: 40, null: false
    t.integer "parentid"
    t.integer "order", limit: 1, default: 1, null: false, unsigned: true
    t.column "active", "enum('active','inactive')", null: false
    t.integer "site_id", default: 26, null: false
    t.index ["parentid"], name: "parentid_fk"
  end

  create_table "yuxi_options", id: { type: :integer, limit: 2 }, charset: "utf8mb3", force: :cascade do |t|
    t.string "tag"
    t.string "label", limit: 50, null: false
    t.column "active", "enum('active','inactive')", null: false
  end

  create_table "yuxi_products", primary_key: "product_id", id: { type: :bigint, unsigned: true, default: nil }, charset: "latin1", force: :cascade do |t|
    t.integer "category_id", limit: 2, null: false, unsigned: true
    t.string "material_id"
    t.string "color_id"
    t.string "fabric_id"
    t.string "texture_id"
    t.string "size_id"
    t.boolean "is_premium", default: false, null: false
    t.boolean "discount_rental", default: false
    t.boolean "sales_item", default: false
    t.boolean "closeout", default: false
    t.string "style_id"
    t.index ["product_id"], name: "product_id", unique: true
  end

  create_table "yuxi_products_backup_20241010", id: false, charset: "latin1", force: :cascade do |t|
    t.bigint "product_id", null: false, unsigned: true
    t.integer "category_id", limit: 2, null: false, unsigned: true
    t.integer "material_id", limit: 2, unsigned: true
    t.integer "color_id", limit: 2, unsigned: true
    t.integer "fabric_id", limit: 2, unsigned: true
    t.integer "texture_id", limit: 2, unsigned: true
    t.integer "size_id", limit: 2, null: false, unsigned: true
    t.boolean "is_premium", default: false, null: false
    t.boolean "discount_rental", default: false
    t.boolean "sales_item", default: false
    t.boolean "closeout", default: false
  end

  create_table "zipcodes", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "zipcode", null: false
    t.string "city", limit: 32, null: false
    t.string "state", limit: 2, null: false
    t.float "latitude", limit: 53, null: false
    t.float "longitude", limit: 53, null: false
    t.integer "timezone", null: false
    t.boolean "daysaving", null: false
    t.index ["state"], name: "state"
    t.index ["zipcode"], name: "zipcode", unique: true
  end

  create_table "zipcoverage", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "site_id", null: false
    t.integer "zipcode", limit: 3, null: false
    t.string "city", limit: 64, null: false
    t.integer "city_id", null: false, unsigned: true
    t.index ["city_id"], name: "cities_id"
    t.index ["zipcode"], name: "zipcode", unique: true
  end

  add_foreign_key "cycle_count_bins_product_pieces", "cycle_count_bins", column: "cycle_count_bins_id", name: "cycle_count_bins_product_pieces_ibfk_3", on_update: :cascade, on_delete: :cascade
  add_foreign_key "cycle_count_bins_product_pieces", "product_pieces", name: "cycle_count_bins_product_pieces_ibfk_4", on_update: :cascade, on_delete: :cascade
  add_foreign_key "cycle_count_bins_scan_product_pieces", "cycle_count_bins", column: "cycle_count_bins_id", name: "cycle_count_bins_scan_product_pieces_ibfk_4", on_update: :cascade, on_delete: :cascade
  add_foreign_key "cycle_count_bins_scan_product_pieces", "product_pieces", name: "cycle_count_bins_scan_product_pieces_ibfk_5", on_update: :cascade, on_delete: :cascade
  add_foreign_key "cycle_count_bins_scan_product_pieces", "users", name: "cycle_count_bins_scan_product_pieces_ibfk_6", on_update: :cascade, on_delete: :cascade
  add_foreign_key "cycle_counts", "sites", column: "sites_id", name: "cycle_counts_ibfk_1"
  add_foreign_key "deliveries", "orders", column: "orders_id", name: "deliveries_ibfk_1", on_update: :cascade, on_delete: :cascade
  add_foreign_key "deliveries", "trucks", column: "trucks_id", name: "deliveries_ibfk_2", on_update: :cascade, on_delete: :cascade
  add_foreign_key "deliveries", "users", column: "users_id", name: "deliveries_ibfk_3", on_update: :cascade, on_delete: :cascade
  add_foreign_key "deliveries_history", "orders", column: "orders_id", name: "deliveries_history_ibfk_1", on_update: :cascade, on_delete: :cascade
  add_foreign_key "deliveries_history", "trucks", column: "trucks_id", name: "deliveries_history_ibfk_2", on_update: :cascade, on_delete: :cascade
  add_foreign_key "deliveries_history", "users", column: "users_id", name: "deliveries_history_ibfk_3", on_update: :cascade, on_delete: :cascade
  add_foreign_key "order_lines", "floors", name: "order_lines_ibfk_2"
  add_foreign_key "order_lines", "rooms", name: "order_lines_ibfk_1"
  add_foreign_key "order_status_signatures", "orders", name: "fk_order", on_delete: :cascade
end
