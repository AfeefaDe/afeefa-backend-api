class CreateChapterConfigs < ActiveRecord::Migration[5.0]
  def up
    unless ApplicationRecord.connection.execute('show tables').to_a.inspect =~ /chapter_configs/
      create_table :chapter_configs do |t|
        t.integer :chapter_id
        t.integer :creator_id
        t.integer :last_modifier_id
        t.boolean :active

        t.timestamps null: false
      end
    end
  end

  def down
    drop_table :chapter_configs
  end
end
