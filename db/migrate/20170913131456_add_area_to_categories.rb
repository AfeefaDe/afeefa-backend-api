class AddAreaToCategories < ActiveRecord::Migration[5.0]

  MAIN_AREA = 'dresden'
  AREAS = %w(bautzen leipzig)

  def up
    add_column :categories, :area, :string, default: MAIN_AREA
    Category.reset_column_information

    AREAS.each do |area|
      Category.where(area: MAIN_AREA).each do |category|
        cloned_category = category.dup
        cloned_category.id = nil
        cloned_category.area = area
        cloned_category.save
      end
    end

    Category.where.not(area: MAIN_AREA).each do |category|
      next unless category.parent
      parent_category = Category.find_by(title: category.parent.title, area: category.area)
      category.parent = parent_category
      category.save
    end
  end

  def down
    Category.where.not(area: MAIN_AREA).delete_all

    remove_column :categories, :area
  end

end
