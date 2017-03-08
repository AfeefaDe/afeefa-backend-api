class ChangeColumnTypeForDescriptions < ActiveRecord::Migration[5.0]
  def change
    change_column :orgas, :description, :text
    change_column :events, :description, :text
  end
end
