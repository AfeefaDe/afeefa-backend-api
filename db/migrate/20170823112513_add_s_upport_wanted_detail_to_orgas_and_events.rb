class AddSUpportWantedDetailToOrgasAndEvents < ActiveRecord::Migration[5.0]

  def change
    add_column :orgas, :support_wanted_detail, :string, limit: 1000, after: :support_wanted
    add_column :events, :support_wanted_detail, :string, limit: 1000, after: :support_wanted
  end

end
