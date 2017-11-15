class AddLastEditorToOrgasAndEvents < ActiveRecord::Migration[5.0]

  def change
    add_reference :orgas, :last_editor, references: :users, index: true
    add_reference :events, :last_editor, references: :users, index: true
  end

end
