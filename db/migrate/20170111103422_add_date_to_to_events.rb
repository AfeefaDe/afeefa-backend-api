class AddDateToToEvents < ActiveRecord::Migration[5.0]
  def change
    rename_column :events, :date, :date_start
    add_column :events, :date_end, :datetime
  end
end
