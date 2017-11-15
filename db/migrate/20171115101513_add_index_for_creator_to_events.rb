class AddIndexForCreatorToEvents < ActiveRecord::Migration[5.0]

  def change
    add_index :events, :creator_id
  end

end
