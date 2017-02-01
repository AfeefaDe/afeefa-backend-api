class RemoveIsSubCategoryFromCategories < ActiveRecord::Migration[5.0]

  def change
    remove_column :categories, :is_sub_category
  end

end
