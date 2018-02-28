class CreateAreaChapterConfigs < ActiveRecord::Migration[5.0]
  def change
    create_table :area_chapter_configs do |t|
      t.string :area
      t.integer :chapter_config_id

      t.timestamps null: false
    end
  end
end
