class AnnotatableTypeFromAnnotations < ActiveRecord::Migration[5.0]
  def change
    remove_column :annotations, :annotatable_type
  end
end
