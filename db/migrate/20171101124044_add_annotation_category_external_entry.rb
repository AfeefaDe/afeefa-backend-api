class AddAnnotationCategoryExternalEntry < ActiveRecord::Migration[5.0]

  def up
    AnnotationCategory.create!(title: 'Externer Eintrag', generated_by_system: true)
  end

  def down
    AnnotationCategory.where(title: 'Externer Eintrag').delete_all
  end

end
