class AddShortDescriptionToOrgasAndEvents < ActiveRecord::Migration[5.0]

  def change
    add_column :orgas, :short_description, :text
    add_column :events, :short_description, :text
  end

end
