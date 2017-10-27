class FixEntryCategoryAreas < ActiveRecord::Migration[5.0]

  Settings.afeefa.fapi_sync_active = false

  AREAS = %w(bautzen leipzig)
  MODELS = [Orga, Event]

  def up
    AREAS.each do |area|
      MODELS.each do |model_class|
        model_class.where(area: area).each do |model|

          category = model.category
          if category && category.area != area
            new_category = Category.where(title: category.title, area: area).first
            if new_category
              model.category_id = new_category.id
              model.save(validate: false)

              puts "set category from #{category.id} #{category.title} to #{new_category.id} #{new_category.title} for entry #{model.id} #{model.class.name} #{model.title} #{model.category_id}"
            else
              puts "category #{category.id} #{category.title} for entry #{model.id} #{model.class.name} #{model.title} not found in area #{area}"
            end
          end

          category = model.sub_category
          if category && category.area != area
            new_category = Category.where(title: category.title, area: area).first
            if new_category
              model.sub_category_id = new_category.id
              model.save(validate: false)

              puts "set category from #{category.id} #{category.title} to #{new_category.id} #{new_category.title} for entry #{model.id} #{model.class.name} #{model.title} #{model.sub_category_id}"
            else
              puts "category #{category.id} #{category.title} for entry #{model.id} #{model.class.name} #{model.title} not found in area #{area}"
            end
          end

        end
      end
    end
  end

  def down
  end

end
