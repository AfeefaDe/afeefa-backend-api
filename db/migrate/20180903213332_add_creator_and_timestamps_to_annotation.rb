class AddCreatorAndTimestampsToAnnotation < ActiveRecord::Migration[5.0]
  def change
    add_reference :annotations, :creator, references: :users, index: true
    add_reference :annotations, :last_editor, references: :users, index: true
    add_column :annotations, :created_at, :datetime, null: false
    add_column :annotations, :updated_at, :datetime, null: false

    Annotation.update_all(created_at: Time.now, updated_at: Time.now)
  end
end
