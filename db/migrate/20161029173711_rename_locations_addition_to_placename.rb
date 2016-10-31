class RenameLocationsAdditionToPlacename < ActiveRecord::Migration
  def change
    rename_column :locations, :addition, :placename
  end
end
