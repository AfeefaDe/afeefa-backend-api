class AddFlagMigratedFromNeosToOrgasEventsLocationsAndContactInfos < ActiveRecord::Migration[5.0]

  def change
    add_column :orgas, :migrated_from_neos, :boolean, default: false
    add_column :events, :migrated_from_neos, :boolean, default: false
    add_column :locations, :migrated_from_neos, :boolean, default: false
    add_column :contact_infos, :migrated_from_neos, :boolean, default: false
  end

end
