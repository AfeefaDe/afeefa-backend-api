class CreateResources < ActiveRecord::Migration[5.0]

  def change
    create_table :resources do |t|
      t.string :title, null: false
      t.string :description
      t.string :tags

      t.references :orga

      t.timestamps null: false
    end
  end

end
