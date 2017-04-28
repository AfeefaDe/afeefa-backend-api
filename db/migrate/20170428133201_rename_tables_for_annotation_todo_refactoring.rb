class RenameTablesForAnnotationTodoRefactoring < ActiveRecord::Migration[5.0]
  def change
    rename_table :annotations, :annotation_categories
    rename_table :annotation_able_relations, :annotations

    rename_column :annotations, :annotation_id, :annotation_category_id
  end
end
