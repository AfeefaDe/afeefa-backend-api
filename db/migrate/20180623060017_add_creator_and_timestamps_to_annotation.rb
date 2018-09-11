class AddCreatorAndTimestampsToAnnotation < ActiveRecord::Migration[5.0]
  def change
    add_reference :annotations, :creator, references: :users, index: true
    add_reference :annotations, :last_editor, references: :users, index: true
    add_column :annotations, :created_at, :datetime, null: false
    add_column :annotations, :updated_at, :datetime, null: false

    Annotation.all.each do |annotation|
      if annotation.entry.present?
        annotation.update!(
          created_at: annotation.entry.updated_at,
          updated_at: annotation.entry.updated_at
        )
      else
        annotation.destroy
      end
    end
  end
end
