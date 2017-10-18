class RemoveTranslationCacheMetadataTable < ActiveRecord::Migration[5.0]
  def change
    drop_table :translation_cache_meta_data
  end
end
