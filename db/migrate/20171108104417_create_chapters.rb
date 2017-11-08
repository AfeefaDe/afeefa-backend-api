class CreateChapters < ActiveRecord::Migration[5.0]

  def change
    create_table :chapters do |t|
      t.string :title, null: false
      t.text :content
      t.integer :order
      t.string :area

      t.references :category

      t.timestamps null: false
    end
  end

end
