class AddStateToThingsAndOrga < ActiveRecord::Migration[5.0]
  def change
    add_column :events, :state, :string
    add_column :orgas, :state, :string
    # todo: add state columns for other things
  end
end
