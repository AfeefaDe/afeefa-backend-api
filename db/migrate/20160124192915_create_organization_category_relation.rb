class CreateOrganizationCategoryRelation < ActiveRecord::Migration
  def change
    create_table :organization_category_relations do |t|

      t.references :category, index: true
      t.references :organization, index: true

      t.boolean :primary

      t.timestamps null: false
    end
  end
end
