class AddTagsToOrgasAndEvents < ActiveRecord::Migration[5.0]

  def change
    add_column :orgas, :tags, :string
    add_column :events, :tags, :string
  end

end
