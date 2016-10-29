module Able

  extend ActiveSupport::Concern

  included do
    include StateMachine

    has_one :location, as: :locatable
    has_one :annotation, as: :annotateable
    has_one :contact_info, as: :contactable
  end

end
