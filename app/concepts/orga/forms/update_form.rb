class Orga < ApplicationRecord
  module Forms
    class UpdateForm < CreateSubOrgaForm

      property :active

      validates :active, inclusion: [true, false]

    end
  end
end
