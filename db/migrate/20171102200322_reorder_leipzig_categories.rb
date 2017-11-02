class ReorderLeipzigCategories < ActiveRecord::Migration[5.0]

  Settings.afeefa.fapi_sync_active = false

    MODELS = [Orga, Event]

    def up
      # set leipzig entry categories to null
      MODELS.each do |model_class|
        model_class.where(area: 'leipzig').each do |model|
          model.category_id = nil
          model.sub_category_id = nil
          model.save(validate: false)
        end
      end
      # remove all leipzig sub categories
      Category.by_area('leipzig').sub_categories.destroy_all
    end

    def down
    end

  end
