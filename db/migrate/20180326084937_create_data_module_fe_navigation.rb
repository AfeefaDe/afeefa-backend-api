class CreateDataModuleFeNavigation < ActiveRecord::Migration[5.0]
  def up
    create_table :fe_navigations do |t|
      t.string :area

      t.timestamps
    end

    create_table :fe_navigation_items do |t|
      t.string :title
      t.string :color
      t.string :icon
      t.string :legacy_title

      t.references :navigation, index: true
      t.references :parent, index: true

      t.timestamps
    end

    create_table :fe_navigation_item_owners do |t|
      t.references :owner, polymorphic: true, index: true
      t.references :navigation_item, index: true

      t.timestamps
    end

    create_table :fe_navigation_item_facet_items do |t|
      t.references :facet_item, index: true
      t.references :navigation_item, index: true

      t.timestamps
    end
  end

  def down
    drop_table :fe_navigations
    drop_table :fe_navigation_items
    drop_table :fe_navigation_item_owners
    drop_table :fe_navigation_item_facet_items
  end
end
