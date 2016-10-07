class Orga < ApplicationRecord
  module Forms
    class UpdateForm < CreateSubOrgaForm

      validates :active, inclusion: [true, false]

    end
  end
end
