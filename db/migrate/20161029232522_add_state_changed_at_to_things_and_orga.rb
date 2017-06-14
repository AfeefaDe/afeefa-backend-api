class AddStateChangedAtToThingsAndOrga < ActiveRecord::Migration[5.0]
  def change
    add_column :events, :state_changed_at, :datetime
    add_column :orgas, :state_changed_at, :datetime
  end
end
