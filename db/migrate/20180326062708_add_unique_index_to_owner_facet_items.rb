class AddUniqueIndexToOwnerFacetItems < ActiveRecord::Migration[5.0]
  def change
    add_index :owner_facet_items, [:owner_type, :owner_id, :facet_item_id], unique: true, name: 'facet_item_owner'
  end
end
