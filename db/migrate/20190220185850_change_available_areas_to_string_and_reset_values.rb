class ChangeAvailableAreasToStringAndResetValues < ActiveRecord::Migration[5.0]
  def up
    remove_column :users, :available_areas
    add_column :users, :available_areas, :string

    User.update_all(available_areas: nil)
    User.find_each do |user|
      user.initialize_available_areas_by_area!
    end
  end

  def down 
    remove_column :users, :available_areas
  end
end
