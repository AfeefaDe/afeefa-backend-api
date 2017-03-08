class AddDetailToAnnotationAbleRelation < ActiveRecord::Migration[5.0]

  def change
    add_column :annotation_able_relations, :detail, :text
  end

end
