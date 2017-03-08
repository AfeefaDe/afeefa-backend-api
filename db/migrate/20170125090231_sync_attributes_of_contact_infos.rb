class SyncAttributesOfContactInfos < ActiveRecord::Migration[5.0]

  def change
    add_column :contact_infos, :web, :string
    add_column :contact_infos, :facebook, :string
  end

end
