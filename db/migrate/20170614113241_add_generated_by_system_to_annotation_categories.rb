class AddGeneratedBySystemToAnnotationCategories < ActiveRecord::Migration[5.0]

  def change
    add_column :annotation_categories, :generated_by_system, :boolean, null: false, default: false, after: :title
  end

end
