class RenameAnnotationCategoryExternalEntry < ActiveRecord::Migration[5.0]

  def up
    AnnotationCategory.find_by(title: 'Externer Eintrag')&.update!(title: 'Externe Eintragung')
  end

  def down
    AnnotationCategory.find_by(title: 'Externe Eintragung')&.update!(title: 'Externer Eintrag')
  end

end
