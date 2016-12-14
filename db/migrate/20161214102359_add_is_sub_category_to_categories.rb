class AddIsSubCategoryToCategories < ActiveRecord::Migration[5.0]
  def change
    add_column :categories, :is_sub_category, :boolean
  end
end
