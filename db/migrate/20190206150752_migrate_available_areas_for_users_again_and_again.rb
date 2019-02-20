class MigrateAvailableAreasForUsersAgainAndAgain < ActiveRecord::Migration[5.0]
  def up
    User.update_all(available_areas: nil)
    User.find_each do |user|
      user.initialize_available_areas_by_area!
      puts "migrated user: #{user.reload.inspect}"
    end
  end

  def down
    User.update_all(available_areas: nil)
  end
end
