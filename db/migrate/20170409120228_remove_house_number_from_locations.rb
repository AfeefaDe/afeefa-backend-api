class RemoveHouseNumberFromLocations < ActiveRecord::Migration[5.0]
  def change
    remove_column :locations, :number
  end
end
