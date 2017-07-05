class AddNewAnnotationCategories < ActiveRecord::Migration[5.0]
  def up
    annotation_categories = []
    AnnotationCategory.create!(title: 'ENTWURF', generated_by_system: false)
    annotation_categories << AnnotationCategory.last
    AnnotationCategory.create!(title: 'DRINGEND', generated_by_system: false)
    annotation_categories << AnnotationCategory.last

    annotation_categories.each do |category|
      Annotation.where('detail like ?', "#{category.title}:% ").each do |annotation|
        annotation.update(
          annotation_category_id: category.id,
          detail: "#{annotation.detail.gsub("#{category.title}: ", '')}")
      end
    end
  end

  def down
    annotation_categories = AnnotationCategory.where(title: ['ENTWURF' 'DRINGEND'])
    default_category = AnnotationCategory.find_by(title: 'Sonstiges')

    annotation_categories.each do |category|
      Annotation.where(annotation_category_id: category.id).each do |annotation|
        annotation.update!(
          annotation_category_id: default_category.id,
          detail: "#{category.title}: #{annotation.detail}")
      end
    end
  end
end
