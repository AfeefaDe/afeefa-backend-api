class AddAnnotationCategoryForExternalFeedback < ActiveRecord::Migration[5.0]
  def up
    AnnotationCategory.create!(title: 'EXTERNE ANMERKUNG', generated_by_system: true)
  end

  def down
    AnnotationCategory.where(title: 'EXTERNE ANMERKUNG').delete_all
  end
end
