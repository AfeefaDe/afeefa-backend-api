class AddStateChangedAtToThingsAndOrga < ActiveRecord::Migration[5.0]
  def change
    add_column :events, :state_changed_at, :string
    add_column :orgas, :state_changed_at, :string
    # todo: add category columns for other things
  end
end
