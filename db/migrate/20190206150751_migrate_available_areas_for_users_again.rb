class MigrateAvailableAreasForUsersAgain < ActiveRecord::Migration[5.0]
  def up
    User.find_each do |user|
      user.initialize_available_areas_by_area!
      puts "migrated user: #{user.reload.inspect}"
    end
  end

  def down
    User.find_each do |user|
      user.available_areas = nil
      user.save(validate: false)
      puts "migrated user: #{user.reload.inspect}"
    end
  end
end
