class AddCategoryForFacebookEvents < ActiveRecord::Migration[5.0]
  def up
    Translatable::AREAS.each do |area|
      parent = Category.create(title: 'external-event', area: area)
      Category.create(title: 'fb-event', parent: parent, area: area)
    end
  end

  def down
    Category.where(title: ['external-event']).destroy_all
    Category.where(title: ['fb-event']).destroy_all
  end
end
