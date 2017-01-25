class SyncMissingAttributesOfOrgaEventAndContactInfo < ActiveRecord::Migration[5.0]
  def change
    add_column :orgas, :media_url, :string
    add_column :orgas, :media_type, :string
    add_column :orgas, :support_wanted, :boolean
    add_column :orgas, :for_children, :boolean
    add_column :orgas, :certified_sfr, :boolean
    add_column :orgas, :legacy_entry_id, :string

    add_column :events, :media_url, :string
    add_column :events, :media_type, :string
    add_column :events, :for_children, :boolean
    add_column :events, :certified_sfr, :boolean
    add_column :events, :legacy_entry_id, :string

    add_column :contact_infos, :spoken_languages, :string
  end
end
