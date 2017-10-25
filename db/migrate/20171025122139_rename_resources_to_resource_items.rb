class RenameResourcesToResourceItems < ActiveRecord::Migration[5.0]

  def change
    rename_table :resources, :resource_items
  end

end
