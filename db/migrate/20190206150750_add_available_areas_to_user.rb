class AddAvailableAreasToUser < ActiveRecord::Migration[5.0]
  def up
    add_column :users, :available_areas, :string

    User.find_each do |user|
      user.initialize_available_areas_by_area!
    end
  end

  def down 
    remove_column :users, :available_areas
  end
end
