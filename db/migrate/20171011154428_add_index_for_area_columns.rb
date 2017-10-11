class AddIndexForAreaColumns < ActiveRecord::Migration[5.0]
  def change
    add_index :translation_cache_meta_data, :area
    add_index :categories, :area
    add_index :users, :area
    add_index :orgas, :area
    add_index :events, :area
  end
end
