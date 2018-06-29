class ExtendTranslationCacheTypeColumn < ActiveRecord::Migration[5.0]
  def change
    change_column :translation_caches, :cacheable_type, :string, limit: 255
  end
end
