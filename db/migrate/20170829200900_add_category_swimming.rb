class AddCategorySwimming < ActiveRecord::Migration[5.0]

  def up
    if swimming_categories.blank?
      general = Category.find_by(title: 'genenal')
      Category.create(title: 'swimming', parent: general)
    end
  end

  def down
    swimming_categories.delete_all if swimming_categories.any?
  end

  private

  def swimming_categories
    Category.where(title: 'swimming')
  end

end
