class CreateAnnotationAbleRelation < ActiveRecord::Migration[5.0]
  def change
    create_table :annotation_able_relations do |t|

      t.references :annotation, index: true
      t.references :entry, polymorphic: true, index: true

    end
  end
end
