class CreateAnnotations < ActiveRecord::Migration[5.0]
  def change
    create_table :annotations do |t|
      t.string :title
      t.references :annotateable, polymorphic: true, index:true

      t.timestamps
    end
  end
end
