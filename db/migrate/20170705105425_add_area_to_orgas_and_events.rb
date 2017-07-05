class AddAreaToOrgasAndEvents < ActiveRecord::Migration[5.0]
  def change
    add_column :orgas, :area, :string
    add_column :events, :area, :string
  end
end
