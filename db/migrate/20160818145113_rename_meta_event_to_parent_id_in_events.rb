class RenameMetaEventToParentIdInEvents < ActiveRecord::Migration
  def change
    rename_column :events, :meta_event_id, :parent_id
  end
end
