class CreateThingCategoryRelation < ActiveRecord::Migration
  def change
    create_table :thing_category_relations do |t|

      t.references :category, index: true
      t.references :catable, polymorphic: true, index: true

      t.boolean :primary

      t.timestamps null: false
    end
  end
end
