class MoveShortDescriptionToItsRightPlace < ActiveRecord::Migration[5.0]
  def change
    change_column :orgas, :short_description, :text, after: :description
    change_column :events, :short_description, :text, after: :description
  end
end
