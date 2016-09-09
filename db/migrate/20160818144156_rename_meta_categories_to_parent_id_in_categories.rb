class RenameMetaCategoriesToParentIdInCategories < ActiveRecord::Migration
  def change
    rename_column :categories, :meta_category_id, :parent_id
  end
end
