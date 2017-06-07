class RenameParentEntryFields < ActiveRecord::Migration[5.0]
  def change
    rename_column :orgas, :parent_id, :parent_orga_id
    rename_column :events, :parent_id, :parent_event_id
    change_column :events, :orga_id, :integer, after: :parent_event_id
  end
end
