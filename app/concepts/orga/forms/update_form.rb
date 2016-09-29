class Orga < ApplicationRecord
  module Forms
    class UpdateForm < CreateSubOrgaForm

      property :active

      collection :meta, virtual: true do
        property :trigger_operation
      end

      validates :active, inclusion: [true, false]
      validates :meta, presence: true

    end
  end
end
