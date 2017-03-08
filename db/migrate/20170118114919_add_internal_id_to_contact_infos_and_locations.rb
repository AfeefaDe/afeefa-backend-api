class AddInternalIdToContactInfosAndLocations < ActiveRecord::Migration[5.0]

  def change
    add_column :contact_infos, :internal_id, :string
    add_column :locations, :internal_id, :string
  end

end
