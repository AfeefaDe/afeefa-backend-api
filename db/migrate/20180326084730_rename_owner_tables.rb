class RenameOwnerTables < ActiveRecord::Migration[5.0]
  def change
    rename_table :offer_owners, :offer_owners
    rename_table :facet_item_owners, :facet_item_owners
  end
end
