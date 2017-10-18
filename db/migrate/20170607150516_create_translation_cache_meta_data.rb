class CreateTranslationCacheMetaData < ActiveRecord::Migration[5.0]

  def change
    create_table :translation_cache_meta_data do |t|
      t.string :locale
      t.datetime :locked_at

      t.timestamps
    end
  end

end
