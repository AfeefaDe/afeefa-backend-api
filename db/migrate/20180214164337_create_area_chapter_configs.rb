class CreateAreaChapterConfigs < ActiveRecord::Migration[5.0]
  def up
    unless ApplicationRecord.connection.execute('show tables').to_a.inspect =~ /chapter_configs/
      create_table :area_chapter_configs do |t|
        t.string :area
        t.integer :chapter_config_id

        t.timestamps null: false
      end
    end
  end

  def down
    drop_table :area_chapter_configs
  end
end
