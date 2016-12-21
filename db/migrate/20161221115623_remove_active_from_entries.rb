class RemoveActiveFromEntries < ActiveRecord::Migration[5.0]
  def change
    remove_column :orgas, :active
    remove_column :events, :active
  end
end
