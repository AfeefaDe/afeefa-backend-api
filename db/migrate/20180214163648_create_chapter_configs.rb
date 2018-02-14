class CreateChapterConfigs < ActiveRecord::Migration[5.0]
  def change
    create_table :chapter_configs do |t|
      t.integer :chapter_id
      t.integer :creator_id
      t.integer :last_modifier_id
      t.boolean :active

      t.timestamps null: false
    end
  end
end
