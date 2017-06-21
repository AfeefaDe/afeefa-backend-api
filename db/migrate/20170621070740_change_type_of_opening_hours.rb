class ChangeTypeOfOpeningHours < ActiveRecord::Migration[5.0]
  def change
    change_column :contact_infos, :opening_hours, :text
  end
end
