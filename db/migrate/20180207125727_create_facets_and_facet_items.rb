class CreateFacetsAndFacetItems < ActiveRecord::Migration[5.0]
  def up
    unless ApplicationRecord.connection.execute('show tables').to_a.inspect =~ /facets/
      create_table :facets do |t|
        t.string :title

        t.timestamps
      end
    end

    unless ApplicationRecord.connection.execute('show tables').to_a.inspect =~ /facet_items/
      create_table :facet_items do |t|
        t.string :title
        t.string :color

        t.references :facet, index: true
        t.references :parent, index: true

        t.timestamps
      end
    end

    unless ApplicationRecord.connection.execute('show tables').to_a.inspect =~ /owner_facet_items/
      create_table :owner_facet_items do |t|
        t.references :owner, polymorphic: true, index: true
        t.references :facet_item, index: true

        t.timestamps
      end
    end
  end

  def down
    drop_table :owner_facet_items
    drop_table :facet_items
    drop_table :facets
  end
end
