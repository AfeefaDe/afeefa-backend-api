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

ActiveRecord::Schema.define(version: 20161029150321) do

  create_table "categories", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string   "title"
    t.string   "type"
    t.integer  "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_categories_on_parent_id", using: :btree
  end

  create_table "contact_infos", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string  "type"
    t.string  "content"
    t.string  "contactable_type"
    t.integer "contactable_id"
    t.index ["contactable_type", "contactable_id"], name: "index_contact_infos_on_contactable_type_and_contactable_id", using: :btree
  end

  create_table "events", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string   "title"
    t.string   "description"
    t.string   "public_speaker"
    t.string   "location_type"
    t.boolean  "support_wanted"
    t.integer  "creator_id"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.integer  "parent_id"
    t.datetime "date"
    t.boolean  "active",         default: true
    t.string   "state"
    t.string   "category"
  end

  create_table "locations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string   "lat"
    t.string   "lon"
    t.string   "street"
    t.string   "number"
    t.string   "addition"
    t.string   "zip"
    t.string   "city"
    t.string   "district"
    t.string   "state"
    t.string   "country"
    t.boolean  "displayed"
    t.string   "locatable_type"
    t.integer  "locatable_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.index ["locatable_type", "locatable_id"], name: "index_locations_on_locatable_type_and_locatable_id", using: :btree
  end

  create_table "orga_category_relations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer  "category_id"
    t.integer  "orga_id"
    t.boolean  "primary"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["category_id"], name: "index_orga_category_relations_on_category_id", using: :btree
    t.index ["orga_id"], name: "index_orga_category_relations_on_orga_id", using: :btree
  end

  create_table "orgas", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.string   "title"
    t.text     "description", limit: 65535
    t.integer  "parent_id"
    t.boolean  "active",                    default: true
    t.string   "state"
    t.string   "category"
  end

  create_table "owner_thing_relations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string   "ownable_type"
    t.integer  "ownable_id"
    t.string   "thingable_type"
    t.integer  "thingable_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.index ["ownable_type", "ownable_id"], name: "index_owner_thing_relations_on_ownable_type_and_ownable_id", using: :btree
    t.index ["thingable_type", "thingable_id"], name: "index_owner_thing_relations_on_thingable_type_and_thingable_id", using: :btree
  end

  create_table "roles", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string   "title"
    t.integer  "user_id"
    t.integer  "orga_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["orga_id"], name: "index_roles_on_orga_id", using: :btree
    t.index ["user_id"], name: "index_roles_on_user_id", using: :btree
  end

  create_table "thing_category_relations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer  "category_id"
    t.string   "catable_type"
    t.integer  "catable_id"
    t.boolean  "primary"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["catable_type", "catable_id"], name: "index_thing_category_relations_on_catable_type_and_catable_id", using: :btree
    t.index ["category_id"], name: "index_thing_category_relations_on_category_id", using: :btree
  end

  create_table "users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string   "email",                                default: "",      null: false
    t.string   "encrypted_password",                   default: "",      null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                        default: 0,       null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                                             null: false
    t.datetime "updated_at",                                             null: false
    t.string   "forename"
    t.string   "surname"
    t.string   "provider",                             default: "email", null: false
    t.string   "uid",                                  default: "",      null: false
    t.text     "tokens",                 limit: 65535
    t.index ["email"], name: "index_users_on_email", using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true, using: :btree
  end

end
