class CreateCachingTable < ActiveRecord::Migration[5.0]
  def change
    create_table :translation_caches do |t|
      t.integer :cacheable_id
      t.string :cacheable_type, limit: 20

      t.string :language, null: false, limit: 3
      t.string :title
      t.string :short_description
      t.string :description

      t.timestamps null: false

    end

    add_index :translation_caches, [:cacheable_id, :cacheable_type, :language], name: :index_translation_cache
  end
end
