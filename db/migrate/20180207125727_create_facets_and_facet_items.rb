class CreateFacetsAndFacetItems < ActiveRecord::Migration[5.0]
  def up
    create_table :facets do |t|
      t.string :title

      t.timestamps
    end

    create_table :facet_items do |t|
      t.string :title
      t.string :color

      t.references :facet, index: true
      t.references :parent, index: true

      t.timestamps
    end

    create_table :owner_facet_items do |t|
      t.references :owner, polymorphic: true, index: true
      t.references :facet_item, index: true

      t.timestamps
    end
  end

  def down
    drop_table :owner_facet_items
    drop_table :facet_items
    drop_table :facets
  end
end
