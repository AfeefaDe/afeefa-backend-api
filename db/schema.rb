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

ActiveRecord::Schema.define(version: 20170920100635) do

  create_table "annotation_categories", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "title",               limit: 1000
    t.boolean  "generated_by_system",              default: false, null: false
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
  end

  create_table "annotations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "annotation_category_id"
    t.string  "entry_type"
    t.integer "entry_id"
    t.text    "detail",                 limit: 65535
    t.index ["annotation_category_id"], name: "index_annotations_on_annotation_category_id", using: :btree
    t.index ["entry_type", "entry_id"], name: "index_annotations_on_entry_type_and_entry_id", using: :btree
  end

  create_table "categories", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "title",      limit: 1000
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.integer  "parent_id"
    t.string   "area",                    default: "dresden"
    t.index ["parent_id"], name: "index_annotations_on_entry_type_and_entry_id", using: :btree
  end

  create_table "contact_infos", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "contactable_type"
    t.integer  "contactable_id"
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
    t.string   "mail",               limit: 1000
    t.string   "phone"
    t.string   "contact_person",     limit: 1000
    t.string   "web",                limit: 1000
    t.string   "social_media",       limit: 1000
    t.string   "spoken_languages",   limit: 1000
    t.boolean  "migrated_from_neos",               default: false
    t.text     "opening_hours",      limit: 65535
    t.string   "fax"
    t.index ["contactable_type", "contactable_id"], name: "index_contact_infos_on_contactable_type_and_contactable_id", using: :btree
  end

  create_table "entries", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string  "entry_type"
    t.integer "entry_id"
    t.index ["entry_type", "entry_id"], name: "index_entries_on_entry_type_and_entry_id", using: :btree
  end

  create_table "events", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "title",                 limit: 1000
    t.text     "description",           limit: 65535
    t.text     "short_description",     limit: 65535
    t.string   "public_speaker",        limit: 1000
    t.string   "location_type"
    t.boolean  "support_wanted"
    t.string   "support_wanted_detail", limit: 1000
    t.integer  "creator_id"
    t.datetime "created_at",                                          null: false
    t.datetime "updated_at",                                          null: false
    t.integer  "parent_event_id"
    t.integer  "orga_id"
    t.datetime "date_start"
    t.string   "state"
    t.datetime "state_changed_at"
    t.integer  "category_id"
    t.integer  "sub_category_id"
    t.datetime "date_end"
    t.boolean  "time_start",                          default: false
    t.boolean  "time_end",                            default: false
    t.string   "media_url",             limit: 1000
    t.string   "media_type"
    t.boolean  "for_children"
    t.boolean  "certified_sfr"
    t.string   "legacy_entry_id"
    t.boolean  "migrated_from_neos",                  default: false
    t.string   "tags",                  limit: 1000
    t.string   "inheritance"
    t.string   "area",                  limit: 1000
    t.index ["category_id"], name: "index_events_on_category_id", using: :btree
    t.index ["orga_id"], name: "index_events_on_orga_id", using: :btree
    t.index ["sub_category_id"], name: "index_events_on_sub_category_id", using: :btree
  end

  create_table "locations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "lat",                limit: 1000
    t.string   "lon",                limit: 1000
    t.string   "street",             limit: 1000
    t.string   "placename",          limit: 1000
    t.string   "zip"
    t.string   "city",               limit: 1000
    t.string   "district",           limit: 1000
    t.string   "state"
    t.string   "country",            limit: 1000
    t.boolean  "displayed"
    t.string   "locatable_type"
    t.integer  "locatable_id"
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.boolean  "migrated_from_neos",              default: false
    t.string   "directions",         limit: 1000
    t.index ["locatable_type", "locatable_id"], name: "index_locations_on_locatable_type_and_locatable_id", using: :btree
  end

  create_table "orga_category_relations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "category_id"
    t.integer  "orga_id"
    t.boolean  "primary"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["category_id"], name: "index_orga_category_relations_on_category_id", using: :btree
    t.index ["orga_id"], name: "index_orga_category_relations_on_orga_id", using: :btree
  end

  create_table "orgas", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.datetime "created_at",                                          null: false
    t.datetime "updated_at",                                          null: false
    t.string   "title",                 limit: 1000
    t.text     "description",           limit: 65535
    t.text     "short_description",     limit: 65535
    t.integer  "parent_orga_id"
    t.string   "state"
    t.datetime "state_changed_at"
    t.integer  "category_id"
    t.integer  "sub_category_id"
    t.string   "media_url",             limit: 1000
    t.string   "media_type"
    t.boolean  "support_wanted"
    t.string   "support_wanted_detail", limit: 1000
    t.boolean  "for_children"
    t.boolean  "certified_sfr"
    t.string   "legacy_entry_id"
    t.boolean  "migrated_from_neos",                  default: false
    t.string   "tags",                  limit: 1000
    t.string   "inheritance"
    t.string   "area",                  limit: 1000
    t.index ["category_id"], name: "index_orgas_on_category_id", using: :btree
    t.index ["sub_category_id"], name: "index_orgas_on_sub_category_id", using: :btree
  end

  create_table "owner_thing_relations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "ownable_type"
    t.integer  "ownable_id"
    t.string   "thingable_type"
    t.integer  "thingable_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.index ["ownable_type", "ownable_id"], name: "index_owner_thing_relations_on_ownable_type_and_ownable_id", using: :btree
    t.index ["thingable_type", "thingable_id"], name: "index_owner_thing_relations_on_thingable_type_and_thingable_id", using: :btree
  end

  create_table "roles", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "title",      limit: 1000
    t.integer  "user_id"
    t.integer  "orga_id"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.index ["orga_id"], name: "index_roles_on_orga_id", using: :btree
    t.index ["user_id"], name: "index_roles_on_user_id", using: :btree
  end

  create_table "thing_category_relations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "category_id"
    t.string   "catable_type"
    t.integer  "catable_id"
    t.boolean  "primary"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["catable_type", "catable_id"], name: "index_thing_category_relations_on_catable_type_and_catable_id", using: :btree
    t.index ["category_id"], name: "index_thing_category_relations_on_category_id", using: :btree
  end

  create_table "translation_cache_meta_data", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "locale"
    t.datetime "locked_at"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.string   "area",       default: "dresden"
  end

  create_table "translation_caches", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "cacheable_id"
    t.string   "cacheable_type",    limit: 20
    t.string   "language",          limit: 3,     null: false
    t.string   "title",             limit: 1000
    t.text     "short_description", limit: 65535
    t.text     "description",       limit: 65535
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.index ["cacheable_id", "cacheable_type", "language"], name: "index_translation_cache", using: :btree
  end

  create_table "users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "email",                  limit: 1000,  default: "",      null: false
    t.string   "encrypted_password",     limit: 1000,  default: "",      null: false
    t.string   "reset_password_token",   limit: 1000
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                        default: 0,       null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                                             null: false
    t.datetime "updated_at",                                             null: false
    t.string   "forename",               limit: 1000
    t.string   "surname",                limit: 1000
    t.string   "provider",                             default: "email", null: false
    t.string   "uid",                                  default: "",      null: false
    t.text     "tokens",                 limit: 65535
    t.string   "area",                   limit: 1000
    t.index ["email"], name: "index_users_on_email", using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true, using: :btree
  end

end
