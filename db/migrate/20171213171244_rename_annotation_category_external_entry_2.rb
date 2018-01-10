class RenameAnnotationCategoryExternalEntry2 < ActiveRecord::Migration[5.0]

  def up
    AnnotationCategory.find_by(title: 'Externe Eintragung').update!(title: 'EXTERNE EINTRAGUNG')
  end

  def down
    AnnotationCategory.find_by(title: 'EXTERNE EINTRAGUNG').update!(title: 'Externe Eintragung')
  end

end
