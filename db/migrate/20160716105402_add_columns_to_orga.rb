class AddColumnsToOrga < ActiveRecord::Migration
  def change
    add_column :orgas, :active, :boolean, default: true
  end
end
