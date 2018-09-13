class AddOrderToFeNavigationItems < ActiveRecord::Migration[5.0]
  def change
    add_column :fe_navigation_items, :order, :integer, after: :parent_id, null: false, default: 0
  end
end
