class RemoveOldLocations < ActiveRecord::Migration[5.0]
  def change
    drop_table :locations
  end
end
