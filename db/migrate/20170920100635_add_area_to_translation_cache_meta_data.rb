class AddAreaToTranslationCacheMetaData < ActiveRecord::Migration[5.0]

  def change
    add_column :translation_cache_meta_data, :area, :string, default: 'dresden'
  end

end
