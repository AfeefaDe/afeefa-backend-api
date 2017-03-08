class AddTimeStartAndTimeEndToEvents < ActiveRecord::Migration[5.0]

  def change
    add_column :events, :time_start, :boolean, default: false
    add_column :events, :time_end, :boolean, default: false
  end

end
