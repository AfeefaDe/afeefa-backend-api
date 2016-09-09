class AddParentIdToOrgas < ActiveRecord::Migration
  def change
    add_column :orgas, :parent_id, :integer
  end
end
