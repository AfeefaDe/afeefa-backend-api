class ChangeEventColumns < ActiveRecord::Migration[5.0]
  def change
    add_column :events, :active, :boolean, default: true
    remove_column :events, :activated_at
    remove_column :events, :deactivated_at
  end
end
