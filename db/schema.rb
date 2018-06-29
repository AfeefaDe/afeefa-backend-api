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

ActiveRecord::Schema.define(version: 20180629163147) do

  create_table "actor_relations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer  "associating_actor_id"
    t.integer  "associated_actor_id"
    t.string   "type"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.index ["associated_actor_id", "type"], name: "index_actor_relations_on_associated_actor_id_and_type", using: :btree
    t.index ["associated_actor_id"], name: "index_actor_relations_on_associated_actor_id", using: :btree
    t.index ["associating_actor_id", "type"], name: "index_actor_relations_on_associating_actor_id_and_type", using: :btree
    t.index ["associating_actor_id"], name: "index_actor_relations_on_associating_actor_id", using: :btree
    t.index ["type"], name: "index_actor_relations_on_type", using: :btree
  end

  create_table "addresses", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string   "owner_type"
    t.integer  "owner_id"
    t.integer  "contact_id"
    t.string   "title"
    t.string   "street"
    t.string   "zip"
    t.string   "city"
    t.string   "lat"
    t.string   "lon"
    t.text     "directions", limit: 65535
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.index ["contact_id"], name: "index_addresses_on_contact_id", using: :btree
    t.index ["owner_type", "owner_id"], name: "index_addresses_on_owner_type_and_owner_id", using: :btree
  end

  create_table "annotation_categories", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string   "title"
    t.boolean  "generated_by_system", default: false, null: false
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  create_table "annotations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "annotation_category_id"
    t.string  "entry_type"
    t.integer "entry_id"
    t.text    "detail",                 limit: 65535
    t.index ["annotation_category_id"], name: "index_annotations_on_annotation_category_id", using: :btree
    t.index ["entry_type", "entry_id"], name: "index_annotations_on_entry_type_and_entry_id", using: :btree
  end

  create_table "area_chapter_configs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string   "area"
    t.integer  "chapter_config_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  create_table "areas", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string   "title"
    t.string   "lat_min"
    t.string   "lat_max"
    t.string   "lon_min"
    t.string   "lon_max"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["title"], name: "index_areas_on_title", unique: true, using: :btree
  end

  create_table "categories", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string   "title"
    t.integer  "parent_id"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.string   "area",       default: "dresden"
    t.index ["area"], name: "index_categories_on_area", using: :btree
    t.index ["parent_id"], name: "index_categories_on_parent_id", using: :btree
  end

  create_table "chapter_configs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer  "chapter_id"
    t.integer  "creator_id"
    t.integer  "last_modifier_id"
    t.boolean  "active"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  create_table "chapters", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string   "title",                     null: false
    t.text     "content",     limit: 65535
    t.integer  "order"
    t.string   "area"
    t.integer  "category_id"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.index ["category_id"], name: "index_chapters_on_category_id", using: :btree
  end

  create_table "contact_infos", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string   "contactable_type"
    t.integer  "contactable_id"
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
    t.string   "mail"
    t.string   "phone"
    t.string   "contact_person"
    t.string   "internal_id"
    t.string   "web",                limit: 1000
    t.string   "social_media",       limit: 1000
    t.string   "spoken_languages"
    t.boolean  "migrated_from_neos",               default: false
    t.text     "opening_hours",      limit: 65535
    t.string   "fax"
    t.index ["contactable_type", "contactable_id"], name: "index_contact_infos_on_contactable_type_and_contactable_id", using: :btree
  end

  create_table "contact_persons", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer  "contact_id"
    t.string   "name"
    t.string   "role"
    t.string   "mail"
    t.string   "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_id"], name: "index_contact_persons_on_contact_id", using: :btree
  end

  create_table "contacts", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string   "owner_type"
    t.integer  "owner_id"
    t.integer  "location_id"
    t.string   "type"
    t.string   "title"
    t.string   "web",              limit: 1000
    t.string   "social_media",     limit: 1000
    t.string   "spoken_languages"
    t.string   "fax"
    t.text     "opening_hours",    limit: 65535
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.index ["location_id"], name: "index_contacts_on_location_id", using: :btree
    t.index ["owner_type", "owner_id"], name: "index_contacts_on_owner_type_and_owner_id", using: :btree
  end

  create_table "entries", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string  "entry_type"
    t.integer "entry_id"
    t.index ["entry_type", "entry_id"], name: "index_entries_on_entry_type_and_entry_id", using: :btree
  end

  create_table "event_hosts", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer  "actor_id"
    t.integer  "event_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_event_hosts_on_actor_id", using: :btree
    t.index ["event_id"], name: "index_event_hosts_on_event_id", using: :btree
  end

  create_table "events", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string   "title"
    t.text     "description",           limit: 65535
    t.text     "short_description",     limit: 65535
    t.string   "public_speaker"
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
    t.string   "tags"
    t.string   "inheritance"
    t.string   "area"
    t.integer  "last_editor_id"
    t.string   "facebook_id"
    t.index ["area"], name: "index_events_on_area", using: :btree
    t.index ["category_id"], name: "index_events_on_category_id", using: :btree
    t.index ["creator_id"], name: "index_events_on_creator_id", using: :btree
    t.index ["last_editor_id"], name: "index_events_on_last_editor_id", using: :btree
    t.index ["orga_id"], name: "index_events_on_orga_id", using: :btree
    t.index ["sub_category_id"], name: "index_events_on_sub_category_id", using: :btree
  end

  create_table "facet_item_owners", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string   "owner_type"
    t.integer  "owner_id"
    t.integer  "facet_item_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.index ["facet_item_id"], name: "index_facet_item_owners_on_facet_item_id", using: :btree
    t.index ["owner_type", "owner_id", "facet_item_id"], name: "facet_item_owner", unique: true, using: :btree
    t.index ["owner_type", "owner_id"], name: "index_facet_item_owners_on_owner_type_and_owner_id", using: :btree
  end

  create_table "facet_items", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string   "title"
    t.string   "color"
    t.integer  "facet_id"
    t.integer  "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["facet_id"], name: "index_facet_items_on_facet_id", using: :btree
    t.index ["parent_id"], name: "index_facet_items_on_parent_id", using: :btree
  end

  create_table "facet_owner_types", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "facet_id"
    t.string  "owner_type"
    t.boolean "main_facet", default: false, null: false
    t.index ["facet_id"], name: "index_facet_owner_types_on_facet_id", using: :btree
  end

  create_table "facets", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string   "title"
    t.string   "color"
    t.boolean  "color_sub_items", default: true, null: false
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  create_table "fe_navigation_item_facet_items", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer  "facet_item_id"
    t.integer  "navigation_item_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.index ["facet_item_id"], name: "index_fe_navigation_item_facet_items_on_facet_item_id", using: :btree
    t.index ["navigation_item_id"], name: "index_fe_navigation_item_facet_items_on_navigation_item_id", using: :btree
  end

  create_table "fe_navigation_item_owners", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string   "owner_type"
    t.integer  "owner_id"
    t.integer  "navigation_item_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.index ["navigation_item_id"], name: "index_fe_navigation_item_owners_on_navigation_item_id", using: :btree
    t.index ["owner_type", "owner_id"], name: "index_fe_navigation_item_owners_on_owner_type_and_owner_id", using: :btree
  end

  create_table "fe_navigation_items", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string   "title"
    t.string   "color"
    t.integer  "navigation_id"
    t.integer  "parent_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.index ["navigation_id"], name: "index_fe_navigation_items_on_navigation_id", using: :btree
    t.index ["parent_id"], name: "index_fe_navigation_items_on_parent_id", using: :btree
  end

  create_table "fe_navigations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string   "area"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "locations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string   "lat"
    t.string   "lon"
    t.string   "street"
    t.string   "placename"
    t.string   "zip"
    t.string   "city"
    t.string   "district"
    t.string   "state"
    t.string   "country"
    t.boolean  "displayed"
    t.string   "locatable_type"
    t.integer  "locatable_id"
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
    t.string   "internal_id"
    t.boolean  "migrated_from_neos",               default: false
    t.text     "directions",         limit: 65535
    t.index ["locatable_type", "locatable_id"], name: "index_locations_on_locatable_type_and_locatable_id", using: :btree
  end

  create_table "offer_owners", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer  "actor_id"
    t.integer  "offer_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_offer_owners_on_actor_id", using: :btree
    t.index ["offer_id"], name: "index_offer_owners_on_offer_id", using: :btree
  end

  create_table "offers", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string   "title"
    t.text     "description", limit: 65535
    t.string   "area"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "orga_category_relations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer  "category_id"
    t.integer  "orga_id"
    t.boolean  "primary"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["category_id"], name: "index_orga_category_relations_on_category_id", using: :btree
    t.index ["orga_id"], name: "index_orga_category_relations_on_orga_id", using: :btree
  end

  create_table "orga_types", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "orgas", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer  "orga_type_id"
    t.datetime "created_at",                                          null: false
    t.datetime "updated_at",                                          null: false
    t.string   "title"
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
    t.string   "tags"
    t.string   "inheritance"
    t.string   "area"
    t.integer  "last_editor_id"
    t.integer  "creator_id"
    t.string   "facebook_id"
    t.index ["area"], name: "index_orgas_on_area", using: :btree
    t.index ["category_id"], name: "index_orgas_on_category_id", using: :btree
    t.index ["creator_id"], name: "index_orgas_on_creator_id", using: :btree
    t.index ["last_editor_id"], name: "index_orgas_on_last_editor_id", using: :btree
    t.index ["orga_type_id"], name: "index_orgas_on_orga_type_id", using: :btree
    t.index ["sub_category_id"], name: "index_orgas_on_sub_category_id", using: :btree
  end

  create_table "owner_thing_relations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string   "ownable_type"
    t.integer  "ownable_id"
    t.string   "thingable_type"
    t.integer  "thingable_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.index ["ownable_type", "ownable_id"], name: "index_owner_thing_relations_on_ownable_type_and_ownable_id", using: :btree
    t.index ["thingable_type", "thingable_id"], name: "index_owner_thing_relations_on_thingable_type_and_thingable_id", using: :btree
  end

  create_table "resource_items", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string   "title",              null: false
    t.string   "description"
    t.string   "tags"
    t.integer  "orga_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.index ["orga_id"], name: "index_resource_items_on_orga_id", using: :btree
  end

  create_table "roles", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string   "title"
    t.integer  "user_id"
    t.integer  "orga_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["orga_id"], name: "index_roles_on_orga_id", using: :btree
    t.index ["user_id"], name: "index_roles_on_user_id", using: :btree
  end

  create_table "thing_category_relations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer  "category_id"
    t.string   "catable_type"
    t.integer  "catable_id"
    t.boolean  "primary"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["catable_type", "catable_id"], name: "index_thing_category_relations_on_catable_type_and_catable_id", using: :btree
    t.index ["category_id"], name: "index_thing_category_relations_on_category_id", using: :btree
  end

  create_table "translation_caches", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer  "cacheable_id"
    t.string   "cacheable_type"
    t.string   "language",          limit: 3,     null: false
    t.string   "title"
    t.text     "short_description", limit: 65535
    t.text     "description",       limit: 65535
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.index ["cacheable_id", "cacheable_type", "language"], name: "index_translation_cache", using: :btree
  end

  create_table "users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
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
    t.string   "area"
    t.string   "organization"
    t.index ["area"], name: "index_users_on_area", using: :btree
    t.index ["email"], name: "index_users_on_email", using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true, using: :btree
  end

end
