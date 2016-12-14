class AddCategoryAndSubCategoryToOrgasAndEvents < ActiveRecord::Migration[5.0]
  def change
    remove_column :orgas, :category
    add_reference :orgas, :category, index: true
    add_reference :orgas, :sub_category, index: true
    remove_column :events, :category
    add_reference :events, :category, index: true
    add_reference :events, :sub_category, index: true
  end
end
