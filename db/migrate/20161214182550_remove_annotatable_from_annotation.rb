class RemoveAnnotatableFromAnnotation < ActiveRecord::Migration[5.0]

  def change
    remove_reference(:annotations, :annotatable, index: true)
  end

end
