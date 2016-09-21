module Forms
  module TriggerOperationForm
    extend ActiveSupport::Concern

    included do
      UPDATE_DATA = 'update_data'
      UPDATE_STRUCTURE = 'update_structure'
      UPDATE_ALL = 'update_all'
      OPERATIONS = [UPDATE_ALL, UPDATE_DATA, UPDATE_STRUCTURE]

      feature Reform::Form::Dry

      collection :meta, virtual: true do
        property :trigger_operation, virtual: true
      end

      validation :default do
        configure do
          def operation?(value)
            value.in?(OPERATIONS)
          end
        end
        #required(:trigger_operation).filled
        required(:trigger_operation).included_in?(OPERATIONS)

      end
    end
  end
end